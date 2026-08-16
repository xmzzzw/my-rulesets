#!/bin/sh
# ============================================================
# OpenClash 覆写脚本 — my-rulesets 完整规格
# 将机场订阅配置改造为「my-rulesets」统一规格
# 放置位置：/etc/openclash/custom/openclash_custom_overwrite.sh
#
# 规格（与 overwrite_script.js / 已验证的 FlClash 版一致）：
#   - 保留订阅节点（proxies 原样保留）
#   - 20 应用策略组（AI/Netflix/HBO/...）+ Proxies + 🎯Direct + ✈️Final
#     + 动态国家分组（≥2 节点即建组）+ 各 -自动 + 🌍 其他地区
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
# 动态国家分组：统计订阅里各国家节点数，≥2 节点的国家才建独立分组，
# 否则并入 🌍 其他地区（用户规范：≥2 节点即单独建组）。
# 节点名匹配：emoji + 国家代码 + 中文名（如「🇭🇰 HK | 香港 01」）。
#
# POSIX sh 实现（OpenClash 用 busybox ash）：不用关联数组/管道赋值，
# 统计结果写入临时文件，保证变量在父 shell 生效。

# ---------- 2.1 提取订阅节点名列表 ----------
# 节点在 YAML 里形如：- name: '🇭🇰 HK | 香港 01'
NODE_NAMES_FILE=$(mktemp)
grep -E '^[[:space:]]*-[[:space:]]*name:' "$CONFIG_FILE" \
  | sed -E "s/^[[:space:]]*-[[:space:]]*name:[[:space:]]*//; s/^['\"]//; s/['\"][[:space:]]*$//" \
  > "$NODE_NAMES_FILE"

# ---------- 2.2 国家 → 匹配正则 映射表（写死，避免多行 heredoc 的转义问题）----------
# 每行：组名|正则。正则为 grep -E 语法。
# 统计命中该正则的节点数，≥2 才建组。
cat > /tmp/myrules_country_table << 'TABEOF'
🇭🇰 香港|(?i)(香港|HK|Hong[[:space:]]?Kong)
🇸🇬 新加坡|(?i)(新加坡|SG|Singapore)
🇯🇵 日本|(?i)(日本|JP|Japan)
🇺🇸 美国|(?i)(美国|US|America)
🇨🇳 台湾|(?i)(台湾|TW|Taiwan)
🇰🇷 韩国|(?i)(韩国|KR|Korea)
🇬🇧 英国|(?i)(英国|GB|UK|United[[:space:]]?Kingdom)
🇩🇪 德国|(?i)(德国|DE|Germany)
🇦🇺 澳大利亚|(?i)(澳大利亚|澳洲|AU|Australia)
🇨🇦 加拿大|(?i)(加拿大|CA|Canada)
🇫🇷 法国|(?i)(法国|FR|France)
🇷🇺 俄罗斯|(?i)(俄罗斯|RU|Russia)
🇳🇱 荷兰|(?i)(荷兰|NL|Netherlands)
🇮🇳 印度|(?i)(印度|IN|India)
🇹🇷 土耳其|(?i)(土耳其|TR|Turkey)
🇦🇪 阿联酋|(?i)(阿联酋|迪拜|AE|Dubai)
🇮🇹 意大利|(?i)(意大利|IT|Italy)
🇪🇸 西班牙|(?i)(西班牙|ES|Spain)
🇧🇷 巴西|(?i)(巴西|BR|Brazil)
🇲🇾 马来西亚|(?i)(马来西亚|MY|Malaysia)
🇻🇳 越南|(?i)(越南|VN|Vietnam)
🇹🇭 泰国|(?i)(泰国|TH|Thailand)
🇵🇭 菲律宾|(?i)(菲律宾|PH|Philippines)
🇮🇩 印尼|(?i)(印尼|ID|Indonesia)
🇲🇽 墨西哥|(?i)(墨西哥|MX|Mexico)
🇳🇿 新西兰|(?i)(新西兰|NZ|New[[:space:]]?Zealand)
🇮🇪 爱尔兰|(?i)(爱尔兰|IE|Ireland)
🇸🇪 瑞典|(?i)(瑞典|SE|Sweden)
🇳🇴 挪威|(?i)(挪威|NO|Norway)
🇫🇮 芬兰|(?i)(芬兰|FI|Finland)
🇨🇭 瑞士|(?i)(瑞士|CH|Switzerland)
🇵🇱 波兰|(?i)(波兰|PL|Poland)
🇦🇷 阿根廷|(?i)(阿根廷|AR|Argentina)
🇪🇬 埃及|(?i)(埃及|EG|Egypt)
🇿🇦 南非|(?i)(南非|ZA|South[[:space:]]?Africa)
TABEOF

