# Self-hosted V2 / 自建 VPS 节点规范

本文件是 `xmzzzw/my-rulesets` 的 **Self-hosted V2 唯一规范**。目标不是把内部数据模型完整暴露给客户端，而是把前端可见层级压平到最多两层策略组，保证 Surge / Mihomo 系客户端的可用性和可读性。

## 1. 前端必须看到的结构

存在多个自建机器时，策略组顺序固定为：

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

这里**不生成 Provider 独立策略层**。`Provider + Machine-ID` 被压平为一个机器策略组，例如 `🖥 DMIT · LAX-01`。

## 2. 节点命名合同

真实自建代理节点必须命名为：

```text
<Provider> | <Machine-ID> | <Protocol>
```

示例：

```text
DMIT | LAX-01 | Snell
DMIT | LAX-01 | HY2
DMIT | LAX-02 | Snell
DMIT | LAX-02 | HY2
Lisa | LAX-01 | Snell
Lisa | LAX-01 | HY2
```

约束：

- `Provider`：ASCII 字母/数字/`.`/`_`/`-`，例如 `DMIT`、`Lisa`、`BWH`。
- `Machine-ID`：ASCII 字母/数字/`.`/`_`/`-`，例如 `LAX-01`、`SJC-02`。
- `Protocol`：支持标签之一：`SS / SSR / Trojan / AnyTLS / VMess / VLESS / Hysteria2 / Hysteria / HY2 / TUIC / WireGuard / Snell / HTTP / SOCKS5`，大小写不敏感。
- 节点名必须正好由 3 个 `|` 分段组成。
- 机场节点不满足这个合同，因此继续进入国家识别。

这个合同的目的，是避免把普通机场的 `US | 美国 01`、`HK | 香港 01` 误识别成自建节点。

## 3. 分组规则

### 3.1 顶层自建组

```text
🏠 自建节点
├─ 🏠 自建节点-自动
├─ 🖥 DMIT · LAX-01
├─ 🖥 DMIT · LAX-02
└─ 🖥 Lisa · LAX-01
```

`🏠 自建节点` 是 `select`。

### 3.2 顶层自动组

```text
🏠 自建节点-自动
├─ DMIT | LAX-01 | Snell
├─ DMIT | LAX-01 | HY2
├─ DMIT | LAX-02 | Snell
├─ DMIT | LAX-02 | HY2
├─ Lisa | LAX-01 | Snell
└─ Lisa | LAX-01 | HY2
```

`🏠 自建节点-自动` 是 `url-test`，**直接引用所有真实协议节点**。

不要写成：

```text
🏠 自建节点-自动
├─ 🖥 DMIT · LAX-01-自动
└─ 🖥 Lisa · LAX-01-自动
```

也就是说：**自动组不嵌套自动组**。这样对 Surge / Mihomo / 其他客户端更稳定。

### 3.3 单台机器组

```text
🖥 DMIT · LAX-01
├─ 🖥 DMIT · LAX-01-自动
├─ DMIT | LAX-01 | Snell
└─ DMIT | LAX-01 | HY2
```

机器组是 `select`。

机器自动组：

```text
🖥 DMIT · LAX-01-自动
├─ DMIT | LAX-01 | Snell
└─ DMIT | LAX-01 | HY2
```

是 `url-test`，也直接引用真实协议节点。

## 4. 应用策略

存在自建节点时：

```text
Proxies
├─ 🏠 自建节点
├─ 国家组...
```

`AI` 优先把自建节点放第一项：

```text
AI
├─ 🏠 自建节点
├─ Proxies
├─ 🎯Direct
├─ 国家组...
```

其他应用策略：

```text
Google / Telegram / Crypto / ...
├─ Proxies
├─ 🎯Direct
├─ 🏠 自建节点
├─ 国家组...
```

`✈️Final` 同样显式提供 `🏠 自建节点`。

## 5. 国家分组隔离

一旦节点符合 Self-hosted V2 命名合同：

- 不进入 `🇺🇸 美国`、`🇭🇰 香港` 等国家统计；
- 不进入 `🌍 其他地区`；
- 只进入对应机器组与 `🏠 自建节点` 体系。

即使 `Machine-ID=LAX-01`，也不会因为地理位置在美国而重复进入 `🇺🇸 美国`。

## 6. 无自建节点时

如果配置中没有任何符合合同的自建节点：

- 不生成 `🏠 自建节点`；
- 不生成机器组；
- `Proxies / AI / Final / 国家分组` 保持原来的机场-only 行为。

## 7. 当前实现覆盖

本规范必须同步到以下所有实现：

- `overwrite_script.js`：FlClash / Clash Verge Rev / Mihomo。
- `openclash_overwrite.sh`：OpenClash。
- `tools/convert.py`：Surge / Clash 配置生成。
- `.claude/skills/my-rulesets-convert/SKILL.md`。
- `.claude/skills/my-rulesets-overwrite/SKILL.md`。
- `AGENTS.md`。
- `README.md / USAGE.md / OVERWRITE.md / tools/README.md`。
- `tests/` 回归测试。

任何一端修改 Self-hosted 规则，都必须同时修改另外两端和 skills，并通过三端一致性测试。

## 8. 安全

仓库是公开的。禁止提交：

- VPS IP（如果用户希望保密）；
- 端口/用户名/密码；
- Snell PSK；
- Hysteria2 密码；
- ShadowTLS 密钥；
- WireGuard 私钥；
- 机场订阅 token；
- 任何完整真实生产节点配置。

公开仓库只保存**命名合同、分组逻辑和无秘密的合成测试 fixture**。

## 9. AI 固定出口建议

`🏠 自建节点-自动` 可以跨机器切换，因此公网出口 IP 可能变化。

对于 ChatGPT / Claude / Codex 等希望稳定出口身份的业务，推荐手动选择：

```text
AI
→ 🏠 自建节点
→ 🖥 DMIT · LAX-01
→ 🖥 DMIT · LAX-01-自动
```

这样 Snell / HY2 可以自动切换，但仍然使用同一台 VPS 的公网 IP。
