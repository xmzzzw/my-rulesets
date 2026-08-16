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
#   - 规则：5 条内部直连 + 32 条 RULE-SET + GEOIP,CN + MATCH
#
# 关键实现约束（OpenClash 片段机制）：
#   OpenClash 的 init.d 用 grep 按【行】提取覆写脚本生成的 Ruby 片段，
#   多行参数会被截断只剩第一行 → Ruby 语法错误 → 覆写静默失效。
#   因此 ruby_* 函数的参数必须严格【单行】。
#   本脚本用 heredoc 构造内容后压缩换行，保证传给函数的参数无换行。
#
# 换机场不用改：国家分组用 include-all + filter 自动归类
# ============================================================
. /usr/share/openclash/ruby.sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

LOG_TIP "Start Running MyRules Custom Overwrite Scripts..."
LOGTIME=$(echo $(date "+%Y-%m-%d %H:%M:%S"))
LOG_FILE="/tmp/openclash.log"
CONFIG_FILE="$1"

# 用 jsdelivr CDN 而非 raw.githubusercontent.com：
# raw 在软路由上直连常被墙/EOF，且 OpenClash 的 github_address_mod
# 改写发生在覆写脚本之前，会被我们覆盖。直接写 jsdelivr 最稳妥。
RULE_BASE="https://testingcf.jsdelivr.net/gh/xmzzzw/my-rulesets@main/clash"
RULE_PATH="./rule_provider"

# ============ 辅助：压缩为单行（去掉换行与多余空格）============
# heredoc 内容 → 单行字符串。传给 ruby_* 函数必须是单行！
oneliner() {
   tr -d '\n' | sed 's/[[:space:]][[:space:]]*/ /g'
}

# ============ 1. 注入 32 个 rule-providers（引用 GitHub 规则集）============
# 命名与 overwrite_script.js 的 provider_N 一致，保证规则引用有效
RPS=$(cat << 'EOF' | oneliner
'provider_0'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/nexitallyy_Extra_CN_3.list','path'=>'REPL_RP/provider_0.list','interval'=>86400},
'provider_1'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_GlobalScholar.list','path'=>'REPL_RP/provider_1.list','interval'=>86400},
'provider_2'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_myTVSUPER.list','path'=>'REPL_RP/provider_2.list','interval'=>86400},
'provider_3'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/nexitallyy_Extra_Crypto.list','path'=>'REPL_RP/provider_3.list','interval'=>86400},
'provider_4'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/nexitallyy_Extra_AI.list','path'=>'REPL_RP/provider_4.list','interval'=>86400},
'provider_5'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_Google.list','path'=>'REPL_RP/provider_5.list','interval'=>86400},
'provider_6'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/ACL4SSR_YouTube.list','path'=>'REPL_RP/provider_6.list','interval'=>86400},
'provider_7'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_GameDownload.list','path'=>'REPL_RP/provider_7.list','interval'=>86400},
'provider_8'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/ACL4SSR_LocalAreaNetwork.list','path'=>'REPL_RP/provider_8.list','interval'=>86400},
'provider_9'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/ACL4SSR_ChinaCompanyIp.list','path'=>'REPL_RP/provider_9.list','interval'=>86400},
'provider_10'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/HotKids_Netflix.list','path'=>'REPL_RP/provider_10.list','interval'=>86400},
'provider_11'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/ACL4SSR_Telegram.list','path'=>'REPL_RP/provider_11.list','interval'=>86400},
'provider_12'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_Steam.list','path'=>'REPL_RP/provider_12.list','interval'=>86400},
'provider_13'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_Epic.list','path'=>'REPL_RP/provider_13.list','interval'=>86400},
'provider_14'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_Xbox.list','path'=>'REPL_RP/provider_14.list','interval'=>86400},
'provider_15'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_PlayStation.list','path'=>'REPL_RP/provider_15.list','interval'=>86400},
'provider_16'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/HotKids_HBO_Max.list','path'=>'REPL_RP/provider_16.list','interval'=>86400},
'provider_17'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_HBOUSA.list','path'=>'REPL_RP/provider_17.list','interval'=>86400},
'provider_18'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_HBOHK.list','path'=>'REPL_RP/provider_18.list','interval'=>86400},
'provider_19'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/naiixi_DisneyPlus.list','path'=>'REPL_RP/provider_19.list','interval'=>86400},
'provider_20'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/ACL4SSR_Bahamut.list','path'=>'REPL_RP/provider_20.list','interval'=>86400},
'provider_21'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/HotKids_Bilibili.list','path'=>'REPL_RP/provider_21.list','interval'=>86400},
'provider_22'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/ACL4SSR_Microsoft.list','path'=>'REPL_RP/provider_22.list','interval'=>86400},
'provider_23'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/ACL4SSR_Apple.list','path'=>'REPL_RP/provider_23.list','interval'=>86400},
'provider_24'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_TikTok.list','path'=>'REPL_RP/provider_24.list','interval'=>86400},
'provider_25'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/ACL4SSR_ProxyLite.list','path'=>'REPL_RP/provider_25.list','interval'=>86400},
'provider_26'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_Facebook.list','path'=>'REPL_RP/provider_26.list','interval'=>86400},
'provider_27'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/nexitallyy_Extra_Proxies.list','path'=>'REPL_RP/provider_27.list','interval'=>86400},
'provider_28'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_Twitter.list','path'=>'REPL_RP/provider_28.list','interval'=>86400},
'provider_29'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/naiixi_Extra_CN.list','path'=>'REPL_RP/provider_29.list','interval'=>86400},
'provider_30'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/naiixi_Extra_CN_2.list','path'=>'REPL_RP/provider_30.list','interval'=>86400},
'provider_31'=>{'type'=>'http','behavior'=>'classical','format'=>'text','url'=>'REPL_RB/blackmatrix7_WeChat.list','path'=>'REPL_RP/provider_31.list','interval'=>86400}
EOF
)
RPS=$(echo "$RPS" | sed "s|REPL_RB|${RULE_BASE}|g; s|REPL_RP|${RULE_PATH}|g")
ruby_merge_hash "$CONFIG_FILE" "['rule-providers']" "$RPS"

