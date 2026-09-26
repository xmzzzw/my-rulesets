---
name: my-rulesets-convert
description: 把机场订阅/代理配置转换成 my-rulesets 的 Surge/Clash 配置，并处理 Self-hosted V2（🏠 自建节点 → 🖥 Provider · Machine → 协议节点）、动态国家分组和 AI 分流。用户要求换机场、生成 Surge/Clash 配置、加入自建 VPS、多 VPS/多协议分组时使用。
---

# my-rulesets convert skill

## 目标

生成与 `SELF_HOSTED.md` 和三端覆写逻辑完全一致的配置。

唯一真源：

```text
GitHub: xmzzzw/my-rulesets
SELF_HOSTED.md
tools/convert.py
```

## Self-hosted V2 合同

真实自建节点命名：

```text
<Provider> | <Machine-ID> | <Protocol>
```

例：

```text
DMIT | LAX-01 | Snell
DMIT | LAX-01 | HY2
DMIT | LAX-02 | Snell
DMIT | LAX-02 | HY2
Lisa | LAX-01 | Snell
Lisa | LAX-01 | HY2
```

Provider / Machine-ID 只用 ASCII 字母数字 `._-`。

Protocol 支持标签：

```text
SS SSR Trojan AnyTLS VMess VLESS
Hysteria2 Hysteria HY2 TUIC WireGuard
Snell HTTP SOCKS5
```

## 必须生成的前端结构

```text
Proxies
AI
🎯Direct
✈️Final

🏠 自建节点
🏠 自建节点-自动

🖥 DMIT · LAX-01
🖥 DMIT · LAX-01-自动
🖥 DMIT · LAX-02
🖥 DMIT · LAX-02-自动
🖥 Lisa · LAX-01
🖥 Lisa · LAX-01-自动

国家组...
```

### 顶层组

```text
🏠 自建节点 = select
  🏠 自建节点-自动
  🖥 DMIT · LAX-01
  🖥 DMIT · LAX-02
  🖥 Lisa · LAX-01
```

### 顶层自动组

`🏠 自建节点-自动` 必须直接包含所有真实 self-hosted 协议节点。

禁止自动组套自动组。

### 机器组

```text
🖥 DMIT · LAX-01 = select
  🖥 DMIT · LAX-01-自动
  DMIT | LAX-01 | Snell
  DMIT | LAX-01 | HY2
```

机器自动组只包含该机器的真实协议节点。

## 国家分组

1. 先剔除 self-hosted。
2. 再按 emoji / 国家代码 / 中文名识别国家。
3. `>=2` 节点建独立国家组 + `url-test`。
4. `<=1` 并入 `🌍 其他地区`。
5. `🌍 其他地区` 为空时不生成。

## 应用组

存在 self-hosted 时：

```text
Proxies: 🏠 自建节点 在国家组之前
AI: 🏠 自建节点 为第一项
普通应用: Proxies, 🎯Direct, 🏠 自建节点, 国家组...
✈️Final: Proxies, 🎯Direct, 🏠 自建节点, 国家组...
```

## 执行

优先使用：

```bash
python3 ~/my-rulesets/tools/convert.py --input <文件或URL> --format surge
python3 ~/my-rulesets/tools/convert.py --input <文件或URL> --format clash
```

选项：

```text
--output
--subscription-refresh
--no-merge-single
--protocol
```

## 修改 convert.py 时的同步义务

任何 Self-hosted / 国家 / 应用组改动，必须同步：

```text
overwrite_script.js
openclash_overwrite.sh
SELF_HOSTED.md
AGENTS.md
.claude/skills/my-rulesets-overwrite/SKILL.md
tests/
```

不能只改 Python。

## 验证

```bash
python3 -m py_compile tools/convert.py
python3 -m unittest tests/test_self_hosted_policy.py -v
```

再用合成配置生成 Surge 与 Clash，确认策略组顺序。

## 安全

不要把真实 VPS IP、密码、PSK、私钥或订阅 token 提交到公开仓库。测试只用 127.0.0.x / TEST-NET 和假凭据。
