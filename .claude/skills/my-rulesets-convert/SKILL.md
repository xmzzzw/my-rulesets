---
name: my-rulesets-convert
description: 机场订阅 → 自定义代理配置 的转换 skill。自动识别协议（ss/trojan/anytls/vmess/vless等）、国家（emoji/代码/中文名）、配置格式（Surge/Clash），生成统一规格的国家分组+自动选择+AI分流配置。当用户提供机场订阅链接、机场配置文件、或要求"把XX机场转换成我的配置""生成XX协议配置""换机场了帮我弄"时使用。
---

# my-rulesets 订阅转换

把机场订阅（链接或配置文件）转换成「my-rulesets 规格」的自定义代理配置。

## 何时使用

- 用户提供机场订阅链接 / 配置文件，要求转换
- "换机场了，帮我生成配置"
- "把 XX 转成 ss/trojan/anytls 协议"
- "生成 Surge / FlClash / Clash Verge 配置"
- 用户给固定机场模板，要求生成订阅

## 核心原则

**灵活、不死板、自动匹配**：
1. 协议自动识别（ss/trojan/anytls/vmess/vless/hysteria2...）
2. 国家自动识别（emoji 🇭🇰 / 国家代码 HK / 中文名 香港）
3. 单节点国家自动合并到 🌍 其他地区（≤1 节点不建分组）
4. 无法拉取订阅时，用给定模板生成
5. 生成后必须验证（surge-cli / mihomo）

## 执行步骤

### 1. 获取订阅内容

- **有订阅链接**：抓取。注意机场常见限制：
  - **IP 限制**：本机 Surge 代理出口 IP 常被机场限制，用 `--noproxy '*'` 直连
  - **时间窗口**：部分机场需打开后台开启订阅窗口（10分钟有效）
  - **User-Agent**：`ClashForWindows/0.20.39` 或 `Surge`
  ```bash
  curl -sL --noproxy '*' --max-time 30 -A "ClashForWindows/0.20.39" "<订阅URL>" -o /tmp/sub.conf
  ```
- **有配置文件**：直接读取
- **无法拉取**：用给定模板生成，不报错

### 2. 用转换工具生成（优先）

```bash
python3 ~/my-rulesets/tools/convert.py --input <文件或URL> [选项]
```

选项：
- `--format surge|clash`：输出格式（默认 auto 自动检测）
- `--output <路径>`：输出文件
- `--subscription-refresh`：Surge 输出时 [Proxy] 用 `#!include` 保留订阅刷新
- `--no-merge-single`：不合并单节点国家

### 3. 手动转换（工具不适用时）

按以下规格手动构建：

**策略组顺序**（用户明确要求）：
```
Proxies → 应用组(AI/Netflix/...) → 🎯Direct → ✈️Final → 国家分组 + 自动选择
```
国家分组和自动选择**必须放在 Final 后面**。

**国家分组结构**：
- 每个国家：`🇭🇰 香港 = select, 🇭🇰 香港-自动, 节点1, 节点2...`
- 自动选择：`🇭🇰 香港-自动 = url-test, 节点..., url=http://www.gstatic.com/generate_204, interval=300, tolerance=50`
- 单节点国家（≤1）：不建分组，归入 `🌍 其他地区`

**规则集**（引用 my-rulesets GitHub）：
```
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/<规则集>,<策略>,update-interval=86400
```
规则集清单见 `~/my-rulesets/clash/` 目录。

**协议节点格式**：
- ss: `节点名 = ss, 服务器, 端口, encrypt-method=..., password=..., obfs=http, obfs-host=...`
- trojan: `节点名 = trojan, 服务器, 端口, password=..., sni=..., skip-cert-verify=true`
- anytls: `节点名 = anytls, 服务器, 端口, password=..., sni=..., skip-cert-verify=true`

### 4. 验证生成的配置

**Surge**：
```bash
SC="/Applications/Surge.app/Contents/Applications/surge-cli"
echo "quit" | "$SC" profile check <配置名>  # 应返回 Valid
```
（先复制到 `~/Library/Application Support/Surge/Profiles/`）

**Clash**：
```bash
M="/Applications/Clash Verge.app/Contents/MacOS/verge-mihomo"
"$M" -t -f <config.yaml>  # 应返回 test is successful
```

**通用检查**：
- 无段粘连（策略组行和 [Rule] 段头不粘）
- 节点定义 = 分组引用完全一致（无"引用了未定义节点"）
- [Proxy] 段保留 DIRECT
- 命名规范：`MyRules_<机场>_<协议>_Surge.conf` 或 `FlClash_<机场>_<协议>.yaml`

### 5. 部署到目标平台

| 平台 | 客户端 | 交付 |
|------|--------|------|
| Mac/iOS | Surge | `MyRules_<机场>_<协议>_Surge.conf` → Surge Profiles |
| 安卓 | FlClash | Clash YAML + 覆写脚本 |
| Windows | Clash Verge | Clash YAML + 脚本 profile |
| 软路由 | OpenClash | `openclash_overwrite.sh` |

## 流量/到期显示

- **机场提供 `subscription-userinfo` 头**（如 Flower）→ 用订阅 URL 导入自动显示
- **机场不提供**（如 CreamData）→ 不加流量显示（用户确认）
- 不要凭空捏造流量数据

## 覆写脚本（FlClash/Clash Verge 用）

订阅拉节点 + 覆写注入规则时，用 `~/my-rulesets/overwrite_script.js`：
```
https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js
```
OpenClash 用 `~/my-rulesets/openclash_overwrite.sh`。

## 常见坑

1. **IP 限制**：机场订阅必须 `--noproxy '*'` 直连（本机代理 IP 被限制）
2. **订阅窗口**：部分机场需打开后台开启（10分钟），期间抓取
3. **#!include 语法**：Surge [Proxy] 段 `#!include URL` 保留订阅刷新，用 `chr(10)` 拼换行避免转义问题
4. **PROCESS-NAME**：Surge 规则集里的 PROCESS-NAME 在 Clash classical 不支持 → 用 `clash/` 目录的兼容版本
5. **单节点国家**：≤1 节点合并到其他地区
6. **策略组顺序**：国家分组在 Final 后面（用户明确要求）