# ============ 2. 注入策略组（整体替换 proxy-groups）============
# include-all + filter 自动归类节点（换机场不用改）
# 节点名匹配：emoji + 国家代码 + 中文名（如「🇭🇰 HK | 香港 01」）
GROUPS=$(cat << 'EOF' | oneliner
[
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
]
EOF
)
ruby_edit "$CONFIG_FILE" "['proxy-groups']" "$GROUPS"

# ============ 3. 替换 rules（整体替换）============
# 关键：mihomo 内部流量直连规则必须放最前面！
# 若不直连，mihomo 下载 rule-provider 时命中 MATCH,✈️Final 走代理，
# 而代理依赖规则集 → EOF 死循环 → 规则集下载失败 → 节点全红
RULES=$(cat << 'EOF' | oneliner
[
"DOMAIN-SUFFIX,jsdelivr.net,🎯Direct",
"DOMAIN-SUFFIX,githubusercontent.com,🎯Direct",
"DOMAIN-SUFFIX,github.com,🎯Direct",
"DOMAIN-SUFFIX,raw.githubusercontent.com,🎯Direct",
"DOMAIN-SUFFIX,creamdata.xyz,🎯Direct",
"RULE-SET,provider_0,🎯Direct",
"RULE-SET,provider_1,Scholar",
"RULE-SET,provider_2,MyTVSuper",
"RULE-SET,provider_3,Crypto",
"RULE-SET,provider_4,AI",
"RULE-SET,provider_5,Google",
"RULE-SET,provider_6,YouTube",
"RULE-SET,provider_7,🎯Direct",
"RULE-SET,provider_8,🎯Direct",
"RULE-SET,provider_9,🎯Direct",
"RULE-SET,provider_10,Netflix",
"RULE-SET,provider_11,Telegram",
"RULE-SET,provider_12,Steam",
"RULE-SET,provider_13,Epic",
"RULE-SET,provider_14,Xbox",
"RULE-SET,provider_15,PlayStation",
"RULE-SET,provider_16,HBO",
"RULE-SET,provider_17,HBO",
"RULE-SET,provider_18,HBO",
"RULE-SET,provider_19,DisneyPlus",
"RULE-SET,provider_20,Bahamut",
"RULE-SET,provider_21,Bilibili",
"RULE-SET,provider_22,Microsoft",
"RULE-SET,provider_23,Apple",
"RULE-SET,provider_24,Tiktok",
"RULE-SET,provider_25,Proxies",
"RULE-SET,provider_26,Proxies",
"RULE-SET,provider_27,Proxies",
"RULE-SET,provider_28,Proxies",
"RULE-SET,provider_29,🎯Direct",
"RULE-SET,provider_30,🎯Direct",
"RULE-SET,provider_31,🎯Direct",
"GEOIP,CN,🎯Direct,no-resolve",
"MATCH,✈️Final"
]
EOF
)
ruby_edit "$CONFIG_FILE" "['rules']" "$RULES"

# ============ 4. 日志 ============
LOG_TIP "MyRules Custom Overwrite Complete."
exit 0
