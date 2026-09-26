# OVERWRITE.md — 各客户端覆写规范

## 1. 当前一等覆写路径

| 平台 | 实现 |
|---|---|
| FlClash | `overwrite_script.js` |
| Clash Verge Rev | `overwrite_script.js` |
| Mihomo | `overwrite_script.js` / 生成后的 YAML |
| OpenClash | `openclash_overwrite.sh` |
| Surge | `tools/convert.py --format surge` |

## 2. Self-hosted V2

覆写前真实节点命名：

```text
<Provider> | <Machine-ID> | <Protocol>
```

覆写后前端：

```text
🏠 自建节点            Selector
🏠 自建节点-自动       URLTest
🖥 DMIT · LAX-01      Selector
🖥 DMIT · LAX-01-自动 URLTest
...
```

不创建 Provider 单独层；Provider 与 Machine-ID 合并成 `🖥 Provider · Machine-ID`。

自动组直接引用真实协议节点，不嵌套自动组。

## 3. FlClash

配置 → 覆写 → 脚本模式，导入：

```text
https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js
```

注意：外部获取可能是快照。GitHub 更新后需重新获取。

## 4. Clash Verge Rev

订阅右键 → 脚本 profile。脚本入口：

```javascript
function main(config, profileName) { ... }
```

脚本 profile 通常为本地文件；GitHub 更新不会自动替换本地脚本。

## 5. OpenClash

覆写脚本：

```text
/etc/openclash/custom/openclash_custom_overwrite.sh
```

### 关键约束

1. `ruby_*` 参数必须单行。
2. `proxy-groups` 用 `ruby_edit` 整体替换。
3. provider URL 使用 jsDelivr，防止 raw GitHub EOF。
4. 内部规则下载域名必须放 rules 前部直连。
5. YAML 节点名用 Ruby parser 提取，避免 emoji `\U...` 转义失配。
6. 更新脚本后必须触发完整覆写并验证实际运行配置。

## 6. Surge

规则集可以继续远程引用；完整策略建议由：

```bash
python3 tools/convert.py --input <配置> --format surge
```

生成。

## 7. 其他客户端

Loon / Shadowrocket / sing-box 等客户端的策略概念可以映射，但当前仓库没有与 Surge/Mihomo 同等级的独立 renderer。新增 renderer 时必须遵守 [SELF_HOSTED.md](SELF_HOSTED.md)：

```text
内部：Provider / Machine / Protocol
前端：🏠 自建节点 → 🖥 Provider · Machine → real proxy
```

不要把内部四层模型全部暴露成客户端 UI。
