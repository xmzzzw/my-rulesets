#!/bin/sh
# ============================================================
# OpenClash 覆写脚本 — my-rulesets 完整规格
# ============================================================
# 规格：
#   - 保留订阅 proxies
#   - 自建 VPS 节点以命名约定识别：^DMIT[space]*\|
#   - DMIT 节点不参与国家归类，也不会进入「🌍 其他地区」
#   - 🛠 DMIT自建 = select(自动 + 具体协议节点)
#   - 🛠 DMIT自建-自动 = url-test(具体协议节点)
#   - 动态国家分组：任一国家 >=2 节点建组；<=1 并入 🌍 其他地区
#   - 20 应用策略组 + Proxies + 🎯Direct + ✈️Final
#   - 32 个 rule-providers + 5 条内部直连 + GEOIP + MATCH
#
# UI 顺序：
#   Proxies → 应用组 → 🎯Direct → ✈️Final → DMIT自建(+自动)
#   → 国家分组(+自动) → 🌍 其他地区(+自动)
#
# 安全：公开仓库只包含命名/分组逻辑，不包含任何 VPS IP、PSK 或密码。
# ============================================================
. /usr/share/openclash/ruby.sh
. /usr/share/openclash/log.sh
. /lib/functions.sh

LOG_TIP "Start Running MyRules Custom Overwrite Scripts..."
CONFIG_FILE="$1"
RULE_BASE="https://testingcf.jsdelivr.net/gh/xmzzzw/my-rulesets@main/clash"
RULE_PATH="./rule_provider"
TEST_URL="http://www.gstatic.com/generate_204"

oneliner() {
  tr -d '\n' | sed 's/[[:space:]][[:space:]]*/ /g'
}

ruby_escape_file() {
  sed 's/\\/\\\\/g; s/"/\\"/g; s/.*/"&",/' "$1"
}

# ============ 1. 注入 rule-providers ============
RPS=$(cat << 'EOF_RPS' | oneliner
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
EOF_RPS
)
RPS=$(echo "$RPS" | sed "s|REPL_RB|${RULE_BASE}|g; s|REPL_RP|${RULE_PATH}|g")
ruby_merge_hash "$CONFIG_FILE" "['rule-providers']" "$RPS"

# ============ 2. 提取节点并分离自建节点 ============
NODE_NAMES_FILE=$(mktemp)
NORMAL_NODES_FILE=$(mktemp)
DMIT_NODES_FILE=$(mktemp)
ACTIVE_COUNTRIES_FILE=$(mktemp)
OTHER_NODES_FILE=$(mktemp)

ruby -ryaml -rYAML -I "/usr/share/openclash" -E UTF-8 -e '
  value = YAML.load_file(ARGV[0])
  Array(value["proxies"]).each do |p|
    n = p["name"]
    next unless n.is_a?(String) && !n.empty?
    puts n
  end
' "$CONFIG_FILE" 2>/dev/null \
  | grep -viE 'Traffic|Expire|流量|到期|剩余|套餐|官网|订阅|^Panel|^www\.|creamdata\.xyz|节点|主页' \
  > "$NODE_NAMES_FILE"

grep -iE '^DMIT[[:space:]]*\|' "$NODE_NAMES_FILE" > "$DMIT_NODES_FILE" || true
grep -viE '^DMIT[[:space:]]*\|' "$NODE_NAMES_FILE" > "$NORMAL_NODES_FILE" || true

