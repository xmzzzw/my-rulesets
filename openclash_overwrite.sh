#!/bin/sh
# ============================================================
# OpenClash 覆写脚本 — my-rulesets 完整规格
# 将机场订阅配置改造为「my-rulesets」统一规格
# 放置位置：/etc/openclash/custom/openclash_custom_overwrite.sh
#
# 规格（与 overwrite_script.js / 已验证的 FlClash 版一致）：
#   - 保留订阅节点（proxies 原样保留）
#   - 20 应用策略组（AI/Netflix/HBO/...）+ Proxies + 🎯Direct + ✈️Final
#     + 10 国家分组 + 各 -自动 + 🌍 其他地区 = 44 策略组
#   - 32 个 rule-providers（引用 GitHub clash/ 规则集）
#   - 规则：32 条 RULE-SET + GEOIP,CN + MATCH
#
# 实现说明：
#   - rule-providers 是 Hash → 用 ruby_merge_hash 合并（正确用法）
#   - proxy-groups  是 Array → 用 ruby_edit 整体赋值（ruby_merge_hash
#     merge! 会报 undefined method merge! for Array）
#   - 换机场不用改：国家分组用 include-all + filter 自动归类
# ============================================================
. /usr/share/openclash/ruby.sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

LOG_TIP "Start Running MyRules Custom Overwrite Scripts..."
LOGTIME=$(echo $(date "+%Y-%m-%d %H:%M:%S"))
LOG_FILE="/tmp/openclash.log"
CONFIG_FILE="$1"

RULE_BASE="https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/clash"
RULE_PATH="./rule_provider"

# ============ 1. 注入 32 个 rule-providers（引用 GitHub 规则集）============
# 命名与 overwrite_script.js 的 provider_N 一致，保证规则引用有效
ruby_merge_hash "$CONFIG_FILE" "['rule-providers']" "
'provider_0'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/nexitallyy_Extra_CN_3.list','path'=>'${RULE_PATH}/provider_0.list','interval'=>86400},
'provider_1'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_GlobalScholar.list','path'=>'${RULE_PATH}/provider_1.list','interval'=>86400},
'provider_2'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_myTVSUPER.list','path'=>'${RULE_PATH}/provider_2.list','interval'=>86400},
'provider_3'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/nexitallyy_Extra_Crypto.list','path'=>'${RULE_PATH}/provider_3.list','interval'=>86400},
'provider_4'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/nexitallyy_Extra_AI.list','path'=>'${RULE_PATH}/provider_4.list','interval'=>86400},
'provider_5'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_Google.list','path'=>'${RULE_PATH}/provider_5.list','interval'=>86400},
'provider_6'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_YouTube.list','path'=>'${RULE_PATH}/provider_6.list','interval'=>86400},
'provider_7'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_GameDownload.list','path'=>'${RULE_PATH}/provider_7.list','interval'=>86400},
'provider_8'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_LocalAreaNetwork.list','path'=>'${RULE_PATH}/provider_8.list','interval'=>86400},
'provider_9'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_ChinaCompanyIp.list','path'=>'${RULE_PATH}/provider_9.list','interval'=>86400},
'provider_10'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/HotKids_Netflix.list','path'=>'${RULE_PATH}/provider_10.list','interval'=>86400},
'provider_11'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_Telegram.list','path'=>'${RULE_PATH}/provider_11.list','interval'=>86400},
'provider_12'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_Steam.list','path'=>'${RULE_PATH}/provider_12.list','interval'=>86400},
'provider_13'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_Epic.list','path'=>'${RULE_PATH}/provider_13.list','interval'=>86400},
'provider_14'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_Xbox.list','path'=>'${RULE_PATH}/provider_14.list','interval'=>86400},
'provider_15'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_PlayStation.list','path'=>'${RULE_PATH}/provider_15.list','interval'=>86400},
'provider_16'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/HotKids_HBO_Max.list','path'=>'${RULE_PATH}/provider_16.list','interval'=>86400},
'provider_17'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_HBOUSA.list','path'=>'${RULE_PATH}/provider_17.list','interval'=>86400},
'provider_18'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_HBOHK.list','path'=>'${RULE_PATH}/provider_18.list','interval'=>86400},
'provider_19'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/naiixi_DisneyPlus.list','path'=>'${RULE_PATH}/provider_19.list','interval'=>86400},
'provider_20'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_Bahamut.list','path'=>'${RULE_PATH}/provider_20.list','interval'=>86400},
'provider_21'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/HotKids_Bilibili.list','path'=>'${RULE_PATH}/provider_21.list','interval'=>86400},
'provider_22'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_Microsoft.list','path'=>'${RULE_PATH}/provider_22.list','interval'=>86400},
'provider_23'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_Apple.list','path'=>'${RULE_PATH}/provider_23.list','interval'=>86400},
'provider_24'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_TikTok.list','path'=>'${RULE_PATH}/provider_24.list','interval'=>86400},
'provider_25'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/ACL4SSR_ProxyLite.list','path'=>'${RULE_PATH}/provider_25.list','interval'=>86400},
'provider_26'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_Facebook.list','path'=>'${RULE_PATH}/provider_26.list','interval'=>86400},
'provider_27'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/nexitallyy_Extra_Proxies.list','path'=>'${RULE_PATH}/provider_27.list','interval'=>86400},
'provider_28'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_Twitter.list','path'=>'${RULE_PATH}/provider_28.list','interval'=>86400},
'provider_29'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/naiixi_Extra_CN.list','path'=>'${RULE_PATH}/provider_29.list','interval'=>86400},
'provider_30'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/naiixi_Extra_CN_2.list','path'=>'${RULE_PATH}/provider_30.list','interval'=>86400},
'provider_31'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'${RULE_BASE}/blackmatrix7_WeChat.list','path'=>'${RULE_PATH}/provider_31.list','interval'=>86400}
"

