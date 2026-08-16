# AGENTS.md — AI Agent 操作手册

> 本文件是给 **AI Agent**（Claude Code / Codex / Cursor / 其他）看的操作手册。
> 当用户提出代理/机场/分流相关需求时，按本文档执行。
> 目的：让任何 Agent 读完后，能独立完成「订阅转换、客户端覆写、部署、验证」整套流程。
>
> 人类读者请移步 [README.md](README.md) / [USAGE.md](USAGE.md) / [OVERWRITE.md](OVERWRITE.md)。

---

## 0. 快速定位：用户需求 → 动作

| 用户说… | 你该做什么 |
|---------|-----------|
| "换机场了/新订阅" | [任务 A：订阅转换](#任务-a订阅转换) |
| "给 FlClash/Clash Verge 写覆写" | [任务 B：Clash 系覆写](#任务-bclash-系覆写) |
| "OpenClash 覆写不生效 / 节点全红" | [任务 C：OpenClash 覆写与排障](#任务-copenclash-覆写与排障) |
| "Surge 引用规则集" | [任务 D：Surge 配置](#任务-dsurge-配置) |
| "ChatGPT 用不了 / 地区限制" | [任务 E：地区限制排查](#任务-e地区限制排查广播-ip) |
| "验证配置 / 测试节点" | [任务 F：验证与测试](#任务-f验证与测试) |
| "把 XX 转成 ss/trojan 协议" | [任务 A](#任务-a订阅转换)，`convert.py` 自动识别协议 |
| 不确定做什么 | 先读 [USAGE.md](USAGE.md) 和本文件，向用户确认目标平台 |

---

## 0.5 全局协作规范（最重要，违反视为错误）

> ⚠️ **用户反复强调的硬性要求，任何 Agent 必须遵守：**

1. **所有修改必须「云端 + 本地」双端一致**
   - 本仓库（GitHub `xmzzzw/my-rulesets`）是唯一真源（source of truth）
   - **改了任何文件（overwrite_script.js / openclash_overwrite.sh / convert.py / 文档 / skill），必须同步：**
     - 推送到 GitHub（云端）
     - 更新本地对应文件（`~/my-rulesets/`）
     - 若涉及已部署的客户端（如 Windows Clash Verge / r2s OpenClash），**还要把改动同步到目标设备并重启生效**
   - **不允许只改一边**：只改本地不推送，或只推 GitHub 不动本地，都算未完成
2. **本地 skills 与仓库保持一致**
   - `~/.claude/skills/my-rulesets-convert/` 和 `~/.claude/skills/my-rulesets-overwrite/` 的内容
     必须与仓库中规格保持一致（策略组顺序、动态分组、命名规则等）
   - 仓库规格一变，本地 skill 要同步更新
3. **修改流程**：改 → 本地验证 → 推 GitHub → 同步目标设备（如需）→ 更新记忆（如需）

---

## 1. 仓库与环境

### 1.1 仓库结构

```
my-rulesets/                          # 公开仓库 github.com/xmzzzw/my-rulesets
├── README.md                         # 项目总览（人类）
├── USAGE.md                          # 完整使用说明（人类）
├── OVERWRITE.md                      # 各客户端覆写教程 + OpenClash 踩坑（人类）
├── AGENTS.md                         # 本文件（Agent 操作手册）
├── overwrite_script.js               # FlClash / Clash Verge 覆写脚本
├── openclash_overwrite.sh            # OpenClash 覆写脚本
├── tools/
│   ├── convert.py                    # 通用转换工具（订阅→配置）
│   └── README.md
├── *.list                            # Surge 格式规则集（32 个）
├── clash/*.list                      # Clash 兼容规则集（32 个，覆写脚本引用）
└── icons/                            # 策略组图标
```

### 1.2 环境信息（Agent 需要知道的）

- **本机**（macOS）：`~/my-rulesets/` 是仓库工作副本
- **软路由 r2s**：`ssh r2s`（192.168.3.100，iStoreOS + OpenClash）
- **GitHub**：`github.com/xmzzzw/my-rulesets`，`gh` CLI 已登录（repo/workflow 权限）
- **工具**：`python3`（本机）、`ruby`（r2s 有 `/usr/share/openclash/YAML.rb`）、mihomo 内核在 r2s `/etc/openclash/clash`

### 1.3 ⚠️ 安全约束（公开仓库）

仓库是**公开的**。以下内容**绝不允许写入仓库**：
- ❌ 机场订阅链接（含 token）
- ❌ 代理认证密码（格式如 `Clash:<密码>`，位于 r2s `/etc/config/openclash` 的 `authentication`）
- ❌ OpenClash API secret（位于运行配置的 `secret` 字段）
- ❌ 含真实节点的客户端配置（`*.yaml`/`*.conf`/`MyRules_*`，已在 `.gitignore` 阻止）

这些敏感值只存在于：`~/.claude/projects/-Users-zhouzhenwei/memory/` 记忆文件、r2s 配置文件、用户本地。
文档中一律用占位符：`<订阅URL>` / `<认证>` / `<secret>`。
> ⚠️ Agent 注意：真实值从记忆或 r2s 读取，**禁止**以任何形式写入公开文档/commit。

---

## 2. 工具清单（Agent 必读）

### 2.1 `tools/convert.py` — 通用转换工具

**用途**：机场订阅（文件/URL）→ 自定义配置。自动识别协议/国家/格式，**不死板**。

```bash
cd ~/my-rulesets

# 订阅 URL → Surge 配置（打印预览）
python3 tools/convert.py --input '<订阅URL>'

# → Clash YAML
python3 tools/convert.py --input '<订阅URL>' --format clash

# → 输出文件
python3 tools/convert.py --input '<文件或URL>' --output /tmp/out.conf

# Surge 保留订阅刷新（[Proxy] 用 #!include）
python3 tools/convert.py --input '<订阅URL>' --subscription-refresh

# 不合并单节点国家
python3 tools/convert.py --input '<文件>' --no-merge-single
```

**能力**：
- 协议：ss / ssr / trojan / anytls / vmess / vless / hysteria2 / tuic 等
- 国家：emoji（🇭🇰）/ 国家代码（HK）/ 中文名（香港）自动识别
- 单节点国家合并到 🌍 其他地区（≤1 节点不建分组）
- 规则集注入：引用 `clash/` 目录 32 个规则集

**抓取订阅的坑**（convert.py 内置 `--noproxy '*'`）：
- 机场常限制代理出口 IP → 必须直连抓取
- 部分机场需打开后台开启订阅窗口（10 分钟有效）
- 失败时用 `curl -sL --noproxy '*' -A "ClashForWindows/0.20.39" '<订阅URL>'` 手动抓

### 2.2 `overwrite_script.js` — FlClash / Clash Verge 覆写

```javascript
// 入口（Clash Verge 传 profileName）
function main(config, profileName) { ...; return config; }
```

**逻辑**：保留订阅 proxies → 重建 proxy-groups（国家分组+自动选择+应用组+Direct/Final）→ 注入 32 rule-providers → 重写 rules。

**URL**：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js`

### 2.3 `openclash_overwrite.sh` — OpenClash 覆写

部署到 r2s：`/etc/openclash/custom/openclash_custom_overwrite.sh`

**逻辑**：保留 proxies → 用 `ruby_edit` 整体替换 proxy-groups / rules → 用 `ruby_merge_hash` 注入 rule-providers（**jsdelivr CDN url**）。

**⚠️ 已确认的坑**（改这个脚本必读）：
1. **Ruby 片段必须单行**：OpenClash init.d 用 grep 按行提取片段，多行参数被截断 → 覆写静默失效。脚本里用 heredoc + `tr -d '\n'`。
2. **proxy-groups 是 Array**：用 `ruby_edit` 整体赋值，`ruby_merge_hash` 会报 `merge! for Array`。
3. **provider url 用 jsdelivr**：`https://testingcf.jsdelivr.net/gh/xmzzzw/my-rulesets@main/clash/<文件>.list`（raw.githubusercontent.com 软路由常被墙 → EOF 死循环 → 节点全红）。
4. **规则最前面加内部直连**：`DOMAIN-SUFFIX,jsdelivr.net,🎯Direct` 等。
5. **Quick Start 跳过覆写**：改完脚本要 `touch` + 删 `/tmp/openclash.change` 再重启。

---

## 3. 任务 A：订阅转换

**触发**：用户提供订阅链接/文件，要求生成配置或换机场。

**步骤**：
1. 获取订阅内容（URL 直连抓取，`--noproxy '*'`）
2. `python3 ~/my-rulesets/tools/convert.py --input <订阅> --format <surge|clash>`
3. 检查输出：策略组顺序、国家分组、规则集引用、AI 组
4. 验证（见 [任务 F](#任务-f验证与测试)）
5. 部署到目标客户端

**命名规范**（严格）：`<机场名称>_<协议>_<代理终端>_MyRules.<ext>`
- 代理终端：`Surge` / `Clash`（Clash 系统一，FlClash/Clash Verge 均用）等
- 规则名统一用 `MyRules`
- 示例：`CreamData_Anytls_Clash_MyRules.yaml`、`Flower_ss_Surge_MyRules.conf`

**手动规格**（convert.py 不适用时）：
```
策略组顺序：Proxies → 应用组(AI/Netflix/...) → 🎯Direct → ✈️Final → 国家分组 + 自动选择
国家分组（动态）：任一国家节点 ≥2 即建 select + url-test 自动分组（🇭🇰 香港 = select, 🇭🇰 香港-自动, 节点...；🇭🇰 香港-自动 = url-test, url=http://www.gstatic.com/generate_204, interval=300, tolerance=50）；≤1 节点国家并入 🌍 其他地区
规则集：RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/clash/<规则集>.list,<策略>
```

---

## 4. 任务 B：Clash 系覆写

**触发**：用户要求给 FlClash / Clash Verge 等写覆写。

**FlClash（安卓）**：
1. 添加订阅（机场 Clash 链接）
2. 配置 → 覆写 → 脚本模式
3. 从 URL 导入：`https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/overwrite_script.js`

**Clash Verge Rev（Windows）**：
1. 添加订阅
2. 订阅右键 → 新建脚本 profile
3. 粘贴 `overwrite_script.js` 内容（`function main(config, profileName)`）

**验证**：代理页应有 `Proxies` 顶层 → 应用组 → Direct/Final → 国家分组；节点可展开。

---

## 5. 任务 C：OpenClash 覆写与排障

**触发**：用户报告 OpenClash 覆写不生效 / 节点全红 / 要部署覆写。

### 5.1 部署/更新覆写脚本

```bash
ssh r2s
# 备份旧脚本
cp /etc/openclash/custom/openclash_custom_overwrite.sh \
   /etc/openclash/custom/openclash_custom_overwrite.sh.bak-$(date +%Y%m%d-%H%M%S)
# 从 GitHub 拉最新（r2s 直连 GitHub 用 --noproxy '*'）
curl -sL --noproxy '*' -o /etc/openclash/custom/openclash_custom_overwrite.sh \
  https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/openclash_overwrite.sh
chmod +x /etc/openclash/custom/openclash_custom_overwrite.sh
# 关键：触发完整流程（否则 Quick Start 跳过）
touch /etc/openclash/custom/openclash_custom_overwrite.sh
rm -f /tmp/openclash.change
# 重启
/etc/init.d/openclash restart
```

### 5.2 诊断清单（按序检查）

```bash
ssh r2s
# 1. OpenClash 是否 running
/etc/init.d/openclash status

# 2. 实际运行配置
ps w | grep 'clash -d' | grep -v grep | awk '{print $NF}'

# 3. 覆写脚本是否真的跑了（日志）
grep -iE 'MyRules|Overwrite' /tmp/openclash.log | tail

# 4. 是否 Quick Start 跳过
grep 'Quick Start' /tmp/openclash.log | tail

# 5. 运行配置结构（验证覆写生效）
ruby -ryaml -e 'c=YAML.load_file("<运行配置>"); puts "proxies=#{c["proxies"]&.length} groups=#{c["proxy-groups"]&.length} providers=#{c["rule-providers"]&.keys&.length} rules=#{c["rules"]&.length}"'
# 期望：proxies 130 / groups 44 / providers 32 / rules 39

# 6. provider 下载错误（节点全红主因）
grep -iE 'Provider.*pull error|EOF' /tmp/openclash.log | tail

# 7. 节点延迟（核心健康检查）
# secret 从运行配置读
SECRET=$(ruby -ryaml -e 'c=YAML.load_file("<运行配置>"); print c["secret"].to_s')
curl -s -H "Authorization: Bearer $SECRET" -X GET \
  'http://127.0.0.1:9090/group/%F0%9F%87%AD%F0%9F%87%B0%20%E9%A6%99%E6%B8%AF/delay?url=http://www.gstatic.com/generate_204&timeout=3000'
```

### 5.3 常见坑速查

| 症状 | 根因 | 解决 |
|------|------|------|
| 日志有 Complete 但配置没变 | Ruby 片段多行被截断 | 脚本参数改单行 |
| 节点全红 | provider 下载 EOF（raw 被墙） | 用 jsdelivr + 加内部直连规则 |
| `merge! for Array` 错误 | proxy-groups 用 ruby_merge_hash | 改用 ruby_edit |
| 重启后覆写没跑 | Quick Start 跳过 | touch + 删 change 文件 |
| 代理连不上 | DNS 注入被墙 | nameserver 加国内 IP + proxy-server-nameserver |
| 面板空白 | 面板目录损坏/浏览器缓存 | 重下面板 + 强制刷新 |

---

## 6. 任务 D：Surge 配置

**触发**：用户要求 Surge 用 my-rulesets 规则。

**方法**：`[Rule]` 段引用远程规则集：

```ini
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_AI.list,AI,update-interval=86400
RULE-SET,https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/nexitallyy_Extra_CN_3.list,🎯Direct,update-interval=86400
```

**订阅刷新**：`[Proxy]` 段 `#!include <订阅URL>`。

**验证**：`surge-cli profile check <配置名>`（surge-cli 在 `/Applications/Surge.app/Contents/Applications/surge-cli`）。

---

## 7. 任务 E：地区限制排查（广播 IP）

**触发**：用户说 ChatGPT/某服务「国家不支持」。

**核心事实**：**广播 IP 机场**（如 CreamData）所有节点共享同一出口 IP 池，标注国家 ≠ 实际出口。

**排查**：
```bash
# 看实际出口国家/ASN
curl -s -x http://<认证>@127.0.0.1:7890 'https://ipinfo.io/json' | grep -E '"country"|"org"'
```

**结论**：
- 广播 IP 机场的地区限制**无法靠覆写解决**（出口 IP 不变）
- OpenAI 支持地区参考：美国/日本/新加坡/韩国；香港/台湾不支持
- 需原生 IP 机场/真家宽节点才能用 ChatGPT 等

**验证 ChatGPT 走向**：
```bash
# 切 AI 组到目标策略组
curl -s -H "Authorization: Bearer <secret>" -H 'Content-Type: application/json' \
  -X PUT 'http://127.0.0.1:9090/proxies/AI' -d '{"name":"🇺🇸 美国"}'
# 测流量走向
curl -s -x http://<认证>@127.0.0.1:7890 'https://chatgpt.com/cdn-cgi/trace' | grep 'loc='
# 内核日志
grep -iE 'chatgpt|openai' /tmp/openclash.log | tail
```

---

## 8. 任务 F：验证与测试

**mihomo 校验**：
```bash
# r2s 上
/etc/openclash/clash -t -d /tmp -f <config.yaml>
# 期望：configuration file ... test is successful
```

**节点延迟**：
```bash
curl -s -H "Authorization: Bearer <secret>" -X GET \
  'http://127.0.0.1:9090/group/<urlencoded组名>/delay?url=http://www.gstatic.com/generate_204&timeout=3000'
# 期望：{"节点名": 延迟ms, ...}，无 timeout
```

**出口 IP**：
```bash
curl -s -x http://<认证>@127.0.0.1:7890 'https://api.ipify.org'
```

**规则集 URL 可达性**：
```bash
# 本机或 r2s，--noproxy '*'
curl -s -o /dev/null -w '%{http_code}\n' --noproxy '*' \
  'https://testingcf.jsdelivr.net/gh/xmzzzw/my-rulesets@main/clash/nexitallyy_Extra_AI.list'
# 期望 200
```

---

## 9. Agent 工作流模板

**换机场 → 全平台**（完整流程）：

1. 抓订阅：`curl -sL --noproxy '*' -A "ClashForWindows/0.20.39" '<订阅URL>' -o /tmp/sub`（失败则提示用户开订阅窗口）
2. 生成配置：`python3 tools/convert.py --input <订阅>`（看协议/国家/格式）
3. 按平台交付：
   - **Surge**：`--subscription-refresh` 版 → `~/Library/Application Support/Surge/Profiles/`
   - **FlClash/Verge**：订阅 + `overwrite_script.js`
   - **OpenClash**：订阅 + `openclash_overwrite.sh`（部署见任务 C）
4. 验证：mihomo `-t` + 节点延迟 + 出口 IP
5. 检查 .gitignore 没把敏感文件提交；README/文档链接更新

**规则集更新**：
- 改 GitHub 对应 `.list` 文件
- 客户端按 `interval`（86400s=1天）自动更新
- 覆写脚本引用 `clash/` 目录的规则集同样生效

---

## 10. 关联文件

- `USAGE.md` — 人类详细使用说明
- `OVERWRITE.md` — 各客户端覆写教程 + 踩坑
- `tools/README.md` — convert.py 文档
- `tools/convert.py` — 转换工具
- `overwrite_script.js` / `openclash_overwrite.sh` — 覆写脚本
- `.claude/skills/` — Claude Code 可调用的 skill（convert / overwrite）
