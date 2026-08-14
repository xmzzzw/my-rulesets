# my-rulesets 完整使用说明

> 一套「节点用机场订阅、规则用自己维护」的多平台代理分流方案。
> 本文档详细说明项目的设计思路、各平台部署步骤、覆写脚本原理与维护方法。

---

## 目录

1. [项目概述](#1-项目概述)
2. [核心设计思路](#2-核心设计思路)
3. [目录结构与文件说明](#3-目录结构与文件说明)
4. [快速上手（2 分钟）](#4-快速上手2-分钟)
5. [各平台详细部署](#5-各平台详细部署)
6. [覆写脚本原理](#6-覆写脚本原理)
7. [规则集说明](#7-规则集说明)
8. [策略组结构](#8-策略组结构)
9. [更新与维护](#9-更新与维护)
10. [常见问题（FAQ）](#10-常见问题faq)

---

## 1. 项目概述

本项目解决一个核心问题：**换机场后，分流规则不依赖机场自带的策略**。

传统做法是「机场订阅 → 客户端 → 机场自带规则」，一旦换机场，分流规则也跟着变，且无法自定义。

本项目将「**节点**」与「**规则**」彻底解耦：
- **节点** → 来自机场订阅（实时更新，自动显示流量/到期）
- **规则/策略组** → 来自本仓库（国家分组 + 自动选择 + AI 分流 + opencode 等）

**支持平台**：Surge（macOS/iOS）、FlClash（Android）、Clash Verge Rev（Windows）、OpenClash（软路由）。

**核心能力**：
- 6 个主要国家/地区分组（香港/美国/日本/新加坡/台湾/韩国）+ 🌍 其他地区
- 每个国家分组带 `-自动` url-test 故障转移（自动选最快节点）
- AI 分流（含 opencode.ai）走 AI 策略组（可手动选美国出口）
- 国内 AI 模型 API（DeepSeek/智谱/Kimi/通义）强制直连
- 32 个规则集（Surge + Clash 双格式）

---

## 2. 核心设计思路

### 2.1 原则：节点与规则分离

```
┌─────────────────────┐
│  机场订阅（节点）    │ ← 实时更新，含流量/到期信息
│  机场订阅链接        │
└─────────┬───────────┘
          │ 拉取节点
          ▼
┌─────────────────────┐
│  代理客户端          │
│  (Surge/FlClash/    │
│   ClashVerge/       │
│   OpenClash)        │
└─────────┬───────────┘
          │ 注入规则
          ▼
┌─────────────────────┐
│  本仓库（规则）      │ ← 国家分组 + 自动选择 + AI 分流
│  my-rulesets        │
└─────────────────────┘
```

### 2.2 覆写脚本（核心机制）

由于 FlClash / Clash Verge 新版不支持「导入整个配置文件」作为覆写，改用**脚本覆写**：

- FlClash / Clash Verge 用 **JS 脚本**（`main(config)`），接收订阅解析后的配置对象，改造后返回
- OpenClash 用 **Ruby 脚本**（`ruby_merge_hash` 等函数）增量修改 YAML

**脚本的作用**（无论订阅长什么样）：
1. **保留**订阅的节点（proxies）
2. **重建**策略组（国家分组 + 自动选择 + 应用组 + Final）
3. **注入** rule-providers（引用本仓库 clash/ 规则集）
4. **重写** rules（RULE-SET + GEOIP + MATCH）

---

## 3. 目录结构与文件说明

```
my-rulesets/
├── README.md                    # 项目总览
├── USAGE.md                     # 本文档（详细使用说明）
├── overwrite_script.js          # FlClash / Clash Verge 覆写脚本
├── openclash_overwrite.sh       # OpenClash 覆写脚本
│
├── *.list                       # Surge 格式规则集（32 个）
│   ├── nexitallyy_Extra_AI.list      # AI 平台（OpenAI/Claude/Gemini/Grok/opencode）
│   ├── nexitallyy_Extra_CN_3.list    # 强制直连（含国内模型 API）
│   ├── nexitallyy_Extra_Crypto.list  # 加密货币
│   ├── naiixi_Extra_CN.list          # 国内直连
│   └── ... (ACL4SSR/blackmatrix7/HotKids/naiixi 各源)
│
├── clash/                       # Clash 兼容规则集（32 个，去除 USER-AGENT）
│   └── *.list                   # 与根目录同名，格式兼容 mihomo classical
│
└── icons/                       # 策略组图标（22 个）
    ├── apple.png / netflix.png / youtube.png ...
    └── README.md                # 图标清单
```

### 关键文件

| 文件 | 用途 | 部署位置 |
|------|------|---------|
| `overwrite_script.js` | FlClash/Clash Verge 覆写 | FlClash 脚本模式 / Clash Verge 脚本 profile |
| `openclash_overwrite.sh` | OpenClash 覆写 | `/etc/openclash/custom/openclash_custom_overwrite.sh` |
| `*.list`（根目录） | Surge 规则集 | Surge 引用 |
| `clash/*.list` | Clash 规则集 | 覆写脚本 rule-providers 引用 |
| `icons/*.png` | 策略组图标 | 各客户端 icon-url |

---

## 4. 快速上手（2 分钟）

### 安卓（FlClash）

1. **添加订阅**：粘贴机场 Clash 订阅链接
2. **配置覆写脚本**：
   - 进入订阅 → 「覆写」→ 选「脚本」模式
   - 从 URL 导入：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js`
3. **完成**：节点自动拉取 + 规则自动注入

### Windows（Clash Verge Rev）

1. **添加订阅**：机场订阅链接
2. **配置脚本**：
   - 订阅右键 → 「脚本」→ 新建脚本
   - 粘贴脚本内容（可从 URL 获取）
3. **完成**

### 苹果生态（Surge）

在配置 `[Rule]` 段引用规则集：

```ini
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_AI.list,AI,update-interval=86400
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_CN_3.list,🎯Direct,update-interval=86400
```

### 软路由（OpenClash）

1. **配置订阅**：机场订阅链接
2. **放置覆写脚本**：`openclash_overwrite.sh` → `/etc/openclash/custom/`
3. **重启 OpenClash** 生效

---

## 5. 各平台详细部署

### 5.1 安卓 — FlClash

#### 前置条件
- 已安装 FlClash（Android）
- 机场订阅链接（Clash 格式）

#### 步骤

**① 添加订阅**
1. 打开 FlClash → 底部「配置」
2. 右上角「+」→ 粘贴机场订阅链接
3. 等待拉取完成（节点数 + 流量显示自动出现）

> 流量进度条 / 已用 / 总流量 / 到期时间的显示，依赖订阅响应头 `subscription-userinfo`。若机场支持则自动显示。

**② 配置覆写脚本**
1. 进入刚添加的订阅
2. 找到「覆写」（或「Overwrite」）
3. 选择「脚本」模式
4. 打开脚本编辑器 → 右上角菜单 → 「外部获取」→「从 URL 导入」
5. 粘贴：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js`
6. 保存

**③ 验证**
- 代理页应显示：`Proxies` 顶层组 → 6 个国家分组 + 🌍 其他地区
- 每个国家分组可展开看到该国节点
- AI 组可选择（含全部国家分组）
- 流量进度条正常显示

#### 更新流量
1. 打开机场管理页（触发订阅窗口期）
2. FlClash → 该订阅 → 「更新配置」
3. 流量/到期数据刷新

---

### 5.2 Windows — Clash Verge Rev

#### 前置条件
- 已安装 Clash Verge Rev
- 机场订阅链接

#### 步骤

**① 添加订阅**
1. 打开 Clash Verge → 订阅页
2. 「添加」→ 粘贴机场订阅链接

**② 配置脚本**
1. 订阅项右键 → 「脚本」→ 新建脚本
2. 粘贴脚本内容（或从 URL 获取：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js`）
3. 保存并启用

**③ 验证**
- 代理页显示国家分组 + 自动选择
- AI 分流生效

> 注意：Clash Verge Rev 新版已移除 prepend/append 增强文件，改用「编辑规则/编辑代理组」界面 + 脚本 profile。本项目的脚本 profile 方式兼容。

---

### 5.3 苹果生态 — Surge（macOS / iOS）

#### 方式一：直接引用规则集（推荐）

在 Surge 配置 `[Rule]` 段引用本仓库规则集：

```ini
[Rule]
# AI 分流（含 opencode.ai，可手动选美国出口）
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_AI.list,AI,update-interval=86400
# 强制直连（含国内模型 API）
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_CN_3.list,🎯Direct,update-interval=86400
# 其余规则集按需引用
```

#### 方式二：使用完整配置模板

若需要完整的「国家分组 + 自动选择」策略组结构，可参考本项目此前生成的 Surge 模板（在本地 `~/Desktop/MyRules_Flower_ss_Surge.conf`），或让 Claude Code 基于本仓库重新生成。

---

### 5.4 软路由 — OpenClash

#### 前置条件
- OpenWrt + OpenClash
- 机场订阅链接

#### 步骤

**① 配置订阅**
1. OpenClash 界面 → 配置订阅
2. 添加机场订阅链接

**② 放置覆写脚本**
1. SSH 登录路由，或通过 OpenClash 文件管理
2. 上传 `openclash_overwrite.sh` 到 `/etc/openclash/custom/openclash_custom_overwrite.sh`
3. 赋予执行权限：`chmod +x /etc/openclash/custom/openclash_custom_overwrite.sh`
4. 重启 OpenClash

**③ 验证**
- 日志出现 `MyRules Custom Overwrite Complete`
- 代理组出现国家分组 + 自动选择
- 规则集正常加载（`/etc/openclash/rule_provider/` 下应有下载的规则集）

#### 备选：界面配置
OpenClash → 覆写设置 → 规则设置：
- 开启「Custom Clash Rules」
- 在自定义规则框粘贴 `RULE-SET` 引用（参考脚本内的规则列表）

---

## 6. 覆写脚本原理

### 6.1 overwrite_script.js（FlClash / Clash Verge）

```javascript
function main(config) {
  // 1. 保留订阅节点
  const nodes = config.proxies || [];

  // 2. 按国家归类节点（从节点名识别香港/美国/日本/新加坡/台湾/韩国/其他）

  // 3. 重建策略组：
  //    - Proxies（顶层，引用国家分组）
  //    - 各国分组（select + 各 -自动 url-test）
  //    - 应用组（Netflix/AI/YouTube...引用国家分组）
  //    - 🎯Direct / ✈️Final

  // 4. 注入 rule-providers（引用 clash/ 规则集）
  // 5. 重写 rules（RULE-SET + GEOIP + MATCH）

  return config;
}
```

**规格**（与 FlClash_Flower 模板一致）：
- proxies：保留订阅节点（90 个）
- proxy-groups：36 个（6 国家分组 + 各 -自动 + 🌍其他地区 + 19 应用组 + Direct + Final）
- rule-providers：32 个
- rules：34 条

### 6.2 openclash_overwrite.sh（OpenClash）

OpenClash 使用 Ruby 脚本操作 YAML：

```sh
# 注入 rule-providers
ruby_merge_hash "$CONFIG_FILE" "['rule-providers']" "'opencode'=>{...}"

# 注入 include-all 国家分组（自动归类，换机场不用改）
ruby_merge_hash "$CONFIG_FILE" "['proxy-groups']" "'🇭🇰 香港'=>{'type'=>'select','include-all'=>true,'filter'=>'(?i)(香港|HK|HongKong)'}"

# 写自定义规则
cat > /etc/openclash/custom/openclash_custom_rules.list << 'EOF'
RULE-SET,opencode,AI
EOF
```

**关键差异**：
- FlClash / Clash Verge：JS 脚本**整个重写**配置
- OpenClash：Ruby 脚本**增量修改**配置（保留订阅原有内容）

---

## 7. 规则集说明

### 7.1 规则集来源

| 来源 | 内容 | 许可 |
|------|------|------|
| nexitallyy/ProxyRules | AI/CN/Crypto/Proxies | 原作者所有 |
| blackmatrix7/ios_rule_script | Google/Netflix/Steam 等 | 原作者所有 |
| ACL4SSR/ACL4SSR | Apple/Microsoft/Telegram 等 | 原作者所有 |
| HotKids/Rules | Bilibili/HBO/Netflix | 原作者所有 |
| naiixi.com | CN/DisneyPlus | 原作者所有 |

### 7.2 私有化改造点

1. **`nexitallyy_Extra_AI.list`**：新增 `opencode.ai` / `opencode.com`（OpenCode 网关）
2. **`nexitallyy_Extra_CN_3.list`**：新增国内模型 API 域名：
   - `deepseek.com`（DeepSeek）
   - `bigmodel.cn`（智谱 GLM）
   - `moonshot.cn`（月之暗面 Kimi）
   - `dashscope.aliyuncs.com`（阿里通义千问）

### 7.3 Surge 与 Clash 格式差异

- **根目录 `*.list`**：Surge 格式（可能含 `PROCESS-NAME`、`USER-AGENT`）
- **`clash/*.list`**：Clash 兼容格式（去除 `USER-AGENT`，mihomo classical 可解析）

> 覆写脚本统一引用 `clash/` 目录，保证 mihomo 兼容。

---

## 8. 策略组结构

覆写脚本生成的策略组结构：

```
🚀 顶层：Proxies (select)
├── 🇭🇰 香港 (select) → 🇭🇰 香港-自动 (url-test, 故障转移)
├── 🇺🇸 美国 (select) → 🇺🇸 美国-自动 (url-test)
├── 🇯🇵 日本 (select) → 🇯🇵 日本-自动 (url-test)
├── 🇸🇬 新加坡 (select) → 🇸🇬 新加坡-自动 (url-test)
├── 🇨🇳 台湾 (select) → 🇨🇳 台湾-自动 (url-test)
├── 🌍 其他地区 (select) → 🌍 其他地区-自动 (url-test)

应用策略组（引用国家分组）：
Netflix / HBO / DisneyPlus / YouTube / Bahamut / Bilibili / MyTVSuper /
AI / Telegram / Crypto / Steam / Epic / Xbox / PlayStation / Microsoft /
Scholar / Apple / Google / Tiktok

兜底：
🎯Direct (直连) / ✈️Final (最终)
```

**AI 策略组**（select，可手动选任意节点，不固定美国出口）：
```
AI = Proxies, 🎯Direct, 🇭🇰 香港, 🇺🇸 美国, 🇯🇵 日本, 🇸🇬 新加坡, 🇨🇳 台湾, 🌍 其他地区
```

---

## 9. 更新与维护

### 9.1 更新规则集

直接在 GitHub 修改对应 `.list` 文件即可：
- 客户端按 `update-interval`（默认 86400 秒 = 1 天）自动更新
- 覆写脚本引用的 `clash/` 规则集同样生效

### 9.2 换机场

**无需改规则**，只需更新订阅：
- FlClash / Clash Verge：更新订阅 URL
- OpenClash：更新订阅配置
- 规则/策略组自动适配新节点（国家分组用 include-all 或节点名归类）

### 9.3 更新流量/到期显示

因机场有订阅时间窗口限制：
1. 打开机场管理页（触发窗口期）
2. 客户端「更新配置」
3. 流量/到期刷新

---

## 10. 常见问题（FAQ）

### Q1：FlClash 导入后看不到代理栏？
- 确认覆写脚本已配置（脚本模式）
- 检查订阅 URL 是否正常拉取节点
- 若用静态文件，需改用订阅 URL

### Q2：流量/到期不显示？
- FlClash 只从订阅响应头 `subscription-userinfo` 读取
- 需用订阅 URL（非静态文件）导入
- 机场须返回该响应头

### Q3：国家分组是空的？
- 覆写脚本按节点名识别国家（香港/美国等关键字）
- 若机场节点命名不含国家关键字，会归入 🌍 其他地区
- OpenClash 的 include-all 用 filter 匹配，可调整 filter 正则

### Q4：opencode.ai 不生效？
- 确认 AI 规则集已更新（含 opencode.ai）
- 确认 AI 策略组选择了正确的节点（美国出口）

### Q5：国内模型 API 走了代理？
- 确认 CN_3 规则集已更新（含 deepseek/bigmodel/moonshot/dashscope）
- 确认 CN 直连规则在 AI 规则之前（优先级）

### Q6：OpenClash 脚本没生效？
- 确认脚本权限：`chmod +x`
- 确认放置路径：`/etc/openclash/custom/openclash_custom_overwrite.sh`
- 查看日志：`/tmp/openclash.log` 应有 `MyRules Custom Overwrite Complete`

---

## 相关链接

- 仓库主页：<https://github.com/xmzzzw/my-rulesets>
- FlClash：<https://github.com/chen08209/FlClash>
- Clash Verge Rev：<https://github.com/clash-verge-rev/clash-verge-rev>
- OpenClash：<https://github.com/vernesong/OpenClash>
- 塔台（tower）：<https://github.com/pengchujin/tower>
- mihomo 文档：<https://wiki.metacubex.one/>
