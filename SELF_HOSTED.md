# Self-hosted VPS / 自建 VPS 节点规范

本仓库支持把自建 VPS 当作与“国家分组”同级的一级策略组，而不是混入机场的国家节点池。

## 当前约定：DMIT

自建 DMIT 节点必须采用以下命名格式：

```text
DMIT | <Region> | <Protocol>
```

推荐示例：

```text
DMIT | LAX | Snell
DMIT | LAX | HY2
```

公开仓库只依赖节点名称识别自建节点，不保存 VPS IP、端口密码、PSK、TLS 密钥或任何其他凭据。

## 客户端中的策略结构

当配置里至少存在一个以 `DMIT |` 开头的节点时，自动生成：

```text
Proxies
├─ 🛠 DMIT自建
├─ 🇭🇰 香港
├─ 🇺🇸 美国
├─ 🇯🇵 日本
└─ ...

🛠 DMIT自建
├─ 🛠 DMIT自建-自动
├─ DMIT | LAX | Snell
└─ DMIT | LAX | HY2

🛠 DMIT自建-自动
├─ DMIT | LAX | Snell
└─ DMIT | LAX | HY2
```

`🛠 DMIT自建-自动` 当前使用 `url-test`，参数与现有国家自动组保持一致：

- URL: `http://www.gstatic.com/generate_204`
- interval: `300`
- tolerance: `50`

## AI 策略

如果 DMIT 自建节点存在，`AI` 策略组把 `🛠 DMIT自建` 放在第一位：

```text
AI
├─ 🛠 DMIT自建
├─ Proxies
├─ 🎯Direct
├─ 🇺🇸 美国
├─ 🇭🇰 香港
└─ ...
```

这样海外 AI 服务可以默认走固定 VPS 出口，同时仍可手动切回机场国家组。

其他应用组保持原来的操作习惯：

```text
Google / Telegram / Crypto / Netflix / ...
├─ Proxies
├─ 🎯Direct
├─ 🛠 DMIT自建
├─ 国家分组...
```

## 归类隔离规则

`DMIT | ...` 节点属于 `self-hosted`，不是国家节点：

1. 不参与国家节点数量统计；
2. 不进入 `🇺🇸 美国` 等国家分组；
3. 不进入 `🌍 其他地区`；
4. 只出现在 `🛠 DMIT自建` / `🛠 DMIT自建-自动` 以及上层可选择策略中。

即使 VPS 实际位于洛杉矶，也不会因为地区信息被重复归入美国机场节点池。

## 无 DMIT 节点时

如果配置中不存在 `DMIT | ...` 节点，则不会创建任何 DMIT 分组，原有国家分组和应用策略保持原样，保证向后兼容。

## 适用实现

当前规范已同步到：

- `overwrite_script.js`：FlClash / Clash Verge Rev / Mihomo
- `openclash_overwrite.sh`：OpenClash
- `tools/convert.py`：Surge / Clash 配置生成

后续增加其他 VPS 厂商时，建议沿用同样的 `<Provider> | <Region> | <Protocol>` 命名模型，并为其建立独立 `self-hosted` 一级组，而不是直接塞进国家组。
