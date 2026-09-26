# Tests

当前自建 VPS 改造提供两个最小回归测试：

```bash
python3 tests/test_self_hosted_policy.py
node tests/test_self_hosted_overwrite.js
```

它们验证：

- `DMIT | ...` 自动进入 `🛠 DMIT自建`；
- `🛠 DMIT自建-自动` 正确包含各协议节点；
- `Proxies` 与 `AI` 的 DMIT 优先顺序；
- DMIT 节点不会泄漏进国家分组或 `🌍 其他地区`；
- 不存在 DMIT 节点时保持原有分组行为。

OpenClash 的 shell 脚本还应至少执行 `sh -n openclash_overwrite.sh`，并在真实 r2s/OpenClash 环境部署前进行配置生成和 mihomo 加载验证。
