# Self-hosted DMIT change summary

Branch: `feature/self-hosted-dmit-groups`

## Behavior

When nodes named `DMIT | <Region> | <Protocol>` are present:

- Create `🛠 DMIT自建` selector.
- Create `🛠 DMIT自建-自动` url-test group.
- Put `🛠 DMIT自建` first in `Proxies`.
- Put `🛠 DMIT自建` first in `AI`.
- Add `🛠 DMIT自建` as an explicit option to other application groups and `✈️Final`.
- Exclude all `DMIT | ...` nodes from country grouping and `🌍 其他地区`.

When no DMIT nodes are present, the old country/application structure is preserved.

## Implementations changed

- `overwrite_script.js`
- `openclash_overwrite.sh`
- `tools/convert.py`
- project documentation and regression tests

## Validation completed before PR

- `node --check overwrite_script.js`
- `python3 -m py_compile tools/convert.py`
- `sh -n openclash_overwrite.sh`
- synthetic JS grouping test
- synthetic Python grouping test
- simulated OpenClash group generation with DMIT + US + HK + single JP node

Real r2s/OpenClash deployment is intentionally not performed from GitHub-only access; production deployment should follow the repository's preflight/backup/verify workflow.
