# my-rulesets

一套「**节点用机场订阅、规则用自己维护**」的多平台代理分流方案。

> 📖 **完整使用说明见 [USAGE.md](USAGE.md)**（含各平台详细部署步骤、覆写脚本原理、FAQ）

---

## 项目简介

**解决的问题**：换机场后，分流规则不依赖机场自带的策略，全部由本仓库统一管理。

**核心原则**：
- **节点** → 机场订阅链接（实时更新 + 自动显示流量/到期）
- **规则/策略组** → 本仓库（国家分组 + 自动选择 + AI 分流 + opencode）

**支持平台**：Surge（macOS/iOS）、FlClash（Android）、Clash Verge Rev（Windows）、OpenClash（软路由）。

---

## 快速上手

| 平台 | 客户端 | 操作 |
|------|--------|------|
| 🤖 安卓 | FlClash | 订阅 URL 拉节点 + 覆写脚本注入规则 |
| 🪟 Windows | Clash Verge Rev | 订阅 URL 拉节点 + 脚本 profile |
| 🍎 苹果 | Surge | 引用规则集 |
| 🖥️ 软路由 | OpenClash | 订阅 + 覆写脚本 |

**覆写脚本 URL**：
```
https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js      # FlClash / Clash Verge
https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/openclash_overwrite.sh  # OpenClash
```

---

## 目录结构

```
my-rulesets/
├── README.md              # 本文件（项目总览）
├── USAGE.md               # 完整使用说明（详细部署 + 原理 + FAQ）
├── overwrite_script.js    # FlClash / Clash Verge 覆写脚本
├── openclash_overwrite.sh # OpenClash 覆写脚本
├── *.list                 # Surge 格式规则集（32 个）
├── clash/                 # Clash 兼容规则集（32 个）
└── icons/                 # 策略组图标（22 个）
```

---

## 核心能力

- **6 国家/地区分组**（香港/美国/日本/新加坡/台湾/韩国）+ 🌍 其他地区
- 每个国家分组带 **`-自动` url-test 故障转移**（自动选最快节点）
- **AI 分流**（含 opencode.ai）走 AI 策略组，可手动选美国出口
- **国内模型 API 强制直连**（DeepSeek/智谱/Kimi/通义）
- **32 个规则集**，Surge + Clash 双格式
- 换机场**只需更新订阅**，规则自动适配

---

## 相关链接

- [USAGE.md 完整使用说明](USAGE.md)
- 塔台（tower）：<https://github.com/pengchujin/tower>
- FlClash：<https://github.com/chen08209/FlClash>
- Clash Verge Rev：<https://github.com/clash-verge-rev/clash-verge-rev>
- OpenClash：<https://github.com/vernesong/OpenClash>
- mihomo 文档：<https://wiki.metacubex.one/>
