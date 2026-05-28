# Build & Install Times

Tracks wall-clock for ISO builds (auto-appended by [`build-scripts/build-the-iso.sh`](build-scripts/build-the-iso.sh)) and for Calamares installs (extracted from `/var/log/Calamares.log` on the target). Newest entries at the top of each table.

Useful for spotting cost regressions when changing squashfs compression, kernel set, package list, or Calamares modules.

## ISO Builds

| When             | Version    | Kernel(s)                  | Squashfs       | Duration | ISO size | Notes                                    |
|------------------|------------|----------------------------|----------------|----------|----------|------------------------------------------|
| 2026-05-28 11:58 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m3s | 6.1G | |
| 2026-05-28 11:27 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m20s | 6.1G | |
| 2026-05-28 10:52 | v26.05.28 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m43s | 6.1G | |
| 2026-05-28 10:40 | v26.05.28 | linux-cachyos linux-zen | zstd L6 -b 1M | 8m4s | 5.9G | |
| 2026-05-28 09:22 | v26.05.28  | linux-cachyos linux-zen    | zstd L6 -b 1M  | (pre)    | 5.9 GB   | first multi-kernel build (manual entry)  |

## Calamares Installs

| When             | ISO        | Target            | Duration | mkinitcpio passes | Notes                                       |
|------------------|------------|-------------------|----------|---------------------|---------------------------------------------|
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
