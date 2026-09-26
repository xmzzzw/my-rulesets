# AGENTS.md — my-rulesets Agent 操作手册

> 本文件给 Codex / Claude Code / Cursor / 其他自动化 Agent 使用。  
> GitHub `xmzzzw/my-rulesets` 是策略规格的 source of truth。

## 0. 必须遵守的全局规则

1. **三端实现必须一致**
   - `overwrite_script.js`
   - `openclash_overwrite.sh`
   - `tools/convert.py`

2. **skills 必须同步**
   - `.claude/skills/my-rulesets-convert/SKILL.md`
   - `.claude/skills/my-rulesets-overwrite/SKILL.md`

3. **文档必须同步**
   - `README.md`
   - `SELF_HOSTED.md`
   - `USAGE.md`
   - `OVERWRITE.md`
   - `tools/README.md`

4. **修改后必须回归测试**
   - `node --check overwrite_script.js`
   - `node tests/test_self_hosted_overwrite.js`
   - `python3 -m py_compile tools/convert.py`
   - `python3 -m unittest tests/test_self_hosted_policy.py -v`
   - `sh -n openclash_overwrite.sh`
   - `sh tests/test_openclash_self_hosted_contract.sh`

5. **公开仓库禁止秘密**
   - 机场订阅 URL/token
   - VPS 密码、PSK、私钥
   - OpenClash API secret
   - 完整生产节点配置

如果只有 GitHub 连接权限，没有用户设备 SSH 权限，只能完成 GitHub 变更与离线验证；不得声称已同步本地 `~/my-rulesets/`、R2S、Windows 或手机。

---

# 1. Self-hosted V2 唯一合同

唯一规范文件：`SELF_HOSTED.md`。

## 1.1 节点命名

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

- Provider / Machine-ID：ASCII 字母数字 `._-`
- Protocol：SS/SSR/Trojan/AnyTLS/VMess/VLESS/Hysteria2/Hysteria/HY2/TUIC/WireGuard/Snell/HTTP/SOCKS5
- 必须恰好 3 段 `|`
- 一旦识别为 self-hosted，禁止进入国家组或 `🌍 其他地区`

## 1.2 前端可见结构

必须生成：

```text
🏠 自建节点            select
🏠 自建节点-自动       url-test

🖥 DMIT · LAX-01      select
🖥 DMIT · LAX-01-自动 url-test
🖥 DMIT · LAX-02      select
🖥 DMIT · LAX-02-自动 url-test
🖥 Lisa · LAX-01      select
🖥 Lisa · LAX-01-自动 url-test
```

**不要生成 Provider 独立层。**  
即不要生成 `DMIT → LAX-01 → 协议` 三层 UI；显示层压平成 `DMIT · LAX-01`。

## 1.3 自动组规则

顶层：

```text
🏠 自建节点-自动
→ 直接包含所有真实 self-hosted 协议节点
```

机器层：

```text
🖥 DMIT · LAX-01-自动
→ 直接包含该机器的真实协议节点
```

禁止：

```text
url-test → url-test → real proxy
```

自动组不嵌套自动组。

## 1.4 应用组

存在 self-hosted 时：

```text
Proxies
→ 第一项：🏠 自建节点
```

```text
AI
→ 第一项：🏠 自建节点
→ Proxies
→ 🎯Direct
→ 国家组
```

普通应用组：

```text
Proxies
🎯Direct
🏠 自建节点
国家组...
```

`✈️Final` 同样显式提供 `🏠 自建节点`。

---

# 2. 仓库主要文件

```text
overwrite_script.js
  FlClash / Clash Verge Rev / Mihomo 动态覆写

openclash_overwrite.sh
  OpenClash 自定义覆写

tools/convert.py
  Surge / Clash 完整配置生成

SELF_HOSTED.md
  Self-hosted V2 唯一规范

.claude/skills/
  Agent skill 镜像

tests/
  合成 fixture 回归测试
```

---

# 3. 国家分组固定规则

