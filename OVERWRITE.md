# 覆写教程：把机场订阅改造成 my-rulesets 规格

> 各 Clash 系客户端 + 主流代理软件的「订阅覆写」方法，以及踩过的坑。
> 覆写 = 订阅拉节点 + 自定义分流规则，让机场订阅套用你自己的 my-rulesets 规格。

## 目录

- [覆写链接速查](#覆写链接速查)
- [覆写核心思想](#覆写核心思想)
- [各客户端覆写方法](#各客户端覆写方法)
  - [FlClash（安卓）](#flclash安卓)
  - [Clash Verge Rev（Windows）](#clash-verge-revwindows)
  - [OpenClash（软路由）](#openclash软路由)
  - [Surge（Mac/iOS）](#surge-macios)
  - [ClashX / ClashX Pro（Mac）](#clashx--clashx-promac)
  - [Shadowrocket（iOS）](#shadowrocketios)
  - [Loon（iOS）](#loonioos)
  - [sing-box](#sing-box)
- [OpenClash 踩坑记录](#openclash-踩坑记录)
- [广播 IP 判定](#广播-ip-判定)
- [验证方法](#验证方法)

---

## 覆写链接速查

| 资源 | 链接 |
|------|------|
| 仓库 | `https://github.com/xmzzzw/my-rulesets` |
| FlClash / Clash Verge JS 脚本 | `https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js` |
| OpenClash Ruby 脚本 | `https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/openclash_overwrite.sh` |
| Clash 规则集 | `https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/clash/<规则集>.list` |
| Surge 规则集 | `https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/<规则集>.list` |
| 本教程 | `https://github.com/xmzzzw/my-rulesets/blob/main/OVERWRITE.md` |

> ⚠️ **OpenClash 用 jsdelivr 加速**（raw.githubusercontent.com 常被墙）：
> `https://testingcf.jsdelivr.net/gh/xmzzzw/my-rulesets@main/clash/<规则集>.list`

---

## 覆写核心思想

所有客户端的覆写都是同一个套路：

1. **保留订阅的 proxies**（节点列表，换机场时自动更新）
2. **重建 proxy-groups**：
   - 国家分组（🇭🇰 香港 / 🇺🇸 美国 / 🇯🇵 日本 / 🇸🇬 新加坡 / 🇨🇳 台湾 / 🇰🇷 韩国...）
   - 各国家 `-自动`（url-test，延迟自动选择/故障转移）
   - 🌍 其他地区
   - 应用组（Netflix / AI / YouTube / Telegram / Crypto / Steam...）
   - 🎯Direct / ✈️Final 兜底
3. **注入 rule-providers**（引用 my-rulesets 的 `clash/` 规则集）
4. **重写 rules**（`RULE-SET` + `GEOIP,CN,DIRECT` + `MATCH`）

换机场时只需更新订阅，分流规则自动套用，**不用改配置**。

---

## 各客户端覆写方法

### FlClash（安卓）

1. **添加订阅**：FlClash → 配置 → 右上角 + → 粘贴机场订阅链接
2. **配置覆写**：进入订阅 → 「覆写」→ 选「脚本」模式
3. **导入脚本**：脚本编辑器 → 右上角菜单 → 「外部获取」→ 从 URL 导入
4. **粘贴**：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js`
5. **保存**，自动生效

**脚本特征**：`function main(config) { ...; return config; }`，直接改 config 对象。

> 流量进度条依赖订阅响应头 `subscription-userinfo`，机场支持则自动显示。

### Clash Verge Rev（Windows）

1. **添加订阅**：订阅 URL
2. **新建脚本 profile**：订阅右键 → 「脚本」→ 新建
3. **粘贴脚本**（可从 URL 获取）：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js`
4. **保存**

**脚本特征**：`function main(config, profileName) { ...; return config; }`。

> 新版 Clash Verge 移除了 prepend/append（改「编辑规则/编辑代理组」界面），但脚本 profile 仍可用。

### OpenClash（软路由）

1. **配置订阅**：机场订阅链接（Clash 格式）
2. **放置覆写脚本**：
   ```bash
   # 下载脚本到 r2s
   curl -sL --noproxy '*' -o /etc/openclash/custom/openclash_custom_overwrite.sh \
     https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/openclash_overwrite.sh
   chmod +x /etc/openclash/custom/openclash_custom_overwrite.sh
   ```
3. **重启 OpenClash** 生效

**机制**：init.d 启动时对订阅配置应用覆写脚本（Ruby 操作 YAML）。

> ⚠️ **改完脚本必须触发完整流程**：`touch /etc/openclash/custom/openclash_custom_overwrite.sh` 并删 `/tmp/openclash.change`，否则「Quick Start Mode」跳过覆写。

**常见坑**（详见下方踩坑记录）：
- Ruby 片段必须单行（grep 按行提取）
- proxy-groups 是 Array，用 `ruby_edit` 不用 `ruby_merge_hash`
- provider url 用 jsdelivr，规则加 mihomo 内部流量直连

### Surge（Mac/iOS）

在 `[Rule]` 段引用远程规则集：

```ini
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_AI.list,AI,update-interval=86400
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_CN_3.list,🎯Direct,update-interval=86400
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/blackmatrix7_Google.list,Google,update-interval=86400
```

`[Proxy]` 段保留订阅刷新（订阅 URL 直连抓取，`--noproxy '*'`）：

```ini
[Proxy]
#!include <机场订阅URL>
```

> Surge 规则集用仓库根目录 `*.list`；Clash 用 `clash/*.list`（兼容 mihomo classical）。

### ClashX / ClashX Pro（Mac）

ClashX 无脚本覆写，用完整配置方式：

1. 订阅为 Clash YAML 格式
2. 配置里引用远程 rule-providers：
   ```yaml
   rule-providers:
     ai:
       type: http
       behavior: classical
       format: text
       url: https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/clash/nexitallyy_Extra_AI.list
       path: ./rules/ai.list
       interval: 86400
   ```
3. rules 引用 `RULE-SET,ai,AI`

### Shadowrocket（iOS）

1. 配置 → 添加配置（机场订阅）
2. `[Rule]` 段引用远程规则集：
   ```
   RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_AI.list,AI
   RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_CN_3.list,DIRECT
   ```
3. 策略组在 `[Proxy Group]` 定义，引用国家分组

### Loon（iOS）

1. 配置 → 订阅（机场）
2. 引用远程 RULE-SET：
   ```
   RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_AI.list,AI
   ```
3. Loon 的 `[Remote Rule Set]` / `[Proxy Group]` 结构

### sing-box

sing-box 用 JSON 配置，`route.rules` 引用远程 `rule_set`：

```json
{
  "route": {
    "rule_set": [
      {
        "tag": "ai",
        "type": "remote",
        "format": "source",
        "url": "https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/clash/nexitallyy_Extra_AI.list",
        "download_detour": "direct"
      }
    ],
    "rules": [
      { "rule_set": ["ai"], "outbound": "ai-out" }
    ]
  }
}
```

> 或用 `tools/convert.py` 生成 sing-box 完整配置。

---

## OpenClash 踩坑记录

> 这些坑都真实踩过，花费大量时间排查。务必阅读。

### 坑 1：Ruby 覆写片段必须单行

**现象**：日志显示 `Start Running MyRules Custom Overwrite Scripts...` + `Complete`，但运行配置**没变化**（还是机场原始分组）。

**根因**：OpenClash 的 init.d 用 **grep 按「行」** 提取覆写脚本生成的 Ruby 片段：

```bash
ruby_code=$(grep "yaml_file_path='$yaml_file'" /tmp/yaml_openclash_ruby_parse | sed "s/^threads << Thread.new do //;s/ end$//")
```

**多行参数被截断只剩第一行** → Ruby 语法错误（`unexpected rescue`）→ 覆写静默失效。片段文件里 32 个 provider / 44 个策略组 / 39 条规则的多行内容全被丢弃。

**解决**：所有 `ruby_*` 函数参数**必须单行**。用 heredoc + 压缩换行：

```sh
oneliner() { tr -d '\n' | sed 's/[[:space:]][[:space:]]*/ /g'; }
GROUPS=$(cat << 'EOF' | oneliner
[{"name"=>"Proxies",...},{...}]
EOF
)
ruby_edit "$CONFIG_FILE" "['proxy-groups']" "$GROUPS"
```

**验证**：覆写后检查 `/tmp/yaml_openclash_ruby_parse`，应恰好 3 行（rule-providers / proxy-groups / rules），每行是完整命令。

### 坑 2：rule-provider 下载 EOF 死循环 → 节点全红

**现象**：节点全红；内核日志大量：
```
[Provider] provider_4 pull error: Get "https://raw.githubusercontent.com/...": EOF
```

**根因**：mihomo 启动时下载 rule-provider，若下载流量**命中 `MATCH,✈️Final` 走了代理**，而代理依赖这些规则集 → **EOF 死循环**。raw.githubusercontent.com 在软路由直连也常被墙。

**解决**（两层）：
1. **规则最前面加 mihomo 内部流量直连**：
   ```
   DOMAIN-SUFFIX,jsdelivr.net,🎯Direct
   DOMAIN-SUFFIX,githubusercontent.com,🎯Direct
   DOMAIN-SUFFIX,github.com,🎯Direct
   DOMAIN-SUFFIX,raw.githubusercontent.com,🎯Direct
   DOMAIN-SUFFIX,creamdata.xyz,🎯Direct   # 机场订阅/DoH 域名
   ```
2. **provider url 用 jsdelivr**：
   ```
   url: https://testingcf.jsdelivr.net/gh/xmzzzw/my-rulesets@main/clash/nexitallyy_Extra_AI.list
   ```

> 为什么不用 raw？OpenClash 的 `github_address_mod`（jsdelivr）改写发生在覆写脚本**之前**，会被覆写注入的 raw url 覆盖。所以覆写脚本里**直接写 jsdelivr**。

### 坑 3：OpenClash 快速启动跳过覆写

**现象**：重启后日志 `Step 3: Quick Start Mode, Skip Modify The Config File...`，覆写没跑。

**根因**：OpenClash 有 Quick Start 机制，监控文件时间戳（记录在 `/tmp/openclash.change`），文件未修改则跳过配置生成。

**解决**：改了覆写脚本后，`touch` 脚本 + 删 `/tmp/openclash.change` 再重启。

### 坑 4：proxy-groups 是 Array，ruby_merge_hash 报错

**现象**：`undefined method 'merge!' for an instance of Array`。

**根因**：`ruby_merge_hash` 用 `Hash#merge!`，只适用 Hash（rule-providers / proxy-providers / dns.nameserver-policy）。**proxy-groups 是 Array**。

**解决**：proxy-groups 用 `ruby_edit` 整体赋值；rule-providers 才用 `ruby_merge_hash`。

---

## 广播 IP 判定

**广播 IP**：机场所有节点共享同一出口 IP 池。标注的国家和实际出口可能不一致。

**实例**（CreamData 机场）：
- 标注「美国」「新加坡」「日本」的节点，实际出口**全部是香港** `AS398704 STACKS INC`
- OpenAI/ChatGPT 判定香港为不支持地区 → **403「国家不支持」**

**排查**：
```bash
# 通过代理访问 ipinfo 看真实出口
curl -s -x http://Clash:<密码>@127.0.0.1:7890 'https://ipinfo.io/json' | grep -E '"country"|"org"'
```

**结论**：广播 IP 机场的「地区限制」问题**无法靠覆写解决**（配置再对，出口 IP 不变）。需要：
- 原生 IP 机场 / 真家宽节点
- 或换支持 OpenAI 的地区线路

> OpenAI 支持地区参考：美国 / 日本 / 新加坡 / 韩国 等。香港 / 台湾不支持。

---

## 验证方法

### mihomo 配置校验

```bash
/etc/openclash/clash -t -d /tmp -f <config>.yaml
# 输出 "configuration file ... test is successful" 即通过
```

### 节点延迟（OpenClash API）

```bash
# 先拿 secret（配置里 external-controller 的 secret）
curl -s -H 'Authorization: Bearer <secret>' \
  -X GET 'http://127.0.0.1:9090/group/<urlencoded组名>/delay?url=http://www.gstatic.com/generate_204&timeout=3000'
```

### 流量走向（内核日志）

```bash
grep -iE 'chatgpt|openai' /tmp/openclash.log
# 期望看到：match RuleSet(provider_4) using AI[...]
```

### 出口 IP

```bash
curl -s -x http://<认证>@127.0.0.1:7890 'https://ipinfo.io/json' | grep -E '"country"|"org"'
```
