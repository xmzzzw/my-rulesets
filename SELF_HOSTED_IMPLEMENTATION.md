# Self-hosted implementation contract

This file defines the current implementation contract for self-hosted VPS grouping.

- Detection: node name matches `^DMIT\s*\|`.
- Display group: `🛠 DMIT自建`.
- Auto group: `🛠 DMIT自建-自动`.
- Auto mode: `url-test` using `http://www.gstatic.com/generate_204`, interval 300s, tolerance 50ms.
- DMIT nodes are excluded from all country statistics and `🌍 其他地区`.
- `Proxies` places DMIT before country groups.
- `AI` places DMIT before `Proxies` and `🎯Direct`.
- Other application groups place DMIT after `Proxies`/`🎯Direct` and before country groups.
- `✈️Final` exposes DMIT explicitly.
- If no DMIT node exists, no DMIT policy group is generated.

Credentials remain outside this public repository.
