# tests

Self-hosted V2 回归测试使用纯合成节点，不包含真实 IP、密码、PSK 或订阅 token。

## 测试

```bash
node --check overwrite_script.js
node tests/test_self_hosted_overwrite.js

python3 -m py_compile tools/convert.py
python3 -m unittest tests/test_self_hosted_policy.py -v

sh -n openclash_overwrite.sh
sh tests/test_openclash_self_hosted_contract.sh
```

验证内容：

- 通用 `<Provider> | <Machine-ID> | <Protocol>` 识别
- 多 Provider / 多机器
- `🏠 自建节点` 顶层组
- `🖥 Provider · Machine` 机器组
- 顶层/机器 `url-test` 均直接引用真实节点
- `AI` 与 `Proxies` 的 self-hosted 优先项
- self-hosted 不泄漏进国家组或 `🌍 其他地区`
- 无 self-hosted 时保持机场-only 行为
