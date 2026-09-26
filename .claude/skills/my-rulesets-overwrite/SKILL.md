---
name: my-rulesets-overwrite
description: 维护 my-rulesets 的 FlClash/Clash Verge/Mihomo/OpenClash 覆写逻辑，包括 Self-hosted V2（🏠 自建节点、🖥 Provider · Machine）、动态国家分组、AI 分流、OpenClash 单行 Ruby 片段与 rule-provider EOF 排障。用户要求修改覆写、加入 VPS、多机器分组或排查 OpenClash 时使用。
---

# my-rulesets overwrite skill

## 唯一策略合同

先读：

```text
SELF_HOSTED.md
AGENTS.md
```

覆写实现：

```text
overwrite_script.js
openclash_overwrite.sh
```

这两个文件必须与 `tools/convert.py` 行为一致。

## Self-hosted V2

节点名：

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

不要再使用旧的：

```text
🛠 DMIT自建
🛠 DMIT自建-自动
```

作为硬编码数据模型。

新前端结构：

```text
🏠 自建节点            Selector
🏠 自建节点-自动       URLTest

🖥 DMIT · LAX-01      Selector
🖥 DMIT · LAX-01-自动 URLTest
🖥 DMIT · LAX-02      Selector
🖥 DMIT · LAX-02-自动 URLTest
🖥 Lisa · LAX-01      Selector
🖥 Lisa · LAX-01-自动 URLTest
```

Provider 不单独成为一层策略组。

## 自动组硬规则

顶层自动：

```text
🏠 自建节点-自动
→ 所有真实 self-hosted proxy
```

机器自动：

```text
🖥 Provider · Machine-自动
→ 该机器真实 proxy
```

禁止：

```text
url-test → url-test
```

这是跨客户端兼容的重要约束。

## overwrite_script.js

入口：

```javascript
function main(config, profileName) { ... }
```

流程：

1. 保留 `config.proxies`
2. 过滤伪节点
3. 用 Self-hosted 命名合同识别自建节点
4. self-hosted 从国家识别中剔除
5. 构建国家组
6. 构建应用组
7. Final 后插入 Self-hosted V2 组
8. 再插入国家组
9. 注入 32 rule-providers
10. 重写 rules

FlClash 与 Clash Verge 都使用同一 JS 逻辑。

## OpenClash

脚本：

```text
openclash_overwrite.sh
```

### 关键坑 1：Ruby 参数必须单行

使用：

```sh
oneliner() {
  tr -d '\n' | sed 's/[[:space:]][[:space:]]*/ /g'
}
```

最终传入 `ruby_edit` / `ruby_merge_hash` 的内容不能含换行。

### 关键坑 2：proxy-groups 是 Array

用：

```sh
ruby_edit "$CONFIG_FILE" "['proxy-groups']" "$GROUPS"
```

不要用 `ruby_merge_hash` 合并 Array。

### 关键坑 3：provider EOF

OpenClash rule-provider 使用 jsDelivr，并把以下域名直连规则放在 MATCH 前：

```text
jsdelivr.net
githubusercontent.com
github.com
raw.githubusercontent.com
creamdata.xyz
```

### 关键坑 4：emoji YAML

必须让 Ruby `YAML.load_file` 提取节点名。不要用 awk/sed 直接解析 YAML proxy name。

## 策略组顺序

```text
Proxies
20 个应用组（AI 第一）
🎯Direct
✈️Final
🏠 自建节点
🏠 自建节点-自动
各机器 select/url-test
国家 select/url-test
🌍 其他地区（如非空）
```

## 修改时必须同步

```text
tools/convert.py
SELF_HOSTED.md
README.md
AGENTS.md
.claude/skills/my-rulesets-convert/SKILL.md
tests/
```

## 验证

```bash
node --check overwrite_script.js
node tests/test_self_hosted_overwrite.js
sh -n openclash_overwrite.sh
sh tests/test_openclash_self_hosted_contract.sh
python3 -m unittest tests/test_self_hosted_policy.py -v
```

## 客户端刷新注意

- FlClash 外部获取可能是一次性快照，GitHub 更新后需要重新获取。
- Clash Verge 脚本 profile 通常是本地文件，需要同步。
- OpenClash 需要部署到软路由、触发完整覆写、重启后检查实际运行配置。
- 没有设备权限时，只能报告 GitHub 已完成，不能声称真实设备已更新。

## 安全

公开仓库禁止生产 VPS 凭据、订阅 token、OpenClash secret。只提交逻辑和合成 fixture。