# ============ 3. 国家识别表 ============
cat > /tmp/myrules_country_table << 'EOF_COUNTRY'
🇭🇰 香港@(香港|🇭🇰|[^A-Za-z]HK[^A-Za-z]|Hong ?Kong)
🇸🇬 新加坡@(新加坡|🇸🇬|[^A-Za-z]SG[^A-Za-z]|Singapore)
🇯🇵 日本@(日本|🇯🇵|[^A-Za-z]JP[^A-Za-z]|Japan)
🇺🇸 美国@(美国|🇺🇸|🇺🇲|[^A-Za-z]US[^A-Za-z]|America)
🇨🇳 台湾@(台湾|🇨🇳|🇹🇼|[^A-Za-z]TW[^A-Za-z]|Taiwan)
🇰🇷 韩国@(韩国|🇰🇷|[^A-Za-z]KR[^A-Za-z]|Korea)
🇬🇧 英国@(英国|🇬🇧|[^A-Za-z]GB[^A-Za-z]|[^A-Za-z]UK[^A-Za-z]|United ?Kingdom)
🇩🇪 德国@(德国|🇩🇪|[^A-Za-z]DE[^A-Za-z]|Germany)
🇦🇺 澳大利亚@(澳大利亚|澳洲|🇦🇺|[^A-Za-z]AU[^A-Za-z]|Australia)
🇨🇦 加拿大@(加拿大|🇨🇦|[^A-Za-z]CA[^A-Za-z]|Canada)
🇫🇷 法国@(法国|🇫🇷|[^A-Za-z]FR[^A-Za-z]|France)
🇷🇺 俄罗斯@(俄罗斯|🇷🇺|[^A-Za-z]RU[^A-Za-z]|Russia)
🇳🇱 荷兰@(荷兰|🇳🇱|[^A-Za-z]NL[^A-Za-z]|Netherlands)
🇮🇳 印度@(印度|🇮🇳|[^A-Za-z]IN[^A-Za-z]|India)
🇹🇷 土耳其@(土耳其|🇹🇷|[^A-Za-z]TR[^A-Za-z]|Turkey)
🇦🇪 阿联酋@(阿联酋|迪拜|🇦🇪|[^A-Za-z]AE[^A-Za-z]|Dubai)
🇮🇹 意大利@(意大利|🇮🇹|[^A-Za-z]IT[^A-Za-z]|Italy)
🇪🇸 西班牙@(西班牙|🇪🇸|[^A-Za-z]ES[^A-Za-z]|Spain)
🇧🇷 巴西@(巴西|🇧🇷|[^A-Za-z]BR[^A-Za-z]|Brazil)
🇲🇾 马来西亚@(马来西亚|🇲🇾|[^A-Za-z]MY[^A-Za-z]|Malaysia)
🇻🇳 越南@(越南|🇻🇳|[^A-Za-z]VN[^A-Za-z]|Vietnam)
🇹🇭 泰国@(泰国|🇹🇭|[^A-Za-z]TH[^A-Za-z]|Thailand)
🇵🇭 菲律宾@(菲律宾|🇵🇭|[^A-Za-z]PH[^A-Za-z]|Philippines)
🇮🇩 印尼@(印尼|印度尼西亚|🇮🇩|[^A-Za-z]ID[^A-Za-z]|Indonesia)
🇲🇽 墨西哥@(墨西哥|🇲🇽|[^A-Za-z]MX[^A-Za-z]|Mexico)
🇳🇿 新西兰@(新西兰|🇳🇿|[^A-Za-z]NZ[^A-Za-z]|New ?Zealand)
🇮🇪 爱尔兰@(爱尔兰|🇮🇪|[^A-Za-z]IE[^A-Za-z]|Ireland)
🇸🇪 瑞典@(瑞典|🇸🇪|[^A-Za-z]SE[^A-Za-z]|Sweden)
🇳🇴 挪威@(挪威|🇳🇴|[^A-Za-z]NO[^A-Za-z]|Norway)
🇫🇮 芬兰@(芬兰|🇫🇮|[^A-Za-z]FI[^A-Za-z]|Finland)
🇨🇭 瑞士@(瑞士|🇨🇭|[^A-Za-z]CH[^A-Za-z]|Switzerland)
🇵🇱 波兰@(波兰|🇵🇱|[^A-Za-z]PL[^A-Za-z]|Poland)
🇦🇷 阿根廷@(阿根廷|🇦🇷|[^A-Za-z]AR[^A-Za-z]|Argentina)
🇪🇬 埃及@(埃及|🇪🇬|[^A-Za-z]EG[^A-Za-z]|Egypt)
🇿🇦 南非@(南非|🇿🇦|[^A-Za-z]ZA[^A-Za-z]|South ?Africa)
🇺🇦 乌克兰@(乌克兰|🇺🇦|[^A-Za-z]UA[^A-Za-z]|Ukraine)
🇵🇹 葡萄牙@(葡萄牙|🇵🇹|[^A-Za-z]PT[^A-Za-z]|Portugal)
🇩🇰 丹麦@(丹麦|🇩🇰|[^A-Za-z]DK[^A-Za-z]|Denmark)
🇧🇪 比利时@(比利时|🇧🇪|[^A-Za-z]BE[^A-Za-z]|Belgium)
🇦🇹 奥地利@(奥地利|🇦🇹|[^A-Za-z]AT[^A-Za-z]|Austria)
🇭🇺 匈牙利@(匈牙利|🇭🇺|[^A-Za-z]HU[^A-Za-z]|Hungary)
🇨🇿 捷克@(捷克|🇨🇿|[^A-Za-z]CZ[^A-Za-z]|Czech)
🇬🇷 希腊@(希腊|🇬🇷|[^A-Za-z]GR[^A-Za-z]|Greece)
🇮🇱 以色列@(以色列|🇮🇱|[^A-Za-z]IL[^A-Za-z]|Israel)
🇨🇱 智利@(智利|🇨🇱|[^A-Za-z]CL[^A-Za-z]|Chile)
🇨🇴 哥伦比亚@(哥伦比亚|🇨🇴|[^A-Za-z]CO[^A-Za-z]|Colombia)
🇵🇪 秘鲁@(秘鲁|🇵🇪|[^A-Za-z]PE[^A-Za-z]|Peru)
EOF_COUNTRY

