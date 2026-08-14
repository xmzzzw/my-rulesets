# my-rulesets

自定义分流规则集，复制自 AmyTelecom 机场使用的远程规则集，并做了私有化改造。

**用途**：换机场后分流规则不依赖任何机场策略，全部由本仓库统一管理。在塔台（tower）或各代理客户端中引用本仓库的 raw URL 即可。

## 改造点（相对原始 AmyTelecom 规则）

1. **Extra_AI.list**：新增 `opencode.ai` / `opencode.com` 域名，走 AI / 美国出口策略组。用于 OpenCode / OpenCode Go 网关，确保国外模型（OpenAI/Claude 等）API 可达。
2. **Extra_CN_3.list**：新增国内 AI 模型 API 域名（强制直连，不走代理）：
   - `api.deepseek.com` / `deepseek.com`（DeepSeek）
   - `open.bigmodel.cn` / `bigmodel.cn`（智谱 GLM）
   - `api.moonshot.cn` / `moonshot.cn`（月之暗面 Kimi）
   - `dashscope.aliyuncs.com`（阿里通义千问；`aliyuncs.com` 通配已由 Extra_CN_2 覆盖）

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

## 使用方法

### Surge

```ini
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_AI.list,AI,update-interval=86400
```

### Clash（FlClash / Clash Verge / OpenClash）

通过塔台（tower）导出配置时会自动生成 `rule-providers` 引用本仓库规则集。

## 更新说明

- 原始规则集来自 AmyTelecom 机场（nexitallyy/ProxyRules、blackmatrix7、ACL4SSR、HotKids、naiixi 等），版权归原作者。
- 本仓库做了私有化复制与个性化改造，可自行维护。
- 在 GitHub 上直接修改对应 `.list` 文件即可，客户端按 `update-interval`（默认 1 天）自动更新。

## 相关

- 塔台（tower）：<https://github.com/pengchujin/tower>
- 原始 AI 规则：<https://github.com/nexitallyy/ProxyRules>
