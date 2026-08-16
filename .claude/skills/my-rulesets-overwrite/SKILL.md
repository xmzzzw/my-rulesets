---
name: my-rulesets-overwrite
description: 各 Clash 系客户端及主流代理软件的「机场订阅覆写」方法集锦。当用户要求"给 XX 客户端写覆写脚本""Clash Verge 怎么覆写""FlClash 覆写方法""OpenClash 覆写踩坑""把订阅换成自己的分流规则"时使用。含 OpenClash 两个致命坑（单行片段机制 / rule-provider 下载 EOF 死循环）与广播 IP 判定。
---

# my-rulesets 覆写方法（各客户端）

把机场订阅改造成「my-rulesets 规格」的覆写方法，覆盖 Clash 系全家桶 + 其他主流代理软件。

## 何时使用

- 用户要求给某个客户端写覆写 / 改分流规则
- "Clash Verge 怎么覆写" / "FlClash 覆写" / "OpenClash 覆写"
- 换机场后让各端自动套用 my-rulesets 规格
- OpenClash 覆写不生效 / 节点全红排查

## 覆写链接（my-rulesets GitHub 仓库）

- 仓库：`https://github.com/xmzzzw/my-rulesets`
- **FlClash / Clash Verge JS 脚本**：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js`
- **OpenClash Ruby 覆写脚本**：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/openclash_overwrite.sh`
- **Clash 规则集**：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/clash/<规则集>.list`
- **Surge 规则集**：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/<规则集>.list`
- 教程文档：`https://github.com/xmzzzw/my-rulesets/blob/main/OVERWRITE.md`

## 覆写本质

各客户端「订阅拉节点 + 覆写注入分流」的统一思想：
1. **保留订阅的 proxies（节点）**
2. **重建 proxy-groups**（国家分组 + 各 -自动 url-test + 应用组 + Direct/Final）
3. **注入 rule-providers**（引用 my-rulesets 的 clash/ 规则集）
4. **重写 rules**（RULE-SET + GEOIP,CN + MATCH）

## 各客户端覆写方法

### FlClash（安卓）
- 位置：配置 → 覆写 → 脚本模式
- 支持从 URL 导入脚本：粘贴 `overwrite_script.js` 的 raw URL
- `main(config)` 入口，JS 直接改 config 对象返回

### Clash Verge Rev（Windows）
- 订阅右键 → 新建脚本 profile
- `function main(config, profileName)` 入口，返回改后的 config
- 新版已移除 prepend/append，改「编辑规则/编辑代理组」，但脚本 profile 仍可用

### OpenClash（软路由）
- 覆写脚本 → `/etc/openclash/custom/openclash_custom_overwrite.sh`
- Ruby 函数操作 YAML（`ruby_merge_hash`/`ruby_edit`/`ruby_arr_insert_hash`）
- ⚠️ 见下方「OpenClash 致命坑」

### Surge（Mac/iOS）
- [Rule] 段直接引用远程规则集：
  ```
  RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/<规则集>.list,<策略>,update-interval=86400
  ```
- [Proxy] 段用 `#!include <订阅URL>` 保留订阅刷新

### ClashX / ClashX Pro（Mac）
- 订阅配置（clash 格式）+ 远程 rule-providers
- 或参考 FlClash 思路，但 ClashX 无脚本覆写 → 用完整配置

### Shadowrocket（iOS）
- 配置片段：`[Rule]` 段引用远程 RULE-SET
- URL 规则：`RULE-SET,<url>,<策略>`

### Loon（iOS）
- 配置文件引用：`RULE-SET,<url>,<策略>`
- 插件可脚本覆写

### sing-box
- 配置 JSON 的 `route.rules` + `rule_set` 引用远程
- 或用转换工具生成完整配置

## OpenClash 致命坑（重点）

### 坑 1：Ruby 覆写片段必须单行！

OpenClash 的 init.d（`/etc/init.d/openclash`）**用 grep 按「行」提取覆写脚本生成的 Ruby 片段**：
```bash
ruby_code=$(grep "yaml_file_path='$yaml_file'" /tmp/yaml_openclash_ruby_parse | sed "s/^threads << Thread.new do //;s/ end$//")
```
**多行参数会被截断只剩第一行** → Ruby 语法错误（`unexpected rescue`）→ 覆写静默失效（日志显示 Complete 但配置没变）。

