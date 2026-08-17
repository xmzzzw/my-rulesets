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
#
# ⚠️ 「🌍 其他地区」必须用【排除式 filter】（排除所有已建独立国家分组的正则），
#   而非裸 include-all。裸 include-all 会把订阅里【全部】节点拽进「其他地区」，
#   导致已分配到 🇭🇰 香港/🇯🇵 日本 等独立分组的节点在这里重复出现 —— 用户报告的 bug。
#   排除式 filter：(?i)^(?!.*(香港|HK|日本|JP|...)).*$ 只放行未命中任何国家正则的节点。
#
# ⚠️ 国家匹配须精确，避免大小写不敏感的子串误命中：
#   原版 grep -icE "ID" 会让「印尼」计数命中 "Valid"/"Provider" 等英文单词里的 ID，
#   → 单节点国家被误判 ≥2 → 误建组。现对【国家代码】加【词边界】（前后非字母），
#   emoji/中文仍用普通包含；计数仍用 grep -iE 但正则自带边界。
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

# ---------- 2.1 提取订阅节点名列表（用 ruby 解析 YAML）----------
# 关键：必须用 ruby 的 YAML.load_file 提取真实节点名，不能用 awk/sed 手工解析。
#   OpenClash 把订阅下载后经 yml_change.sh 处理，emoji 节点名在 YAML 里被转义为
#   "\U0001F1F5\U0001F1ED" 形式（字面反斜杠+U，非真实 emoji 字节）。awk/sed 手工
#   解析只能拿到 "\U0001F1F5" 字面串，无法还原成真实 emoji → 「其他地区」显式
#   proxies 引用的节点名与 mihomo 加载后的真实节点名不一致 → fatal not found → 节点全红。
#   ruby 的 YAML.load_file 会正确还原所有 \U/"\\/quote 转义，得到真实 UTF-8 emoji 字节，
#   且天然兼容 block/flow 两种 YAML 写法。
# 过滤流量/到期/面板伪节点（与 overwrite_script.js 一致，不进任何策略组）。
NODE_NAMES_FILE=$(mktemp)
ruby -ryaml -rYAML -I "/usr/share/openclash" -E UTF-8 -e '
  Value = YAML.load_file(ARGV[0])
  Value["proxies"].each do |p|
    n = p["name"]
    next unless n.is_a?(String) && !n.empty?
    puts n
  end
' "$CONFIG_FILE" 2>/dev/null \
  | grep -viE 'Traffic|Expire|流量|到期|剩余|套餐|官网|订阅|^Panel|^www\.|creamdata\.xyz|节点|主页' \
  > "$NODE_NAMES_FILE"

# ---------- 2.2 国家 → 匹配正则 映射表（写死，避免多行 heredoc 的转义问题）----------
# 每行：组名@正则。正则为 grep -E 语法。统计命中该正则的节点数，≥2 才建组。
#
# 匹配精度（修复「单节点国家被误建组」bug）：
#   - emoji 与中文：普通包含即可（如 香港 / 🇭🇰），不存在子串污染。
#   - 英文国家代码：加 grep -E 词边界 [^A-Za-z] 包夹（非字母边界），
#     防止 "ID" 命中 "Valid"、"IN" 命中 "Pinyin"、"US" 命中 "Status" 等误判。
#     用 [^A-Za-z] 而非 \b：\b 对 emoji/中文边界行为不定，[[:space:]]又不覆盖标点。
#   - 英文全名（Hong Kong/Singapore）：词身自身够长不污染，普通包含。
#   实测 CreamData / Flower 多机场均不再误建单节点组。
cat > /tmp/myrules_country_table << 'TABEOF'
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
TABEOF

# ---------- 2.3 统计国家节点数，生成 ≥2 的分组 ----------
# 输出文件每行：组名|正则|计数（节点多的排前面）
MATCHED_FILE=$(mktemp)
while IFS='@' read -r name regex; do
    [ -z "$name" ] && continue
    cnt=$(grep -icE "$regex" "$NODE_NAMES_FILE" || true)
    [ "$cnt" -ge 2 ] && echo "$cnt@$name@$regex"
done < /tmp/myrules_country_table > "$MATCHED_FILE"
# 按计数降序排序（国家分组按节点数排序：节点最多的国家排最前）
# ⚠️ 计数必须作第一列再用 -k1,1 -rn：原版用 -k3 排「名@正则@计数」时，
# busybox sort 对含多字节 emoji 的行按字节比较，-k3 字段定位被干扰 → 排序错乱
# （实测：美国18→土耳其2→新加坡19→香港25 混乱）。前置纯数值列后稳定降序。
sort -t'@' -k1,1 -rn "$MATCHED_FILE" > /tmp/myrules_matched_sorted

# ---------- 2.3b 计算「🌍 其他地区」成员：未被任何 ≥2 国家正则命中的节点 ----------
# 修复「其他地区」含已分配国家分组节点的 bug：
#   原版用裸 include-all =>true 且无 filter → 把订阅【全部】节点吸进「其他地区」，
#   香港/日本/美国等已建独立分组的节点在此重复出现。
#   RE2 不支持负向断言 (?!...)，无法用一行的排除式 filter；故改为【显式枚举】，
#   与 overwrite_script.js / convert.py 三端逻辑统一：只放进未命中任何独立国家正则的节点。
#   单节点国家（<2 未建组）的节点天然落回这里 —— 不再被误建独立组，也不漏。
OTHER_NODES_FILE=$(mktemp)
while IFS= read -r node; do
    [ -z "$node" ] && continue
    matched=0
    while IFS='@' read -r ccnt cname cregex; do
        [ -z "$cname" ] && continue
        if printf '%s' "$node" | grep -qiE "$cregex"; then matched=1; break; fi
    done < /tmp/myrules_matched_sorted
    [ "$matched" = "0" ] && printf '%s\n' "$node"
