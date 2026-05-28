# Build & Install Times

Tracks wall-clock for ISO builds (auto-appended by [`build-scripts/build-the-iso.sh`](build-scripts/build-the-iso.sh)) and for Calamares installs (extracted from `/var/log/Calamares.log` on the target). Newest entries at the top of each table.

Useful for spotting cost regressions when changing squashfs compression, kernel set, package list, or Calamares modules.

## ISO Builds

| When             | Version    | Kernel(s)                  | Squashfs       | Duration | ISO size | Notes                                    |
|------------------|------------|----------------------------|----------------|----------|----------|------------------------------------------|
| 2026-05-28 09:22 | v26.05.28  | linux-cachyos linux-zen    | zstd L6 -b 1M  | (pre)    | 5.9 GB   | first multi-kernel build (manual entry)  |

## Calamares Installs

| When             | ISO        | Target            | Duration | mkinitcpio passes | Notes                                       |
|------------------|------------|-------------------|----------|---------------------|---------------------------------------------|
| 2026-05-28 08:43 | v26.05.28  | VirtualBox VM     | ~3 min   | 2                   | post-fix: cmdline + hook suppression in place |
| 2026-05-28 07:21 | v26.05.28  | VirtualBox VM     | ~4 min   | 10                  | baseline: cmdline-dup bug + 5× mkinitcpio churn |

---

## How rows get added

- **ISO Builds** — `build-the-iso.sh` captures start epoch in `main()`, calls `record_build_time()` after `create_checksums`, and inserts a row at the top of the table. Squashfs setting is read live from `archiso/profiledef.sh`. Failure is non-fatal (logs a warning, build still succeeds).
- **Calamares Installs** — currently manual. Pull the START/END timestamps from `/var/log/Calamares.log` on the target (via SSH or by mounting the install disk), count `==> Building image` lines for the mkinitcpio-passes column, and prepend the row. **Future automation:** a one-line `printf` in `kiro_final` to `/var/log/kiro-install-time` plus a dev-box helper script that SSHes in, pulls the file, and `sed`-inserts the row here.
