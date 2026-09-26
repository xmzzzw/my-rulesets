# my-rulesets

一套「**节点来源与规则/策略解耦**」的多平台代理分流方案。机场订阅负责动态节点，自建 VPS 负责稳定固定出口，本仓库负责统一策略、规则与客户端覆写。

> 完整使用说明：[USAGE.md](USAGE.md)  
> 覆写说明：[OVERWRITE.md](OVERWRITE.md)  
> 自建 VPS 唯一规范：[SELF_HOSTED.md](SELF_HOSTED.md)  
> Agent 操作手册：[AGENTS.md](AGENTS.md)

## 核心结构

机场节点继续按国家动态分组：

```text
🇭🇰 香港
├─ 🇭🇰 香港-自动
├─ HK 01
└─ HK 02
```

Self-hosted V2 把 Provider 与机器合并为一个可见策略层：

```text
🏠 自建节点
├─ 🏠 自建节点-自动
├─ 🖥 DMIT · LAX-01
├─ 🖥 DMIT · LAX-02
└─ 🖥 Lisa · LAX-01

🖥 DMIT · LAX-01
├─ 🖥 DMIT · LAX-01-自动
├─ DMIT | LAX-01 | Snell
└─ DMIT | LAX-01 | HY2
```

客户端最终看到的顺序：

```text
AI                    Selector
Proxies               Selector
🎯Direct              Selector
✈️Final               Selector

🏠 自建节点            Selector
🏠 自建节点-自动       URLTest

🖥 DMIT · LAX-01      Selector
🖥 DMIT · LAX-01-自动 URLTest
🖥 DMIT · LAX-02      Selector
🖥 DMIT · LAX-02-自动 URLTest
🖥 Lisa · LAX-01      Selector
🖥 Lisa · LAX-01-自动 URLTest

🇭🇰 香港               Selector
🇭🇰 香港-自动          URLTest
...
```

## 自建节点命名

必须使用：

```text
<Provider> | <Machine-ID> | <Protocol>
```

例如：

```text
DMIT | LAX-01 | Snell
DMIT | LAX-01 | HY2
Lisa | LAX-01 | Snell
Lisa | LAX-01 | HY2
```

符合合同的节点不会进入国家组或 `🌍 其他地区`。

详细规则见 [SELF_HOSTED.md](SELF_HOSTED.md)。

## 当前一等实现

- **FlClash / Clash Verge Rev / Mihomo**：`overwrite_script.js`
- **OpenClash**：`openclash_overwrite.sh`
- **Surge / Clash 完整配置生成**：`tools/convert.py`
- **规则集**：根目录 Surge 格式 + `clash/` Mihomo 格式
- **Agent skills**：`.claude/skills/`

覆写脚本：

```text
https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js
https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/openclash_overwrite.sh
```

## 核心能力

- 动态国家分组：某国家节点数 `>=2` 才建独立组；单节点国家归入 `🌍 其他地区`
- 国家与自建节点严格隔离
- 多 Provider、多机器、多协议 Self-hosted V2
- 顶层自建自动组直接测试真实协议节点，不嵌套自动组
- AI 策略优先提供 `🏠 自建节点`
- 国内 AI API（DeepSeek/智谱/Kimi/通义）继续强制直连
- 32 个规则集
- 公开仓库不保存任何真实凭据

## 仓库结构

```text
my-rulesets/
├── README.md
├── USAGE.md
├── OVERWRITE.md
├── SELF_HOSTED.md
├── AGENTS.md
├── overwrite_script.js
├── openclash_overwrite.sh
├── .claude/skills/
│   ├── my-rulesets-convert/SKILL.md
│   └── my-rulesets-overwrite/SKILL.md
├── tools/
│   ├── convert.py
│   └── README.md
├── tests/
├── *.list
└── clash/*.list
```

## 安全

本仓库是公开仓库。不要提交 VPS 密码、PSK、私钥、订阅 token 或完整生产节点配置。测试必须使用合成地址和假凭据。
