# my-rulesets

一套「**节点来源与规则/策略解耦**」的多平台代理分流方案。

> 📖 **完整使用说明见 [USAGE.md](USAGE.md)**（含各平台详细部署步骤、覆写脚本原理、FAQ）
>
> 🖊️ **各客户端覆写教程见 [OVERWRITE.md](OVERWRITE.md)**（Clash Verge/FlClash/OpenClash/ClashX/Shadowrocket/Loon/Surge/sing-box 覆写方法 + OpenClash 踩坑记录）
>
> 🛠️ **自建 VPS 规范见 [SELF_HOSTED.md](SELF_HOSTED.md)**（DMIT 自建组、协议选择、AI 固定出口、命名规范）
>
> 🤖 **AI Agent 操作手册见 [AGENTS.md](AGENTS.md)**（Claude/Codex 等 Agent 按需求→动作执行：订阅转换、覆写、部署、验证）

---

## 项目简介

**解决的问题**：换机场后，分流规则不依赖机场自带的策略；同时允许把自建 VPS 作为独立一级节点来源接入现有策略体系。

**核心原则**：
- **机场节点** → 机场订阅链接（实时更新 + 自动显示流量/到期）
- **自建节点** → 本地/私有配置注入（公开仓库不保存任何凭据）
- **规则/策略组** → 本仓库统一维护（国家分组 + 自建分组 + 自动选择 + AI 分流）

**支持平台**：Surge（macOS/iOS）、FlClash（Android）、Clash Verge Rev（Windows）、OpenClash（软路由）、ClashX/ClashX Pro（macOS）、Shadowrocket/Loon（iOS）、sing-box。

---

## 快速上手

| 平台 | 客户端 | 操作 |
|------|--------|------|
| 🤖 安卓 | FlClash | 订阅 URL 拉节点 + 覆写脚本注入规则 |
| 🪟 Windows | Clash Verge Rev | 订阅 URL 拉节点 + 脚本 profile |
| 🍎 苹果 | Surge | 引用规则集 / 生成完整配置 |
| 🖥️ 软路由 | OpenClash | 订阅 + 覆写脚本 |

**覆写脚本 URL**：
```text
https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js      # FlClash / Clash Verge
https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/openclash_overwrite.sh  # OpenClash
```

---

## 自建 VPS：DMIT 分组

当节点名称符合：

```text
DMIT | <Region> | <Protocol>
```

例如：

```text
DMIT | LAX | Snell
DMIT | LAX | HY2
```

系统自动生成：

```text
Proxies
├─ 🛠 DMIT自建
├─ 🇭🇰 香港
├─ 🇺🇸 美国
└─ ...

🛠 DMIT自建
├─ 🛠 DMIT自建-自动
├─ DMIT | LAX | Snell
└─ DMIT | LAX | HY2

🛠 DMIT自建-自动
├─ DMIT | LAX | Snell
└─ DMIT | LAX | HY2
```

规则：
- `DMIT | ...` 不参与国家分组，不会重复进入 `🇺🇸 美国` 或 `🌍 其他地区`。
- `AI` 组在检测到 DMIT 自建节点时，把 `🛠 DMIT自建` 放在第一位。
- 其他应用组继续保留 `Proxies / 🎯Direct / 🛠 DMIT自建 / 国家组` 的手动选择能力。
- `🛠 DMIT自建-自动` 当前与国家自动组一样使用 `url-test`。
- 没有 DMIT 节点时，不创建任何自建组，原有配置行为保持不变。

详细规范见 [SELF_HOSTED.md](SELF_HOSTED.md)。

---

## 目录结构

```text
my-rulesets/
├── README.md              # 本文件（项目总览）
├── USAGE.md               # 完整使用说明（详细部署 + 原理 + FAQ）
├── OVERWRITE.md           # 各客户端覆写教程 + OpenClash 踩坑记录
├── SELF_HOSTED.md         # 自建 VPS / DMIT 策略规范
├── AGENTS.md              # AI Agent 操作手册（Claude/Codex 调用）
├── overwrite_script.js    # FlClash / Clash Verge / Mihomo 覆写脚本
├── openclash_overwrite.sh # OpenClash 覆写脚本
├── tools/                 # 配置转换工具（自动识别协议/国家/格式）
│   ├── convert.py         # 通用转换工具
│   └── README.md          # 工具说明
├── tests/                 # 策略与覆写回归测试
├── *.list                 # Surge 格式规则集（32 个）
├── clash/                 # Clash 兼容规则集（32 个）
└── icons/                 # 策略组图标
```

## 🛠️ 配置转换工具

遇到新机场/新订阅时，用 [tools/convert.py](tools/README.md) 自动生成配置：

```bash
# 自动识别协议/国家/格式，输出 Surge 配置
python3 tools/convert.py --input <订阅URL或文件>

# 输出 Clash YAML
python3 tools/convert.py --input <订阅URL> --format clash

# 保留订阅刷新（[Proxy] 用 #!include）
python3 tools/convert.py --input <订阅URL> --subscription-refresh
```

**工具自动处理**：协议识别（ss/trojan/anytls/snell/hysteria2...）、国家归类（emoji/代码/中文名）、DMIT 自建隔离、单节点国家合并、策略组构建、规则集注入。

---

## 核心能力

- **动态国家分组**：任一国家节点 ≥2 即建独立分组；≤1 节点归入 🌍 其他地区
- 每个国家分组带 **`-自动` url-test** 自动选择
- **自建 VPS 一级分组**：当前支持 `DMIT | ...` → `🛠 DMIT自建 / 🛠 DMIT自建-自动`
- **AI 固定出口优先**：存在 DMIT 自建节点时，AI 策略优先显示 DMIT
- **AI 分流**：含 OpenAI / Claude / Gemini / Grok / OpenCode 等
- **国内模型 API 强制直连**：DeepSeek / 智谱 / Kimi / 通义
- **32 个规则集**，Surge + Clash 双格式
- 换机场**只需更新订阅**，规则自动适配
- 自建 VPS 凭据与公开 GitHub **完全分离**

---

## 相关链接

- [USAGE.md 完整使用说明](USAGE.md)
- [SELF_HOSTED.md 自建 VPS 规范](SELF_HOSTED.md)
- 塔台（tower）：<https://github.com/pengchujin/tower>
- FlClash：<https://github.com/chen08209/FlClash>
- Clash Verge Rev：<https://github.com/clash-verge-rev/clash-verge-rev>
- OpenClash：<https://github.com/vernesong/OpenClash>
- mihomo 文档：<https://wiki.metacubex.one/>
