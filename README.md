# my-rulesets

自定义分流规则集 + 多平台覆写方案，节点用机场订阅、规则用自己维护的一套。

**核心原则**：
- **节点**：使用机场订阅链接（实时更新 + 自动显示流量/到期）
- **规则/策略组**：使用本仓库的规则集（国家分组 + 自动选择 + AI 分流 + opencode）

## 目录结构

```
my-rulesets/
├── *.list               # Surge 格式规则集（32 个）
├── clash/               # Clash 兼容规则集（32 个，去除 USER-AGENT）
├── icons/               # 策略组图标（22 个）
├── overwrite_script.js  # FlClash / Clash Verge 覆写脚本
├── openclash_overwrite.sh  # OpenClash 覆写脚本
└── README.md
```

## 多平台部署方案

### 🍎 苹果生态（Mac / iPhone / iPad）— Surge

直接引用本仓库规则集（详见下方「Surge 用法」）。

### 🤖 安卓 — FlClash

**方案：订阅 URL 拉节点 + 覆写脚本注入规则**

1. **添加订阅**：粘贴机场订阅链接（Clash 格式）
   ```
   https://api-huacloud.dev/sub?target=clash&insert=true&emoji=true&udp=true&clash.doh=true&new_name=true&filename=Flower_SS.yaml&url=<你的订阅>
   ```
   ✅ 节点自动拉取，流量进度条 / 已用 / 总流量 / 到期时间自动显示（订阅响应头带 `subscription-userinfo`）

2. **配置覆写脚本**：
   - 进入该订阅 → 「覆写」→ 选「脚本」模式
   - 从 URL 导入：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js`
   - 脚本自动把订阅配置改造为：
     - 36 个策略组（6 国家分组 + 各 `-自动` url-test 故障转移 + 🌍其他地区 + 应用组）
     - 32 个 rule-providers（引用本仓库 clash/ 规则集）
     - 34 条 rules（RULE-SET + GEOIP + MATCH）

3. **更新流量**：打开机场管理页（触发订阅窗口期）→ FlClash 里「更新配置」

### 🪟 Windows — Clash Verge Rev

**方案：订阅 URL 拉节点 + 脚本 profile 注入规则**

1. **添加订阅**：机场订阅链接
2. **配置脚本**：
   - 订阅右键 → 「脚本」→ 新建脚本 profile
   - 粘贴或从 URL 导入：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js`
   - 效果同 FlClash（覆盖策略组 + 注入规则集）

### 🖥️ 软路由 — OpenClash

**方案：订阅 URL 拉节点 + 覆写脚本注入规则**

1. **订阅配置**：OpenClash 里配置机场订阅链接
2. **配置覆写脚本**：把 `openclash_overwrite.sh` 放到路由的 `/etc/openclash/custom/openclash_custom_overwrite.sh`
   - 脚本自动注入：
     - rule-providers（引用本仓库 clash/ 规则集）
     - include-all 国家分组（香港/美国/日本/新加坡/台湾 + 自动选择，换机场不用改）
     - 自定义规则（`/etc/openclash/custom/openclash_custom_rules.list`）
3. 或者在 OpenClash 界面「覆写设置 → 规则设置」里粘贴自定义规则

## 覆写脚本说明

### overwrite_script.js（FlClash / Clash Verge）

```javascript
function main(config) {
  // 保留订阅节点（proxies）
  // 重建 36 策略组：国家分组 + url-test 自动选择 + 应用组 + Final
  // 注入 32 rule-providers（引用 clash/ 规则集）
  // 重写 rules（RULE-SET + GEOIP + MATCH）
  return config;
}
```

### openclash_overwrite.sh（OpenClash）

Shell + Ruby 脚本，用 `ruby_merge_hash` 注入 rule-providers 和 include-all 策略组，写自定义规则到 `openclash_custom_rules.list`。

## Surge 用法

```ini
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_AI.list,AI,update-interval=86400
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_CN_3.list,🎯Direct,update-interval=86400
```

## 改造点（相对原始 AmyTelecom 规则）

1. **Extra_AI.list**：新增 `opencode.ai` / `opencode.com` 域名，走 AI 策略组（可手动选美国出口）。
2. **Extra_CN_3.list**：新增国内 AI 模型 API 域名（强制直连，不走代理）：
   - `api.deepseek.com` / `deepseek.com`（DeepSeek）
   - `open.bigmodel.cn` / `bigmodel.cn`（智谱 GLM）
   - `api.moonshot.cn` / `moonshot.cn`（月之暗面 Kimi）
   - `dashscope.aliyuncs.com`（阿里通义千问）

## 规则集清单

| 文件 | 原来源 | 用途 |
|------|--------|------|
| `nexitallyy_Extra_AI.list` | nexitallyy/ProxyRules | AI 平台（OpenAI/Claude/Gemini/Grok/opencode） |
| `nexitallyy_Extra_CN_3.list` | nexitallyy/ProxyRules | 强制直连名单（含国内模型 API） |
| `nexitallyy_Extra_Crypto.list` | nexitallyy/ProxyRules | 加密货币 |
| `nexitallyy_Extra_Proxies.list` | nexitallyy/ProxyRules | 代理名单 |
| `naiixi_Extra_CN.list` | naiixi.com | 国内直连 |
| `naiixi_Extra_CN_2.list` | blackmatrix7（naiixi 镜像） | 国内直连（China） |
| `naiixi_DisneyPlus.list` | naiixi.com | Disney+ |
| `ACL4SSR_*.list` | ACL4SSR/ACL4SSR | Apple/Microsoft/Telegram 等 |
| `blackmatrix7_*.list` | blackmatrix7/ios_rule_script | 各平台规则 |
| `HotKids_*.list` | HotKids/Rules | Bilibili/HBO/Netflix |

## 更新说明

- 原始规则集来自机场（nexitallyy/ProxyRules、blackmatrix7、ACL4SSR、HotKids、naiixi 等），版权归原作者。
- 本仓库做了私有化复制与个性化改造，可自行维护。
- 在 GitHub 上直接修改对应 `.list` 文件即可，客户端按 `update-interval`（默认 1 天）自动更新。

## 相关

- 塔台（tower）：<https://github.com/pengchujin/tower>
- FlClash：<https://github.com/chen08209/FlClash>
- Clash Verge Rev：<https://github.com/clash-verge-rev/clash-verge-rev>
- OpenClash：<https://github.com/vernesong/OpenClash>
