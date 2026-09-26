#!/bin/sh
set -eu

SCRIPT="openclash_overwrite.sh"

sh -n "$SCRIPT"
grep -q 'SELF_INDEX_FILE=' "$SCRIPT"
grep -q '🏠 自建节点' "$SCRIPT"
grep -q '🖥 ${provider} · ${machine}' "$SCRIPT"
grep -q 'hysteria2|hysteria|hy2' "$SCRIPT"

# 旧版 DMIT 专用变量不应再存在；DMIT 只允许作为示例文本出现。
if grep -Eq 'DMIT_NODES_FILE|DMIT_GROUPS|DMIT_NODE_RE|DMIT_GROUP=' "$SCRIPT"; then
  echo "legacy DMIT-specific implementation found" >&2
  exit 1
fi

echo "test_openclash_self_hosted_contract.sh: PASS"