# ============ 2. 注入策略组（整体替换 proxy-groups）============
# 用 ruby_edit 一次性赋值完整数组（44 组）：
#   - 20 应用组 + 🎯Direct + ✈️Final + Proxies
#   - 10 国家分组 + 各 -自动 url-test + 🌍 其他地区
# 国家分组用 include-all + filter 自动归类节点（换机场不用改）
# 节点名匹配：emoji + 国家代码 + 中文名（如「🇭🇰 HK | 香港 01」）
# 注意：不要改成 ruby_merge_hash —— proxy-groups 是 Array，merge! 会报错
ruby_edit "$CONFIG_FILE" "['proxy-groups']" '[
{"name"=>"Proxies","type"=>"select","proxies"=>["🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"AI","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Netflix","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"HBO","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"DisneyPlus","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"YouTube","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Bahamut","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Bilibili","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"MyTVSuper","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Telegram","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Crypto","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Steam","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Epic","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Xbox","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"PlayStation","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Microsoft","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Scholar","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Apple","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Google","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"Tiktok","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"🎯Direct","type"=>"select","proxies"=>["DIRECT","Proxies"]},
{"name"=>"✈️Final","type"=>"select","proxies"=>["Proxies","🎯Direct","🇭🇰 香港","🇸🇬 新加坡","🇯🇵 日本","🇺🇸 美国","🇨🇳 台湾","🇰🇷 韩国","🇬🇧 英国","🇩🇪 德国","🇦🇺 澳大利亚","🇨🇦 加拿大","🌍 其他地区"]},
{"name"=>"🇭🇰 香港","type"=>"select","include-all"=>true,"filter"=>"(?i)(香港|HK|Hong\\s?Kong)","proxies"=>["🇭🇰 香港-自动"]},
{"name"=>"🇭🇰 香港-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)(香港|HK|Hong\\s?Kong)","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
{"name"=>"🇸🇬 新加坡","type"=>"select","include-all"=>true,"filter"=>"(?i)(新加坡|SG|Singapore)","proxies"=>["🇸🇬 新加坡-自动"]},
{"name"=>"🇸🇬 新加坡-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)(新加坡|SG|Singapore)","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
{"name"=>"🇯🇵 日本","type"=>"select","include-all"=>true,"filter"=>"(?i)(日本|JP|Japan)","proxies"=>["🇯🇵 日本-自动"]},
{"name"=>"🇯🇵 日本-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)(日本|JP|Japan)","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
{"name"=>"🇺🇸 美国","type"=>"select","include-all"=>true,"filter"=>"(?i)(美国|US|America)","proxies"=>["🇺🇸 美国-自动"]},
{"name"=>"🇺🇸 美国-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)(美国|US|America)","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
{"name"=>"🇨🇳 台湾","type"=>"select","include-all"=>true,"filter"=>"(?i)(台湾|TW|Taiwan)","proxies"=>["🇨🇳 台湾-自动"]},
{"name"=>"🇨🇳 台湾-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)(台湾|TW|Taiwan)","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
{"name"=>"🇰🇷 韩国","type"=>"select","include-all"=>true,"filter"=>"(?i)(韩国|KR|Korea)","proxies"=>["🇰🇷 韩国-自动"]},
{"name"=>"🇰🇷 韩国-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)(韩国|KR|Korea)","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
{"name"=>"🇬🇧 英国","type"=>"select","include-all"=>true,"filter"=>"(?i)(英国|GB|UK|United\\s?Kingdom)","proxies"=>["🇬🇧 英国-自动"]},
{"name"=>"🇬🇧 英国-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)(英国|GB|UK|United\\s?Kingdom)","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
{"name"=>"🇩🇪 德国","type"=>"select","include-all"=>true,"filter"=>"(?i)(德国|DE|Germany)","proxies"=>["🇩🇪 德国-自动"]},
{"name"=>"🇩🇪 德国-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)(德国|DE|Germany)","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
{"name"=>"🇦🇺 澳大利亚","type"=>"select","include-all"=>true,"filter"=>"(?i)(澳大利亚|AU|Australia)","proxies"=>["🇦🇺 澳大利亚-自动"]},
{"name"=>"🇦🇺 澳大利亚-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)(澳大利亚|AU|Australia)","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
{"name"=>"🇨🇦 加拿大","type"=>"select","include-all"=>true,"filter"=>"(?i)(加拿大|CA|Canada)","proxies"=>["🇨🇦 加拿大-自动"]},
{"name"=>"🇨🇦 加拿大-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)(加拿大|CA|Canada)","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
{"name"=>"🌍 其他地区","type"=>"select","include-all"=>true,"proxies"=>["🌍 其他地区-自动"]},
{"name"=>"🌍 其他地区-自动","type"=>"url-test","include-all"=>true,"url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50}
]'

# ============ 3. 注入自定义规则（与 JS 覆写脚本一致）============
cat > /etc/openclash/custom/openclash_custom_rules.list << 'RULEOF'
# 自定义规则（my-rulesets，32 rule-providers + GEOIP + MATCH）
RULE-SET,provider_0,🎯Direct
RULE-SET,provider_1,Scholar
RULE-SET,provider_2,MyTVSuper
RULE-SET,provider_3,Crypto
RULE-SET,provider_4,AI
RULE-SET,provider_5,Google
RULE-SET,provider_6,YouTube
RULE-SET,provider_7,🎯Direct
RULE-SET,provider_8,🎯Direct
RULE-SET,provider_9,🎯Direct
RULE-SET,provider_10,Netflix
RULE-SET,provider_11,Telegram
RULE-SET,provider_12,Steam
RULE-SET,provider_13,Epic
RULE-SET,provider_14,Xbox
RULE-SET,provider_15,PlayStation
RULE-SET,provider_16,HBO
RULE-SET,provider_17,HBO
RULE-SET,provider_18,HBO
RULE-SET,provider_19,DisneyPlus
RULE-SET,provider_20,Bahamut
RULE-SET,provider_21,Bilibili
RULE-SET,provider_22,Microsoft
RULE-SET,provider_23,Apple
RULE-SET,provider_24,Tiktok
RULE-SET,provider_25,Proxies
RULE-SET,provider_26,Proxies
RULE-SET,provider_27,Proxies
RULE-SET,provider_28,Proxies
RULE-SET,provider_29,🎯Direct
RULE-SET,provider_30,🎯Direct
RULE-SET,provider_31,🎯Direct
GEOIP,CN,🎯Direct,no-resolve
MATCH,✈️Final
RULEOF

# ============ 4. 日志 ============
LOG_TIP "MyRules Custom Overwrite Complete."
exit 0
