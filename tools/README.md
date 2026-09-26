# tools/convert.py

`convert.py` 把节点配置转换成 my-rulesets 的 Surge / Clash 策略。

## 用法

```bash
python3 tools/convert.py --input <文件或URL> --format surge
python3 tools/convert.py --input <文件或URL> --format clash
```

常用参数：

```text
--format surge|clash|auto
--output <path>
--subscription-refresh
--no-merge-single
--protocol <label>
```

## Self-hosted V2

节点命名：

```text
<Provider> | <Machine-ID> | <Protocol>
```

示例：

```text
DMIT | LAX-01 | Snell
DMIT | LAX-01 | HY2
Lisa | LAX-01 | Snell
Lisa | LAX-01 | HY2
```

输出策略：

```text
🏠 自建节点
🏠 自建节点-自动
🖥 DMIT · LAX-01
🖥 DMIT · LAX-01-自动
🖥 Lisa · LAX-01
🖥 Lisa · LAX-01-自动
```

顶层和机器级 `url-test` 都直接引用真实协议节点。

## 国家逻辑

Self-hosted 节点先剔除，然后普通机场节点按国家识别：

- 国家节点 `>=2`：独立国家组
- 国家节点 `<=1`：`🌍 其他地区`

## 安全

工具不应该把真实凭据写进 GitHub。生成的真实客户端配置应留在本地并由 `.gitignore` 排除。
