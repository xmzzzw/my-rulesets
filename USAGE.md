# USAGE.md — my-rulesets 使用说明

## 1. 基本模式

机场节点与规则解耦：

```text
机场订阅 / 自建节点
        ↓
my-rulesets 策略
        ↓
应用规则
```

机场节点按国家分组；自建 VPS 使用 Self-hosted V2。

## 2. Self-hosted V2

节点名称：

```text
<Provider> | <Machine-ID> | <Protocol>
```

例如：

```text
DMIT | LAX-01 | Snell
DMIT | LAX-01 | HY2
DMIT | LAX-02 | Snell
DMIT | LAX-02 | HY2
Lisa | LAX-01 | Snell
Lisa | LAX-01 | HY2
```

客户端可见：

```text
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

`🏠 自建节点-自动` 直接测试所有真实 self-hosted 节点；机器自动组只测试该机器的协议节点。

完整合同见 [SELF_HOSTED.md](SELF_HOSTED.md)。

## 3. FlClash / Clash Verge Rev

使用：

```text
overwrite_script.js
```

脚本保留原始 `proxies`，重建策略组、rule-providers、rules。

Self-hosted 节点必须已经存在于传入配置的 `proxies` 中；脚本只做识别和分组，不保存你的 VPS 凭据。

## 4. OpenClash

使用：

```text
openclash_overwrite.sh
```

路径通常为：

```text
/etc/openclash/custom/openclash_custom_overwrite.sh
```

脚本更新后要触发完整覆写，不要只依赖 Quick Start 缓存。

## 5. Surge / Clash 配置生成

```bash
python3 tools/convert.py --input <文件或URL> --format surge
python3 tools/convert.py --input <文件或URL> --format clash
```

如果输入文件中同时存在机场节点与符合命名合同的自建节点，生成器会自动创建 Self-hosted V2 策略结构。

## 6. 国家分组

- `>=2` 个节点：建立国家组 + `-自动`
- `<=1` 个节点：进入 `🌍 其他地区`
- self-hosted 节点不参与国家统计

## 7. AI 策略

存在 self-hosted 时：

```text
AI
├─ 🏠 自建节点
├─ Proxies
├─ 🎯Direct
└─ 国家组...
```

如果希望 AI 固定公网 IP，建议：

```text
AI
→ 🏠 自建节点
→ 🖥 DMIT · LAX-01
→ 🖥 DMIT · LAX-01-自动
```

不要选择跨机器的 `🏠 自建节点-自动` 作为固定身份出口。

## 8. 安全

公开仓库禁止真实密码、PSK、私钥、订阅 token。真实节点只保存在用户本地配置或受控私有环境。