- 从节点名称识别 emoji / 国家代码 / 中文名。
- 某国家节点数 `>=2`：生成 `select + url-test`。
- 某国家节点数 `<=1`：并入 `🌍 其他地区`。
- `🌍 其他地区` 只在非空时生成。
- self-hosted 节点在国家统计前剔除。
- 伪节点（流量/到期/面板等）不进入任何策略组。

策略组顺序：

```text
Proxies
→ 20 个应用组（AI 第一）
→ 🎯Direct
→ ✈️Final
→ Self-hosted V2 组
→ 国家组
→ 🌍 其他地区
```

---

# 4. OpenClash 特殊约束

## 4.1 ruby_* 参数必须单行

OpenClash 的脚本处理链会按行抽取 Ruby 片段。多行参数会被截断，导致覆写看似执行但实际未生效。

因此：

```sh
oneliner() {
  tr -d '\n' | sed 's/[[:space:]][[:space:]]*/ /g'
}
```

最终传给 `ruby_edit` / `ruby_merge_hash` 的字符串必须是单行。

## 4.2 proxy-groups 整体替换

`proxy-groups` 是 Array，使用：

```sh
ruby_edit "$CONFIG_FILE" "['proxy-groups']" "$GROUPS"
```

不要对 Array 使用 `ruby_merge_hash`。

## 4.3 rule-provider 下载必须防 EOF 循环

规则最前保留：

```text
DOMAIN-SUFFIX,jsdelivr.net,🎯Direct
DOMAIN-SUFFIX,githubusercontent.com,🎯Direct
DOMAIN-SUFFIX,github.com,🎯Direct
DOMAIN-SUFFIX,raw.githubusercontent.com,🎯Direct
DOMAIN-SUFFIX,creamdata.xyz,🎯Direct
```

OpenClash provider URL 优先使用 jsDelivr。

## 4.4 Unicode 节点名

节点名必须用 Ruby YAML parser 提取，不能用 awk 直接解析 YAML 中的 `\U...` 转义。

---

# 5. 修改工作流

## 5.1 需求涉及策略结构

必须检查并修改：

```text
overwrite_script.js
openclash_overwrite.sh
tools/convert.py
SELF_HOSTED.md
README.md
AGENTS.md
.claude/skills/my-rulesets-convert/SKILL.md
.claude/skills/my-rulesets-overwrite/SKILL.md
tests/
```

根据影响范围同步 `USAGE.md / OVERWRITE.md / tools/README.md`。

## 5.2 验证 fixture

Self-hosted fixture 至少覆盖：

```text
DMIT | LAX-01 | Snell
DMIT | LAX-01 | HY2
DMIT | LAX-02 | Snell
DMIT | LAX-02 | HY2
Lisa | LAX-01 | Snell
Lisa | LAX-01 | HY2
```

以及：

- 香港 >=2
- 美国 >=2
- 某单节点国家
- 无 self-hosted 场景

必须验证：

- `Proxies` 第一项为 `🏠 自建节点`
- `AI` 第一项为 `🏠 自建节点`
- 顶层 self auto 直接引用真实节点
- 每台机器组结构正确
- self-hosted 不进入美国组/其他地区
- 无 self-hosted 时不生成空组

---

# 6. 部署

GitHub 修改完成不等于真实客户端已经更新。

## FlClash

外部获取脚本通常是快照。仓库脚本更新后需要重新获取/导入。

## Clash Verge Rev

脚本 profile 通常是本地文件，需要同步更新本地脚本。

## OpenClash

真实部署前：

```sh
cp /etc/openclash/custom/openclash_custom_overwrite.sh \
  /etc/openclash/custom/openclash_custom_overwrite.sh.bak-$(date +%Y%m%d-%H%M%S)
```

再同步、触发完整覆写流程、重启并验证运行配置。

没有 SSH 权限时，不执行也不声称已执行。

---

# 7. 兼容性原则

Canonical 数据模型可以知道 Provider/Machine/Protocol 三个字段，但客户端前端只暴露：

```text
🏠 自建节点
→ 🖥 Provider · Machine
→ real protocol proxy
```

这是“内部完整、前端压平”的固定原则。

以后新增 Provider（如 BWH/Vultr/AWS）不需要改代码中的 provider 白名单；只要节点符合命名合同即可自动归类。