# ============ 4. 计算独立国家（仅普通机场节点） ============
while IFS='@' read -r name regex; do
  [ -z "$name" ] && continue
  cnt=$(grep -icE "$regex" "$NORMAL_NODES_FILE" || true)
  [ "$cnt" -ge 2 ] && printf '%s@%s@%s\n' "$cnt" "$name" "$regex"
done < /tmp/myrules_country_table \
  | sort -t'@' -k1,1 -rn > "$ACTIVE_COUNTRIES_FILE"

# 未进入独立国家组的普通节点归入「其他地区」。
while IFS= read -r node; do
  [ -z "$node" ] && continue
  matched=0
  while IFS='@' read -r cnt name regex; do
    [ -z "$name" ] && continue
    if printf '%s\n' "$node" | grep -qiE "$regex"; then
      matched=1
      break
    fi
  done < "$ACTIVE_COUNTRIES_FILE"
  [ "$matched" = "0" ] && printf '%s\n' "$node" >> "$OTHER_NODES_FILE"
done < "$NORMAL_NODES_FILE"

# ============ 5. 生成 DMIT / 国家 / 其他地区组 ============
DMIT_GROUPS=""
DMIT_TOP_REF=""
DMIT_APP_REF=""
AI_PREFIX=""
if [ -s "$DMIT_NODES_FILE" ]; then
  DMIT_REFS=$(ruby_escape_file "$DMIT_NODES_FILE" | tr -d '\n')
  DMIT_REFS="${DMIT_REFS%,}"
  DMIT_GROUPS="{\"name\"=>\"🛠 DMIT自建\",\"type\"=>\"select\",\"proxies\"=>[\"🛠 DMIT自建-自动\",${DMIT_REFS}]},{\"name\"=>\"🛠 DMIT自建-自动\",\"type\"=>\"url-test\",\"proxies\"=>[${DMIT_REFS}],\"url\"=>\"${TEST_URL}\",\"interval\"=>300,\"tolerance\"=>50},"
  DMIT_TOP_REF='"🛠 DMIT自建",'
  DMIT_APP_REF='"🛠 DMIT自建",'
  AI_PREFIX='"🛠 DMIT自建",'
