# Build & Install Times

Tracks wall-clock for ISO builds (auto-appended by [`build-scripts/build-the-iso.sh`](build-scripts/build-the-iso.sh)) and for Calamares installs (extracted from `/var/log/Calamares.log` on the target). Newest entries at the top of each table.

Useful for spotting cost regressions when changing squashfs compression, kernel set, package list, or Calamares modules.

## ISO Builds

| When             | Version    | Kernel(s)                  | Squashfs       | Duration | ISO size | Notes                                    |
|------------------|------------|----------------------------|----------------|----------|----------|------------------------------------------|
| 2026-05-31 15:11 | v26.05.31 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m52s | 6.3G | |
| 2026-05-31 14:53 | v26.05.31 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m21s | 6.3G | |
| 2026-05-31 14:33 | v26.05.31 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m9s | 6.3G | |
| 2026-05-31 14:11 | v26.05.31 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m46s | 6.3G | |
| 2026-05-31 13:37 | v26.05.31 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m17s | 6.3G | |
| 2026-05-31 13:04 | v26.05.31 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m47s | 6.3G | |
| 2026-05-31 12:28 | v26.05.31 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m21s | 6.3G | |
| 2026-05-31 07:07 | v26.05.31 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m4s | 6.3G | |
| 2026-05-30 16:47 | v26.05.30 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m41s | 6.3G | |
| 2026-05-30 12:18 | v26.05.30 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m18s | 6.2G | |
| 2026-05-29 22:40 | v26.05.29 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m29s | 6.2G | |
| 2026-05-29 13:22 | v26.05.29 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m22s | 6.2G | |
| 2026-05-29 12:43 | v26.05.29 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m31s | 6.2G | |
| 2026-05-29 07:55 | v26.05.29 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m8s | 6.2G | |
| 2026-05-28 22:36 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m12s | 6.2G | |
| 2026-05-28 18:54 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m12s | 6.2G | |
| 2026-05-28 18:28 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m11s | 6.2G | |
| 2026-05-28 17:37 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 6m57s | 6.2G | |
| 2026-05-28 15:33 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m51s | 6.1G | |
| 2026-05-28 13:52 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m16s | 6.1G | |
| 2026-05-28 11:58 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m3s | 6.1G | |
| 2026-05-28 11:27 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m20s | 6.1G | |
| 2026-05-28 10:52 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m43s | 6.1G | |
| 2026-05-28 10:40 | v26.05.28 | linux-cachyos linux-zen | zstd L6 -b 1M | 8m4s | 5.9G | |
| 2026-05-28 09:22 | v26.05.28  | linux-cachyos linux-zen    | zstd L6 -b 1M  | (pre)    | 5.9 GB   | first multi-kernel build (manual entry)  |

## Calamares Installs

| When             | ISO        | Target            | Duration | mkinitcpio passes | Notes                                       |
|------------------|------------|-------------------|----------|---------------------|---------------------------------------------|
| 2026-05-28 19:27 | v26.05.28 | picard (bare metal) | 3m11s | 2 | fresh install — kiro-audit 130/0/0 |
| 2026-05-28 15:57 | v26.05.28 | riker (bare metal) | 3m12s | 2 | post-ppd-pin fix |
| 2026-05-28 10:55 | v26.05.28 | riker (bare metal) | 123m28s* | 2 | second physical machine; *duration includes wizard-UI time (mkinitcpio pass count is the relevant install-execution metric — 2 passes, identical to post-fix VM) |
| 2026-05-28 08:43 | v26.05.28  | VirtualBox VM     | ~3 min   | 2                   | post-fix: cmdline + hook suppression in place |
| 2026-05-28 07:21 | v26.05.28  | VirtualBox VM     | ~4 min   | 10                  | baseline: cmdline-dup bug + 5× mkinitcpio churn |

---

## How rows get added

- **ISO Builds** — [`build-scripts/build-the-iso.sh`](build-scripts/build-the-iso.sh) captures start epoch in `main()`, calls `record_build_time()` after `create_checksums`, and inserts a row at the top of the table. Squashfs setting is read live from `archiso/profiledef.sh`. Failure is non-fatal (logs a warning, build still succeeds).
- **Calamares Installs** — run [`build-scripts/record-install-time.sh`](build-scripts/record-install-time.sh) after each test install. It SSHes into the target, reads `/var/log/Calamares.log` (first/last timestamp = duration; `==> Building image` count = mkinitcpio passes), reads ISO version from `/etc/dev-rel`, and prepends a row. No kiro_final / package-rebuild needed — Calamares already timestamps every log line, so the data is right there. Usage:
  ```bash
  bash build-scripts/record-install-time.sh vm                          # VirtualBox guest on port 2022
  bash build-scripts/record-install-time.sh picard --notes "bare metal" # named host
  bash build-scripts/record-install-time.sh riker  --notes "post-fix"   # named host
  bash build-scripts/record-install-time.sh vm     --dry-run            # print, don't write
  ```
