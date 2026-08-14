#!/bin/sh
# OpenClash 覆写脚本
# 将机场订阅配置改造为「my-rulesets」规格
# 放置位置：/etc/openclash/custom/openclash_custom_overwrite.sh
# 功能：注入 rule-providers + include-all 国家分组 + 自定义规则
. /usr/share/openclash/ruby.sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

LOG_TIP "Start Running MyRules Custom Overwrite Scripts..."
LOGTIME=$(echo $(date "+%Y-%m-%d %H:%M:%S"))
LOG_FILE="/tmp/openclash.log"
CONFIG_FILE="$1"

RULE_BASE="https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/clash"

# ============ 1. 注入 rule-providers（引用 GitHub 规则集）============
ruby_merge_hash "$CONFIG_FILE" "['rule-providers']" "
'opencode'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/nexitallyy_Extra_AI.list','path'=>'./rule_provider/opencode.list','interval'=>86400},
'cn3'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/nexitallyy_Extra_CN_3.list','path'=>'./rule_provider/cn3.list','interval'=>86400},
'google'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_Google.list','path'=>'./rule_provider/google.list','interval'=>86400},
'youtube'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_YouTube.list','path'=>'./rule_provider/youtube.list','interval'=>86400},
'netflix'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/HotKids_Netflix.list','path'=>'./rule_provider/netflix.list','interval'=>86400},
'telegram'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_Telegram.list','path'=>'./rule_provider/telegram.list','interval'=>86400},
'crypto'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/nexitallyy_Extra_Crypto.list','path'=>'./rule_provider/crypto.list','interval'=>86400},
'bilibili'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/HotKids_Bilibili.list','path'=>'./rule_provider/bilibili.list','interval'=>86400},
'disney'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/naiixi_DisneyPlus.list','path'=>'./rule_provider/disney.list','interval'=>86400},
'steam'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_Steam.list','path'=>'./rule_provider/steam.list','interval'=>86400},
'twitter'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_Twitter.list','path'=>'./rule_provider/twitter.list','interval'=>86400},
'apple'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_Apple.list','path'=>'./rule_provider/apple.list','interval'=>86400},
'microsoft'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_Microsoft.list','path'=>'./rule_provider/microsoft.list','interval'=>86400}
"

# ============ 2. 注入 include-all 国家分组 + 应用策略组 ============
# 用 include-all + filter 自动归类节点（mihomo 特性，换机场不用改）
ruby_merge_hash "$CONFIG_FILE" "['proxy-groups']" "
'Proxies'=>{'type'=>'select','proxies'=>['🇭🇰 香港','🇺🇸 美国','🇯🇵 日本','🇸🇬 新加坡','🇨🇳 台湾','🌍 其他地区']},
'🇭🇰 香港'=>{'type'=>'select','include-all'=>true,'filter'=>'(?i)(香港|HK|HongKong)','proxies'=>['🇭🇰 香港-自动']},
'🇭🇰 香港-自动'=>{'type'=>'url-test','include-all'=>true,'filter'=>'(?i)(香港|HK|HongKong)','url'=>'http://www.gstatic.com/generate_204','interval'=>300,'tolerance'=>50},
'🇺🇸 美国'=>{'type'=>'select','include-all'=>true,'filter'=>'(?i)(美国|🇺🇸|US|America)','proxies'=>['🇺🇸 美国-自动']},
'🇺🇸 美国-自动'=>{'type'=>'url-test','include-all'=>true,'filter'=>'(?i)(美国|🇺🇸|US|America)','url'=>'http://www.gstatic.com/generate_204','interval'=>300,'tolerance'=>50},
'🇯🇵 日本'=>{'type'=>'select','include-all'=>true,'filter'=>'(?i)(日本|🇯🇵|JP|Japan)','proxies'=>['🇯🇵 日本-自动']},
'🇯🇵 日本-自动'=>{'type'=>'url-test','include-all'=>true,'filter'=>'(?i)(日本|🇯🇵|JP|Japan)','url'=>'http://www.gstatic.com/generate_204','interval'=>300,'tolerance'=>50},
'🇸🇬 新加坡'=>{'type'=>'select','include-all'=>true,'filter'=>'(?i)(新加坡|🇸🇬|SG|Singapore)','proxies'=>['🇸🇬 新加坡-自动']},
'🇸🇬 新加坡-自动'=>{'type'=>'url-test','include-all'=>true,'filter'=>'(?i)(新加坡|🇸🇬|SG|Singapore)','url'=>'http://www.gstatic.com/generate_204','interval'=>300,'tolerance'=>50},
'🇨🇳 台湾'=>{'type'=>'select','include-all'=>true,'filter'=>'(?i)(台湾|🇹🇼|TW|Taiwan)','proxies'=>['🇨🇳 台湾-自动']},
'🇨🇳 台湾-自动'=>{'type'=>'url-test','include-all'=>true,'filter'=>'(?i)(台湾|🇹🇼|TW|Taiwan)','url'=>'http://www.gstatic.com/generate_204','interval'=>300,'tolerance'=>50},
'🌍 其他地区'=>{'type'=>'select','include-all'=>true,'proxies'=>['🌍 其他地区-自动']},
'🌍 其他地区-自动'=>{'type'=>'url-test','include-all'=>true,'url'=>'http://www.gstatic.com/generate_204','interval'=>300,'tolerance'=>50},
'AI'=>{'type'=>'select','proxies'=>['Proxies','🇭🇰 香港','🇺🇸 美国','🇯🇵 日本','🇸🇬 新加坡','🇨🇳 台湾','🌍 其他地区']},
'🎯Direct'=>{'type'=>'select','proxies'=>['DIRECT']},
'✈️Final'=>{'type'=>'select','proxies'=>['Proxies','🇭🇰 香港','🇺🇸 美国','🇯🇵 日本','🇸🇬 新加坡','🇨🇳 台湾','🌍 其他地区']}
"

# ============ 3. 注入自定义规则（优先规则）============
cat > /etc/openclash/custom/openclash_custom_rules.list << 'RULEOF'
# 自定义规则（my-rulesets）
RULE-SET,opencode,AI
RULE-SET,cn3,🎯Direct
RULE-SET,google,Google
RULE-SET,youtube,YouTube
RULE-SET,netflix,Netflix
RULE-SET,telegram,Telegram
RULE-SET,crypto,Crypto
RULE-SET,bilibili,Bilibili
RULE-SET,disney,DisneyPlus
RULE-SET,steam,Steam
RULE-SET,twitter,Proxies
RULE-SET,apple,🎯Direct
RULE-SET,microsoft,Microsoft
GEOIP,CN,🎯Direct
RULEOF

# ============ 4. 日志 ============
LOG_TIP "MyRules Custom Overwrite Complete."
exit 0