fi

COUNTRY_REFS=""
COUNTRY_GROUPS=""
while IFS='@' read -r cnt name regex; do
  [ -z "$name" ] && continue
  COUNTRY_FILE=$(mktemp)
  grep -iE "$regex" "$NORMAL_NODES_FILE" > "$COUNTRY_FILE" || true
  NODE_REFS=$(ruby_escape_file "$COUNTRY_FILE" | tr -d '\n')
  NODE_REFS="${NODE_REFS%,}"
  rm -f "$COUNTRY_FILE"
  [ -z "$NODE_REFS" ] && continue
  COUNTRY_REFS="${COUNTRY_REFS}\"${name}\","
  COUNTRY_GROUPS="${COUNTRY_GROUPS}{\"name\"=>\"${name}\",\"type\"=>\"select\",\"proxies\"=>[\"${name}-自动\",${NODE_REFS}]},{\"name\"=>\"${name}-自动\",\"type\"=>\"url-test\",\"proxies\"=>[${NODE_REFS}],\"url\"=>\"${TEST_URL}\",\"interval\"=>300,\"tolerance\"=>50},"
done < "$ACTIVE_COUNTRIES_FILE"

OTHER_GROUPS=""
if [ -s "$OTHER_NODES_FILE" ]; then
  OTHER_REFS=$(ruby_escape_file "$OTHER_NODES_FILE" | tr -d '\n')
  OTHER_REFS="${OTHER_REFS%,}"
  COUNTRY_REFS="${COUNTRY_REFS}\"🌍 其他地区\","
  OTHER_GROUPS="{\"name\"=>\"🌍 其他地区\",\"type\"=>\"select\",\"proxies\"=>[\"🌍 其他地区-自动\",${OTHER_REFS}]},{\"name\"=>\"🌍 其他地区-自动\",\"type\"=>\"url-test\",\"proxies\"=>[${OTHER_REFS}],\"url\"=>\"${TEST_URL}\",\"interval\"=>300,\"tolerance\"=>50},"
fi

TOP_REFS="${DMIT_TOP_REF}${COUNTRY_REFS}"
APP_REFS="${DMIT_APP_REF}${COUNTRY_REFS}"

# ============ 6. 组装 proxy-groups ============
GROUPS=$(cat << EOF_GROUPS | oneliner
[
{"name"=>"Proxies","type"=>"select","proxies"=>[${TOP_REFS}]},
{"name"=>"AI","type"=>"select","proxies"=>[${AI_PREFIX}"Proxies","🎯Direct",${COUNTRY_REFS}]},
{"name"=>"Netflix","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"HBO","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"DisneyPlus","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"YouTube","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Bahamut","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Bilibili","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"MyTVSuper","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Telegram","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Crypto","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Steam","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Epic","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Xbox","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"PlayStation","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Microsoft","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Scholar","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Apple","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Google","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"Tiktok","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
{"name"=>"🎯Direct","type"=>"select","proxies"=>["DIRECT","Proxies"]},
{"name"=>"✈️Final","type"=>"select","proxies"=>["Proxies","🎯Direct",${APP_REFS}]},
${DMIT_GROUPS}${COUNTRY_GROUPS}${OTHER_GROUPS}
]
EOF_GROUPS
)
ruby_edit "$CONFIG_FILE" "['proxy-groups']" "$GROUPS"

# ============ 7. 重写 rules ============
RULES=$(cat << 'EOF_RULES' | oneliner
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
EOF_RULES
)
ruby_edit "$CONFIG_FILE" "['rules']" "$RULES"

rm -f "$NODE_NAMES_FILE" "$NORMAL_NODES_FILE" "$DMIT_NODES_FILE" "$ACTIVE_COUNTRIES_FILE" "$OTHER_NODES_FILE" /tmp/myrules_country_table
LOG_TIP "MyRules Custom Overwrite Complete."
exit 0