# ---------- 2.3 统计国家节点数，生成 ≥2 的分组 ----------
# 输出文件每行：组名|正则|计数（节点多的排前面）
MATCHED_FILE=$(mktemp)
while IFS='|' read -r name regex; do
    [ -z "$name" ] && continue
    cnt=$(grep -cE "$regex" "$NODE_NAMES_FILE" || true)
    [ "$cnt" -ge 2 ] && echo "$name|$regex|$cnt"
done < /tmp/myrules_country_table > "$MATCHED_FILE"
# 按计数降序排序
sort -t'|' -k3 -rn "$MATCHED_FILE" > /tmp/myrules_matched_sorted

# ---------- 2.4 生成国家分组 Ruby 片段（select + url-test 自动）----------
# NAT_GROUPS：形如
#   {"name"=>"🇫🇷 法国","type"=>"select","include-all"=>true,"filter"=>"...","proxies"=>["🇫🇷 法国-自动"]},
#   {"name"=>"🇫🇷 法国-自动","type"=>"url-test","include-all"=>true,"filter"=>"...","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
NAT_GROUPS=$(while IFS='|' read -r name regex cnt; do
    [ -z "$name" ] && continue
    printf '{"name"=>"%s","type"=>"select","include-all"=>true,"filter"=>"%s","proxies"=>["%s-自动"]},' "$name" "$regex" "$name"
    printf '{"name"=>"%s-自动","type"=>"url-test","include-all"=>true,"filter"=>"%s","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},' "$name" "$regex"
done < /tmp/myrules_matched_sorted)

# ---------- 2.5 生成国家组名引用列表 ----------
# GROUP_REFS：形如 "🇭🇰 香港","🇫🇷 法国",...,"🌍 其他地区"（供 Proxies/应用组/Final 引用）
GROUP_REFS=$(while IFS='|' read -r name regex cnt; do
    [ -z "$name" ] && continue
    printf '"%s",' "$name"
done < /tmp/myrules_matched_sorted)
GROUP_REFS="${GROUP_REFS}\"🌍 其他地区\""

# ---------- 2.6 组装 GROUPS（单行 Ruby 数组）----------
# 顺序严格：Proxies → 20 应用组 → 🎯Direct → ✈️Final → 国家分组(+自动) → 🌍 其他地区(+自动)
GROUPS=$(cat << 'EOF' | oneliner
[
{"name"=>"Proxies","type"=>"select","proxies"=>[GROUP_REFS]},
{"name"=>"AI","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Netflix","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"HBO","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"DisneyPlus","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"YouTube","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Bahamut","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Bilibili","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"MyTVSuper","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Telegram","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Crypto","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Steam","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Epic","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Xbox","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"PlayStation","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Microsoft","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Scholar","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Apple","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Google","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"Tiktok","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
{"name"=>"🎯Direct","type"=>"select","proxies"=>["DIRECT","Proxies"]},
{"name"=>"✈️Final","type"=>"select","proxies"=>["Proxies","🎯Direct",GROUP_REFS]},
NAT_GROUPS
{"name"=>"🌍 其他地区","type"=>"select","include-all"=>true,"proxies"=>["🌍 其他地区-自动"]},
{"name"=>"🌍 其他地区-自动","type"=>"url-test","include-all"=>true,"url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50}
]
EOF
)
# 替换占位符
GROUPS=$(echo "$GROUPS" | sed "s|GROUP_REFS|${GROUP_REFS}|g; s|NAT_GROUPS|${NAT_GROUPS}|g")
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
