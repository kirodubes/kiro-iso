# Distro Testing Log

Results of boot and install testing for kiro-iso builds. Newest first.

---

## 2026-05-25 — v26.05.25 — Picard (bare metal, UEFI, Intel)

**Environment:** Picard — bare-metal Kiro on ASUS STRIX Z270H GAMING, Intel Core i7-7700K, Intel I219-V NIC (e1000e), UEFI/systemd-boot. Kernel `linux-lqx 7.0.10-lqx1-1-lqx`. Installed from the `v26.05.25` ISO (built Mon May 25 14:04 CEST).

**Boot:** PASS — UEFI boot via systemd-boot.
**Boot time:** 24.176s total (firmware 13.376s + loader 5.434s + kernel 1.655s + userspace 3.709s). Firmware POST dominates; Kiro's own userspace is 3.7s.

**Install:** Calamares bare-metal install completed. Post-install cleanup verified via `pacman.log`: `grub` removed (systemd-boot), VM-guest packages removed (`open-vm-tools`, `qemu-guest-agent`, `virtualbox-guest-utils`), live-only `kiro-calamares-config` removed, and `do-not-suspend.conf` removed on install (new `kiro_final` cleanup).

**Score: 110 PASS / 1 WARN / 0 FAIL** (`kiro-audit`). The single WARN is multilib intentionally disabled (re-enabled via one click in ATT — not a defect).

**Comprehensive retest — three audits run:**
- **`/syscheck`** — clean. NIC e1000e quiet (the `62-network-optimization.rules` fix from v26.05.24 is holding — no ethtool errors). 0 failed units. firewalld active + enabled (zone `public`). tuned active / power-profiles-daemon inactive, profile `balanced`. All 10 udev rules present. ZRAM 4G/zstd active. All 8 sysctl security baselines correct.
- **`/kiro-check`** — Source-to-installed integrity **CLEAN**. `10-archiso.conf` removed on install, all live-env survivors cleaned, no config drift, all 18 `edu-system-files` scripts present (under their current `kiro-` prefixed names).
- **`Calamares.log`** — no errors or tracebacks. Only benign warnings: `chcon` ×8 (upstream SELinux-distro noise, no `chcon` on Kiro), a transient "EFI but no ESP" before partitioning, and Qt/firmware cosmetics.

