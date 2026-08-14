# my-rulesets 转换工具

> 灵活处理「机场订阅 → 自定义配置」的各种转换场景。
> 自动识别协议、国家、格式，**不死板**，遇到新场景自动匹配。

## 设计理念

这个工具解决的核心问题：**每次换机场/加订阅，都要手动做一套转换**（识别协议、归类国家、建策略组、引用规则集）。工具把这些逻辑固化下来，**自动匹配**，一次搞定。

**灵活性的体现**：
- **协议自动识别**：ss / trojan / anytls / vmess / vless / hysteria2 / ...（从节点行自动检测）
- **国家自动识别**：emoji（🇭🇰）/ 国家代码（HK）/ 中文名（香港）—— 多种命名格式
- **单节点国家自动合并**：只有 1 个节点的国家，不建分组，归入 🌍 其他地区
- **格式自动检测**：Surge(.conf) / Clash(.yaml) 输入自动识别
- **订阅刷新保留**：可生成 `[Proxy]` 用 `#!include` 的订阅刷新版
- **多输出**：Surge 配置 / Clash YAML / 覆写数据

## 使用方法

### 基本用法

```bash
# 自动检测输入格式，输出 Surge 配置
python3 tools/convert.py --input <文件或订阅URL>

# 指定输出格式
python3 tools/convert.py --input <文件> --format clash

# 生成订阅刷新版（[Proxy] 用 #!include 保留订阅刷新）
python3 tools/convert.py --input <订阅URL> --subscription-refresh

# 不合并单节点国家
python3 tools/convert.py --input <文件> --no-merge-single

# 输出到文件
python3 tools/convert.py --input <文件> --output <输出路径>
```

### 参数说明

| 参数 | 说明 | 默认 |
|------|------|------|
| `--input` | 输入文件或订阅 URL | 必填 |
| `--format` | 输出格式：`surge` / `clash` / `auto` | `auto` |
| `--output` | 输出文件路径 | 打印预览 |
| `--no-merge-single` | 不合并单节点国家 | 合并 |
| `--subscription-refresh` | [Proxy] 用 `#!include` 保留订阅刷新 | 关闭 |

## 转换流程

```
输入（文件/URL）
  ↓
1. 读取内容（URL 自动绕过代理直连，适配机场 IP 限制）
  ↓
2. 解析节点（自动识别协议 ss/trojan/anytls/...）
  ↓
3. 国家归类（emoji / 国家代码 / 中文名 自动匹配）
  ↓
4. 单节点国家合并（≤1 节点 → 🌍 其他地区）
  ↓
5. 构建策略组（国家分组 + 自动选择 + 应用组 + Final）
  ↓
6. 注入规则集（引用 my-rulesets GitHub）
  ↓
输出（Surge / Clash / 覆写数据）
```

## 国家识别规则

工具支持 **3 种节点命名格式**自动识别国家：

| 格式 | 示例 | 识别方式 |
|------|------|---------|
| emoji | `🇭🇰 HK \| 香港 01` | 匹配 emoji |
| 国家代码 | `HK 01` / `HongKong 01` | 匹配代码/英文 |
| 中文名 | `香港 01` | 匹配中文名 |

无法识别的节点自动归入 **🌍 其他地区**。

## 输出规格

工具生成的配置遵循统一规格（与 my-rulesets 项目一致）：

**策略组顺序**：
```
Proxies → 应用组(AI/Netflix/...) → 🎯Direct → ✈️Final → 国家分组 + 自动选择
```

**国家分组**：每个国家 `select` 组 + `-自动` url-test 故障转移

**规则集**：引用 `my-rulesets` GitHub 的 32 个规则集

**AI 分流**：AI 策略组引用全部国家分组（select 手动选，不固定出口）

## 与其他脚本的关系

| 脚本 | 用途 |
|------|------|
| `tools/convert.py` | **通用转换工具**（本文件），自动生成 Surge/Clash 配置 |
| `overwrite_script.js` | FlClash / Clash Verge 覆写脚本（订阅拉节点后注入规则） |
| `openclash_overwrite.sh` | OpenClash 覆写脚本 |

**典型用法组合**：
1. 机场换新订阅 → `convert.py` 生成 Surge 配置（或直接订阅刷新）
2. FlClash/Clash Verge → 订阅 URL + `overwrite_script.js`
3. OpenClash → 订阅 + `openclash_overwrite.sh`

## 未来扩展

- [ ] Clash 覆写数据输出（供 FlClash custom 模式）
- [ ] 更多协议适配（wireguard/hysteria1 等）
- [ ] 订阅流量/到期信息检测（subscription-userinfo）
- [ ] 图标 URL 自动注入
