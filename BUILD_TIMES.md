# Build & Install Times

Tracks wall-clock for ISO builds (auto-appended by [`build-scripts/build-the-iso.sh`](build-scripts/build-the-iso.sh)) and for Calamares installs (extracted from `/var/log/Calamares.log` on the target). Newest entries at the top of each table.

Useful for spotting cost regressions when changing squashfs compression, kernel set, package list, or Calamares modules.

## ISO Builds

| When             | Version    | Kernel(s)                  | Squashfs       | Duration | ISO size | Notes                                    |
|------------------|------------|----------------------------|----------------|----------|----------|------------------------------------------|
| 2026-06-23 15:15 | v26.06.23 | linux-cachyos linux-zen | zstd L3 -b 1M | 9m59s | 6.1G | |
| 2026-06-19 18:47 | v26.06.19 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m24s | 6.1G | |
| 2026-06-19 10:13 | v26.06.19 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m5s | 6.1G | |
| 2026-06-19 07:01 | v26.06.19 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m23s | 6.1G | |
| 2026-06-18 15:32 | v26.06.18 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m49s | 6.1G | |
| 2026-06-17 21:16 | v26.06.17 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m20s | 6.1G | |
| 2026-06-17 15:14 | v26.06.17 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m54s | 6.1G | |
| 2026-06-14 07:55 | v26.06.14 | linux-cachyos linux-zen | zstd L3 -b 1M | 9m41s | 6.1G | |
| 2026-06-14 06:42 | v26.06.14 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m32s | 6.1G | |
| 2026-06-12 20:30 | v26.06.12 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m38s | 6.1G | |
| 2026-06-12 18:07 | v26.06.12 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m5s | 6.1G | |
| 2026-06-11 08:35 | v26.06.11 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m25s | 6.1G | |
| 2026-06-11 08:13 | v26.06.11 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m27s | 6.1G | |
| 2026-06-11 07:17 | v26.06.11 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m50s | 6.1G | |
| 2026-06-10 23:49 | v26.06.10 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m49s | 6.1G | |
| 2026-06-10 21:35 | v26.06.10 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m56s | 6.1G | |
| 2026-06-09 21:05 | v26.06.09 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m26s | 6.1G | |
| 2026-06-09 20:22 | v26.06.09 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m44s | 6.1G | |
| 2026-06-09 19:55 | v26.06.09 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m47s | 6.1G | |
| 2026-06-07 19:48 | v26.06.07 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m26s | 6.1G | |
| 2026-06-07 16:30 | v26.06.07 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m29s | 6.1G | |
| 2026-06-07 12:13 | v26.06.07 | linux-lts linux-zen | zstd L3 -b 1M | 6m52s | 5.5G | |
| 2026-06-07 11:07 | v26.06.07 | linux-lts linux-zen | zstd L3 -b 1M | 7m2s | 5.5G | |
| 2026-06-07 09:01 | v26.06.07 | linux-cachyos-bore linux-lts | zstd L3 -b 1M | 6m40s | 4.7G | |
| 2026-06-07 08:23 | v26.06.07 | linux-cachyos-bore linux-lts | zstd L3 -b 1M | 7m27s | 6.1G | |
| 2026-06-07 07:58 | v26.06.07 | linux-cachyos linux-lts | zstd L3 -b 1M | 7m33s | 6.1G | |
| 2026-06-07 05:48 | v26.06.07 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m45s | 6.1G | |
| 2026-06-07 05:33 | v26.06.07 | linux-cachyos linux-zen | zstd L3 -b 1M | 8m34s | 6.1G | |
| 2026-06-06 15:26 | v26.06.06 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m33s | 6.1G | |
| 2026-06-06 08:14 | v26.06.06 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m39s | 6.1G | |
| 2026-06-06 07:35 | v26.06.06 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m26s | 6.1G | |
| 2026-06-05 20:10 | v26.06.05 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m20s | 6.2G | |
| 2026-06-04 19:36 | v26.06.04 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m36s | 6.3G | |
| 2026-06-04 11:46 | v26.06.04 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m54s | 6.3G | |
| 2026-06-04 11:35 | v26.06.04 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m30s | 6.3G | |
| 2026-06-04 11:11 | v26.06.04 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m40s | 6.3G | |
| 2026-06-04 10:20 | v26.06.04 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m24s | 6.3G | |
| 2026-06-04 09:30 | v26.06.04 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m36s | 6.3G | |
| 2026-06-04 06:40 | v26.06.04 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m24s | 6.3G | |
| 2026-06-02 12:34 | v26.06.02 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m32s | 6.3G | |
| 2026-06-01 05:42 | v26.06.01 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m24s | 6.3G | |
| 2026-05-31 16:51 | v26.05.31 | linux-cachyos linux-zen | zstd L3 -b 1M | 7m21s | 6.3G | |
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
| 2026-06-09 21:52 | v26.06.09 | erik@192.168.1.16 | 5m58s | 2 | worf — real metal BIOS/grub; new kiro_bootloader GRUB branch ran (grub-install i386-pc -> /dev/sda, SUCCESS); Fermi on nouveau |
| 2026-06-09 21:48 | v26.06.09 | erik@192.168.1.9 | 3m21s | 2 | picard — real metal UEFI/systemd-boot; new Calamares modules ran; kiro-audit 135/0/0 |
| 2026-06-09 21:48 | v26.06.09 | erik@192.168.1.14 | 4m21s | 2 | riker — real metal UEFI/systemd-boot; new Calamares modules ran; kiro-audit 139/0/0 |
| 2026-06-08 16:44 | v26.06.08 | erik@192.168.1.14 | 3m19s | 2 | riker — real metal (UEFI/systemd-boot); grub + kiro-bootloader-grub + spice all stripped, kiro-audit 135/0/0 |
| 2026-06-08 16:31 | v26.06.08 | erik@192.168.1.9 | 3m20s | 2 | picard — real metal (UEFI/systemd-boot); grub + kiro-bootloader-grub + spice all stripped, kiro-audit 135/0/0 |
| 2026-06-08 16:16 | v26.06.08 | erik@192.168.1.16 | 5m54s | 2 | worf — real metal (BIOS/grub); kiro-audit GRUB boot-safety PASS |
| 2026-06-08 15:34 | v26.06.08 | erik@192.168.122.78 | 2m27s | 2 | KVM (BIOS/grub) |
| 2026-06-07 21:00 | v26.06.07 | erik@192.168.1.14 | 3m16s | 2 | line 2 nonfree (nvidia kept), Intel HD630, v26.06.07 19:40/cfg26.06-08 release ISO |
| 2026-06-07 20:47 | v26.06.07 | erik@192.168.1.9 | 3m30s | 2 | line 1 free, Intel HD630, v26.06.07 19:40/cfg26.06-08 release ISO |
| 2026-06-01 07:45 | v26.06.01 | picard | 3m47s | 2 | bare-metal install |
| 2026-06-01 07:27 | v26.06.01 | riker | 6m1s | 2 | riker reinstall test |
| 2026-06-01 07:23 | v26.06.01 | worf | 5m53s | 2 | MEDION P7624, BIOS, nouveau |
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