done < "$NODE_NAMES_FILE" > "$OTHER_NODES_FILE"

# 生成 Ruby proxies 字面量：节点名转义 " 与 \ 后，拼成 "名","名",...
# ⚠️ 必须用 sed 字面拼接，不能用 printf '%s' —— 早期版本用 printf 链生成，
# emoji 多字节字符经 printf/sed 某步被破坏成字面 "\U0001F1F5..."，写入 YAML
# 后节点名与订阅真实节点名不匹配 → mihomo 报 fatal「not found」→ 内核启动失败、节点全红。
# sed 的 ./x77/ 不涉及格式化解析，仅替换 \ 与 "，emoji 字节原封不动通过。
# 先在文件层把每个 " 转义成 \"、\ 转义成 \\，再逐行包成 "...", 。
ruby_escape_file() {
    sed 's/\\/\\\\/g; s/"/\\"/g; s/.*/"&",/' "$1"
}
OTHER_REFS=$(ruby_escape_file "$OTHER_NODES_FILE" | tr -d '\n')
OTHER_REFS="${OTHER_REFS%,}"   # 去末尾逗号（无节点时为空串）

# ---------- 2.4 生成国家分组 Ruby 片段（select + url-test 自动）----------
# 国家分组用 include-all + filter 收【本国家】节点（正确：filter 只吸命中该国的节点）。
# NAT_GROUPS：形如
#   {"name"=>"🇫🇷 法国","type"=>"select","include-all"=>true,"filter"=>"(?i)...","proxies"=>["🇫🇷 法国-自动"]},
#   {"name"=>"🇫🇷 法国-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)...","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},
NAT_GROUPS=$(while IFS='@' read -r cnt name regex; do
    [ -z "$name" ] && continue
    printf '{"name"=>"%s","type"=>"select","include-all"=>true,"filter"=>"(?i)%s","proxies"=>["%s-自动"]},' "$name" "$regex" "$name"
    printf '{"name"=>"%s-自动","type"=>"url-test","include-all"=>true,"filter"=>"(?i)%s","url"=>"http://www.gstatic.com/generate_204","interval"=>300,"tolerance"=>50},' "$name" "$regex"
done < /tmp/myrules_matched_sorted)

# ---------- 2.5 生成国家组名引用列表 ----------
# GROUP_REFS：形如 "🇭🇰 香港","🇫🇷 法国",...[:,"🌍 其他地区"]
# 「🌍 其他地区」仅在有未归类节点（OTHER_REFS 非空）时才加入引用，
# 避免引用一个无成员的空组（mihomo url-test 无节点会启动失败）。
GROUP_REFS=$(while IFS='@' read -r cnt name regex; do
    [ -z "$name" ] && continue
    printf '"%s",' "$name"
done < /tmp/myrules_matched_sorted)
# 「其他地区」组 + 引用条件化：仅有未归类节点时生成。
# 注意：OTHER_REFS 必须在此【直接展开】成实际节点名，不能作为 Ruby 字面词
# 留在 OTHER_GROUPS 里 —— 早期版本把 OTHER_REFS 当占位符写给 sed 替换，
# 但 sed 不会替换值内部的占位符（只替换模板行的占位用作 sed 目标），
# 导致 Ruby 看到裸词 OTHER_REFS 报「uninitialized constant」→ 整个 proxy-groups 片段失败。
if [ -n "$OTHER_REFS" ]; then
    GROUP_REFS="${GROUP_REFS}\"🌍 其他地区\""
    OTHER_GROUPS="{\"name\"=>\"🌍 其他地区\",\"type\"=>\"select\",\"proxies\"=>[\"🌍 其他地区-自动\",${OTHER_REFS}]},{\"name\"=>\"🌍 其他地区-自动\",\"type\"=>\"url-test\",\"proxies\"=>[${OTHER_REFS}],\"url\"=>\"http://www.gstatic.com/generate_204\",\"interval\"=>300,\"tolerance\"=>50}"
else
    OTHER_GROUPS=""
fi
# 去末尾逗号使 JSON 更干净（Ruby 容忍尾逗号，但保险）
GROUP_REFS="${GROUP_REFS%,}"

# ---------- 2.6 组装 GROUPS（单行 Ruby 数组）----------
# 顺序严格：Proxies → 20 应用组 → 🎯Direct → ✈️Final → 国家分组(+自动) → [可选]🌍 其他地区(+自动)
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
NAT_GROUPSOTHER_GROUPS
]
EOF
)
# 替换占位符（用 @ 做 sed 分隔符：NAT_GROUPS/OTHER_GROUPS 含正则管道符 |，不能用 | 作分隔符）
GROUPS=$(echo "$GROUPS" | sed "s@GROUP_REFS@${GROUP_REFS}@g; s@NAT_GROUPS@${NAT_GROUPS}@g; s@OTHER_GROUPS@${OTHER_GROUPS}@g")
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