**症状**：日志有 `Start Running MyRules Custom Overwrite Scripts...` + `Complete`，但运行配置结构没变化（还是机场原始分组）。

**解决**：所有 `ruby_*` 函数参数**必须单行**。脚本里用 heredoc + `tr -d '\n'` 压缩：
```sh
oneliner() { tr -d '\n' | sed 's/[[:space:]][[:space:]]*/ /g'; }
GROUPS=$(cat << 'EOF' | oneliner
[{...},{...}]
EOF
)
ruby_edit "$CONFIG_FILE" "['proxy-groups']" "$GROUPS"
```

### 坑 2：rule-provider 下载 EOF 死循环 → 节点全红

mihomo 启动时下载 rule-provider（规则集），若下载流量**命中 `MATCH,✈️Final` 走了代理**，而代理依赖这些规则集 → **EOF 死循环** → 规则集加载失败 → 节点全红。

**症状**：内核日志大量 `[Provider] provider_N pull error: Get "...": EOF`；节点全红。

**解决**（两层）：
1. **规则最前面加 mihomo 内部流量直连**：
   ```
   DOMAIN-SUFFIX,jsdelivr.net,🎯Direct
   DOMAIN-SUFFIX,githubusercontent.com,🎯Direct
   DOMAIN-SUFFIX,github.com,🎯Direct
   DOMAIN-SUFFIX,raw.githubusercontent.com,🎯Direct
   ```
2. **provider url 用 jsdelivr CDN 而非 raw.githubusercontent.com**：
   ```
   https://testingcf.jsdelivr.net/gh/xmzzzw/my-rulesets@main/clash/<规则集>.list
   ```
   raw.githubusercontent.com 在软路由直连常被墙/EOF。注意：OpenClash 的 `github_address_mod` 改写发生在覆写脚本**之前**，会被覆盖，所以直接写 jsdelivr 最稳。

### 坑 3：OpenClash 快速启动跳过覆写

- OpenClash 有「Quick Start Mode」：监控文件时间戳，未修改则跳过配置生成
- **改了覆写脚本必须 `touch` 或删 `/tmp/openclash.change`** 再重启
- 否则日志出现 `Step 3: Quick Start Mode, Skip Modify The Config File...` → 覆写不生效

### 坑 4：proxy-groups 是 Array，ruby_merge_hash 会报错

`ruby_merge_hash` 用 `merge!`，只适用于 Hash（rule-providers/proxy-providers）。proxy-groups 是 Array，`merge!` 报 `undefined method merge! for Array`。**proxy-groups 必须用 `ruby_edit` 整体赋值**。

## 广播 IP 判定（机场节点 IP 归属）

**机场「广播 IP」**：所有节点共享同一出口 IP 池，标注国家与实际出口可能不一致。

**实例**（CreamData）：所有「美国/新加坡/日本」节点实际出口都是香港 `AS398704 STACKS INC`。OpenAI/ChatGPT 判定香港为不支持地区 → 403「国家不支持」。

**排查**：
```bash
curl -s -x http://<认证>@127.0.0.1:7890 'https://ipinfo.io/json' | grep -E '"country"|"org"'
```

**结论**：广播 IP 机场的「地区限制」问题无法靠覆写解决（配置再对，出口 IP 不变）。需原生 IP 机场或真家宽节点。

## 验证方法

- **mihomo 校验**：`/etc/openclash/clash -t -d /tmp -f <config>.yaml` → `test is successful`
- **节点延迟**（OpenClash API）：
  ```bash
  curl -s -H 'Authorization: Bearer <secret>' -X GET 'http://127.0.0.1:9090/group/<urlencoded>/delay?url=http://www.gstatic.com/generate_204&timeout=3000'
  ```
- **流量走向**（内核日志）：
  ```bash
  grep -iE 'chatgpt|openai' /tmp/openclash.log
  ```

## 关联

- [[my-rulesets-convert]]（订阅转换 skill）
- 记忆：[[openclash-r2s-deployment]]、[[tower-rules-customization]]