**Finding — cosmetic, not a defect:** hostname left at the install default `erik-systemproductname` (DMI-derived `<username>-<product>`). Install-time choice, user-overridable with `hostnamectl set-hostname`; did not affect any subsystem (it did mean `picard.local` mDNS didn't resolve until set).

**Pending updates at test time:** 0

---

## 2026-05-24 — v26.05.24 (kiro-next) — Picard (bare metal, UEFI, Intel)

**Environment:** Picard — bare-metal Kiro on ASUS STRIX Z270H GAMING, Intel Core i7-7700K, Intel I219-V NIC (e1000e), UEFI/systemd-boot. Kernel `linux-lqx 7.0.10-lqx1-1-lqx`. Installed from the `kiro-next-v26.05.24` ISO (built Sun May 24 12:45 CEST). Resume/swap config also cross-checked on a VirtualBox guest.

**Boot:** PASS — UEFI boot via systemd-boot.
**Boot time:** 17.8s total (firmware 6.9s + loader 5.4s + kernel 1.7s + userspace 3.8s); graphical.target at 3.8s userspace.

**Install:** Calamares completed with a **dedicated swap partition** chosen during partitioning (new `kiro-calamares-config-next` feature). Post-install audit via `kiro-audit` (SSH):

**Score: 92 PASS / 0 WARN / 0 FAIL**

**Hibernate / suspend (the focus of this build):**
- **Suspend (S3):** PASS on bare metal.
- **Hibernate → resume (S4):** PASS on bare metal. Resume config verified correct: `resume` hook present in the built initramfs and ordered after `block`/before `filesystems`; kernel cmdline `resume=UUID=` matches the swap partition; `/sys/power/state` includes `disk`; swap ≥ RAM. The `Unable to resume from device … offset 0, continuing boot process` line on a *cold* boot is expected (no saved image present), not a failure.
- **VirtualBox note:** hibernate could **not** be validated in the VM — `vmwgfx` aborts the freeze with `Can't hibernate while 3D resources are active` (exit -16) whenever VMSVGA 3D acceleration is enabled. This is a VirtualBox virtual-GPU limitation, **not** a distro bug; bare metal (above) is the authoritative test.

**Finding — fixed (cosmetic):** Two boot-time `ethtool` errors from `62-network-optimization.rules` on the I219-V — `ethtool -C … rx-frames/tx-usecs/tx-frames` (exit 1) and `ethtool -K … gso on` (exit 92). The rule wrongly applied server-NIC knobs to all `e1000e` devices. Networking was unaffected. Fixed in `edu-system-files` commit `36b4f77` (split e1000e to `rx-usecs` only, dropped from GSO line). **Shipped** in the v26.05.24 ISO rebuilt the same day at 16:53 (after the 14:48 commit) — the corrected rule and a clean boot (no ethtool errors) were confirmed on the installed VM via `/kiro-ready` on 2026-05-24.

**Pending updates at test time:** 0

---

## 2026-05-19 — v26.05.19 — VirtualBox (UEFI, Intel, NAT)

**Environment:** VirtualBox 7.x, UEFI firmware, Intel CPU (6 cores), NAT networking with SSH port forwarding host:2022→guest:22

**Boot:** PASS — UEFI boot via systemd-boot, linux-lqx 7.0.9-lqx1-1-lqx kernel loaded

**Install:** Calamares install completed. Post-install audit via `kiro-audit` (SSH):

**Score: 93 PASS / 0 WARN / 0 FAIL**

Notable passing checks vs previous build:
- `kiro-calamares-config-next` removed — previously FAIL, now PASS
- SSH override (`10-archiso.conf`) absent on installed system — PASS
- CUPS permissions (`classes.conf`, `printers.conf`) 600 — PASS
- All 8 sysctl security values correct — PASS
- ZRAM: zstd, 4G, active — PASS
- No failed systemd units — PASS
- Package integrity (`pacman -Qk`) — PASS

**Boot time:** 10.9s (kernel 3.0s + userspace 7.8s)
**Pending updates at test time:** 0

---

## 2026-05-18 — v26.05.18.01 — VirtualBox (UEFI, Intel, NAT)

**Environment:** VirtualBox 7.x, UEFI firmware, Intel CPU (amd-ucode correctly absent), NAT networking with SSH port forwarding 2222→22

**Boot:** PASS — UEFI boot via systemd-boot, linux-lqx 7.0.9-lqx1-1-lqx kernel loaded

**Install:** Calamares install completed. Post-install audit via `audit.sh`:

| Check                                              | Result   |
|----------------------------------------------------|----------|
| Kernel (linux-lqx running)                         | PASS     |
| Boot files (vmlinuz-linux-lqx, initramfs)          | PASS     |
| Microcode (intel-ucode, no amd-ucode)              | PASS     |
| mkinitcpio (no archiso hook, has microcode/kms)    | PASS     |
| linux-lqx.preset exists, linux.preset removed      | PASS     |
| PipeWire stack complete, pulseaudio absent         | PASS     |
| calamares + mkinitcpio-archiso removed             | PASS     |
| kiro-calamares-config removed                      | **FAIL** |
| Calamares live-only artifacts cleaned up           | PASS     |
| /root permissions 700, sudoers.d 750, polkit 750   | PASS     |
| EDITOR=nano, Bluetooth AutoEnable=true             | PASS     |
| makepkg.conf optimized (MAKEFLAGS, PKGEXT, !debug) | PASS     |
| Pacman repos (nemesis_repo, chaotic-aur, multilib) | PASS     |
| ohmychadwm + XFCE desktop entries                  | PASS     |
| SDDM edu-simplicity theme                          | PASS     |
| User groups (wheel, audio, video, storage…)        | PASS     |
| Services (NetworkManager, sddm, bluetooth)         | PASS     |
| shadow/gshadow 400 permissions                     | PASS     |
| NVIDIA (correctly absent, no GPU)                  | PASS     |
| systemd-boot installed                             | PASS     |
| Package integrity (pacman -Qk)                     | PASS     |

**Score:** 63 PASS, 1 WARN (/etc/calamares dir leftover — caused by FAIL below), 1 FAIL

**Known issue:** `kiro-calamares-config` not removed post-install — `kiro_final` removal step fails silently (pacman lock race suspected). Package is manually removable. Does not affect system functionality.

**BIOS/syslinux boot path:** Not tested (VirtualBox uses UEFI). See TODO.md.
