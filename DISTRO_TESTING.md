# Distro Testing Log

Results of boot and install testing for kiro-iso builds. Newest first.

---

## 2026-05-28 — cachyos+zen, **fixes verified** — VirtualBox VM (UEFI, Intel i7-10700K)

**Environment:** Same "Kiro" VirtualBox VM, UEFI/systemd-boot. New ISO built after [kiro-calamares-config](/home/erik/KIRO/kiro-calamares-config) commits `8195c9f` (multi-kernel install fixes: cmdline dedup + mkinitcpio churn cut) and `b49668c` (.gitignore for makepkg artifacts), plus [calamares-3.4.2.r4.g841b478-6](/home/erik/KIRO-PKG-BUILD/calamares-3.4.2.r4.g841b478-6/) package carrying the bootloader/main.py `list()` defensive copy. Calamares `3.4.3.20260528-841b4785-dirty`. Host: erik-virtualbox.

**Boot + install:** PASS, both fixes verified.

### Results vs the morning's baseline install

| Metric                                | Baseline (07:21 install) | Post-fix (08:43 install) |
|---------------------------------------|--------------------------|--------------------------|
| `==> Building image` passes in log    | 10 (5 hook-fires × 2 kernels) | **2** (1 explicit Calamares pass × 2 kernels) |
| Install duration (Calamares start→end) | ~4 min                   | **~40 sec**              |
| `/etc/kernel/cmdline`                 | duplicated `rw root=UUID=…` | **single** `rw root=UUID=…` |
| zen entry `options` line              | duplicated                | **clean**                |
| cachyos entry `options` line          | clean (first call)        | clean                    |
| `kiro-audit`                          | 117 / 1 WARN / 0 FAIL     | 117 / 1 WARN / 0 FAIL    |
| Failed systemd units                  | 0                        | 0                        |

### Evidence in the log (`/var/log/Calamares.log`)

```
1171: [PYTHON JOB]: "Suppressed upstream mkinitcpio pacman hook:
      /tmp/calamares-root-.../etc/pacman.d/hooks/90-mkinitcpio-install.hook -> /dev/null"
1189: [PYTHON JOB]: "  Suppress mkinitcpio hook: SUCCESS"
1733: [PYTHON JOB]: "  Restore mkinitcpio hook: SUCCESS"
```

The two `==> Building image` passes are the official Calamares `initcpiocfg` + `Creating initramfs with mkinitcpio…` job — exactly the source-of-truth pass that has to run. All four redundant hook-triggered passes from the morning install (`kiro_remove_nvidia` DKMS removal, `pacman -Rs mkinitcpio-archiso`, two `kiro_ucode` microcode triggers) are now silently suppressed. `kiro_final` then removes the `/dev/null` symlink so the user's first `pacman -Syu` rebuilds initramfs normally on kernel upgrades.

### Boot-loader entries (both clean)

`/boot/efi/loader/entries/`:

- `db6392…-7.0.10-1-cachyos.conf` — current entry, `sort-key=kiro`, single-clean cmdline
- `db6392…-7.0.10-zen1-1-zen.conf` — selectable from menu, single-clean cmdline (was duplicated in baseline)

Both inherit the same `quiet nowatchdog rw root=UUID=… resume=UUID=… systemd.machine_id=…`, only the `linux`/`initrd` paths differ per kernel.

### Not tested this session (queued for bare-metal pass)

- Two physical machines to test next per [README + RESUME flow](RESUME-not-applicable).
- Picking zen as the default at install (would need a build with `kernel="linux-zen linux-cachyos"` reversed — current test boots cachyos by default and zen from the menu only).

### Dev-side wins from the same session (not user-visible)

- `kiro-calamares-config-*.pkg.tar.zst` size dropped from **97 MB** to expected ~5–7 MB after stripping the makepkg `calamares/` bare-clone artifact from the package source.
- `kiro-enable-ssh` now does `pacman -Sy` first and (on the live ISO only) sets `liveuser`'s password to `erik` so SSH actually works after the one-command opt-in — verified the live-ISO gate via `/run/archiso/bootmnt` is a no-op on the installed system (this install correctly logged "Not on live ISO… skipping").

---

## 2026-05-28 — cachyos+zen default kernels — VirtualBox VM (UEFI, Intel i7-10700K)

**Environment:** "Kiro" VirtualBox VM, UEFI/systemd-boot. Live ISO built today after the [build-the-iso.sh:101](build-scripts/build-the-iso.sh) `kernel=` flip from `linux-lqx` → `linux-cachyos linux-zen`. Calamares 3.4.3.20260528-841b4785-dirty. Host: erik-virtualbox.

**Boot:** PASS — live ISO boots `7.0.10-1-cachyos` (cachyos = first in the space-separated `kernel=` list = live-boot per the [build-the-iso.sh:101](build-scripts/build-the-iso.sh) contract). XFCE desktop comes up clean, "Install kiro" launcher pre-trusted (the launcher-trust fix from earlier today held).

**Install:** PASS — Calamares completes end-to-end. `START CALAMARES` 07:20:53 → final `Saving files…` 07:24:50 = **~4 minutes total install**. Both kernels (`linux-cachyos` + `linux-zen`) + their `-headers` land in the target; both initramfs files generated; both systemd-boot loader entries written.

**Score: 117 PASS / 1 WARN / 0 FAIL** (`kiro-audit`). The WARN is the expected/intentional `multilib missing from pacman.conf`. **This validates today's kernel-agnostic kiro-audit work end-to-end on a kernel we had never tested with the audit before** — the previous lqx-hardcoded code would have produced 6 spurious FAILs on cachyos.

**Boot loader:** systemd-boot 260.1-2-arch, current entry `e6033dc5...-7.0.10-1-cachyos.conf`. Two entries on disk in `/boot/efi/loader/entries/` — cachyos (default, `sort-key=kiro`) + zen (selectable). Boot time: 14.066s total (kernel 6.745s + userspace 7.321s).

**Kernel-agnostic chain proven end-to-end:**
- Build side: [kiro-iso/build-scripts/build-the-iso.sh](build-scripts/build-the-iso.sh) `apply_kernel()` rewrote `packages.x86_64` + every boot loader template from a single `kernel=` variable.
- Install side: `kiro_kernel` Calamares module detected both kernels from the live medium, wrote slim `PRESETS=('default')` presets for each (NO fallback ever built — wins half the mkinitcpio time for free).
- Audit side: kernel-agnostic `kiro-audit` (today's change) validates whatever's installed via `/usr/lib/modules/*/pkgbase`.

### Findings

**[BUG, cosmetic] zen boot-loader entry has duplicated `rw root=UUID=…`**

The cachyos `.conf` cmdline is clean:
```
options    quiet nowatchdog rw root=UUID=021e749f-… systemd.machine_id=…
```
The zen `.conf` cmdline has `rw root=UUID=…` twice:
```
options    quiet nowatchdog rw root=UUID=021e749f-… rw root=UUID=021e749f-… systemd.machine_id=…
```
Root cause: `/etc/kernel/cmdline` on the installed system **itself** is duplicated (`quiet nowatchdog rw root=UUID=… rw root=UUID=…`). cachyos entry was generated first (clean cmdline) → clean entry; zen entry generated after the duplication → carries the dupes. So one of Calamares' modules is writing `/etc/kernel/cmdline` twice (appending instead of overwriting on the second pass) — likely `kiro_before` or `initcpiocfg` re-running. Boot-functional (kernel ignores duplicate params) but ugly and will compound on future kernel installs. **Fix candidate:** locate the second writer in `kiro-calamares-config`, switch from append to write-or-overwrite.

**[PERF] mkinitcpio ran FIVE times during install — 10 kernel builds total**

Search `==> Building image from preset` in `/var/log/Calamares.log` returns five passes:
1. ~07:23:?? — during `kiro_remove_nvidia` / `kiro_before` window (after `kiro_kernel` writes presets)
2. 07:24:08 — Calamares's own `Creating initramfs with mkinitcpio…` job (24/41), running `mkinitcpio -P`
3. 07:24:16 — triggered by `pacman -Rs --noconfirm mkinitcpio-archiso`
4. 07:24:26 — triggered by `kiro_ucode` (microcode reinstall)
5. ~07:24:35 — second pass after another microcode-related action

Each pass builds both kernels → 10 builds. The slim-preset win is already taken (every pass is `'default'` only, no fallback). The remaining churn is consolidation: defer mkinitcpio until the LAST preset/cmdline change, then run `mkinitcpio -P` once. Standard mechanism: symlink `/etc/pacman.d/hooks/90-mkinitcpio-install.hook` → `/dev/null` in the chroot during install, run it explicitly at the end. Estimated save: ~30-60s of a ~4min install.

**[PERF] microcode reinstall churns mkinitcpio twice on its own**

`kiro_ucode` triggers two mkinitcpio runs in the same job — `intel-ucode-20260512-1 is up to date -- reinstalling` followed by `warning: could not get file information for boot/intel-ucode.img`. Whatever `kiro_ucode` is doing (install correct ucode, remove wrong one) is firing the pacman mkinitcpio hook twice. Same fix as above resolves it.

**[INFO] /syscheck needs no updates**

Erik asked whether `/syscheck` needs updating. It does not — the spec at [~/.claude/commands/syscheck.md](file:///home/erik/.claude/commands/syscheck.md) has zero kernel-name hardcoding. Its kernel-related checks delegate to `journalctl -k` (kernel-agnostic) and `kiro-audit` (now kernel-agnostic). All 17 items work unchanged on cachyos/zen.

**[INFO] Calamares.log warnings — all known-benign**

`chcon` ×8 (no `chcon` on Kiro per `project_calamares_chcon_benign`), transient "EFI but no ESP" before partitioning, Qt UI warnings, `WARNING: Unknown GS key autoLoginUser` (Calamares config key it doesn't recognise — minor cleanup item, not a defect), `Possibly missing firmware for module: 'adf7242'/'softing_cs'` (obscure modules, standard Arch noise). Zero Python tracebacks, zero failed jobs.

**Failed systemd units after first boot:** zero.

**Pending updates at test time:** 0.

**Not tested this session (queued for next two machines):** bare-metal install (Erik will burn the ISO and test on two physical machines next), zen as the **default** (would need a second build with `kernel="linux-zen linux-cachyos"` reversed — current test boots zen only from the boot loader menu).

---

## 2026-05-28 — hardened-kernel live ISO (VirtualBox, UEFI) — launcher-trust focus

**Environment:** "Kiro" VirtualBox VM, UEFI. Live ISO built with `kernel="linux-hardened"`. Kernel `7.0.9-hardened1-1-hardened`.

**Boot:** PASS — live hardened kernel boots to the XFCE desktop; `kernels` reports `7.0.9-hardened1-1-hardened`. Validates the kernel-agnostic selector + `kiro_kernel` on the live side for a 4th kernel family.

**Launcher trust (session focus):**
- airootfs autostart approach found **broken** — helper shipped `644` (lost `+x` through the overlay), so the "Untrusted application launcher" prompt persisted.
- Reworked to a systemd **user** service shipped via the `calamares` package. Body **proven**: `systemctl --user start kiro-trust-launchers` → launcher trusted → Calamares launches, no prompt.
- Auto-fire did **not** happen unattended: service `enabled` but `inactive (dead)` — XFCE doesn't activate `graphical-session.target`. **Fix applied** (unit → `default.target`); **pending** verification on a rebuilt/republished calamares ISO.

**Not tested this session:** full Calamares install + `kiro-audit` (focus was launcher trust); hardened install-side (`kiro_kernel` copying `vmlinuz-linux-hardened` to the target) still to confirm.

---

## 2026-05-25 — v26.05.25 — the test box (bare metal, UEFI, Intel)

**Environment:** the test box — bare-metal Kiro on ASUS STRIX Z270H GAMING, Intel Core i7-7700K, Intel I219-V NIC (e1000e), UEFI/systemd-boot. Kernel `linux-lqx 7.0.10-lqx1-1-lqx`. Installed from the `v26.05.25` ISO (built Mon May 25 14:04 CEST).

**Boot:** PASS — UEFI boot via systemd-boot.
**Boot time:** 24.176s total (firmware 13.376s + loader 5.434s + kernel 1.655s + userspace 3.709s). Firmware POST dominates; Kiro's own userspace is 3.7s.

**Install:** Calamares bare-metal install completed. Post-install cleanup verified via `pacman.log`: `grub` removed (systemd-boot), VM-guest packages removed (`open-vm-tools`, `qemu-guest-agent`, `virtualbox-guest-utils`), live-only `kiro-calamares-config` removed, and `do-not-suspend.conf` removed on install (new `kiro_final` cleanup).

**Score: 110 PASS / 1 WARN / 0 FAIL** (`kiro-audit`). The single WARN is multilib intentionally disabled (re-enabled via one click in ATT — not a defect).

**Comprehensive retest — three audits run:**
- **`/syscheck`** — clean. NIC e1000e quiet (the `62-network-optimization.rules` fix from v26.05.24 is holding — no ethtool errors). 0 failed units. firewalld active + enabled (zone `public`). tuned active / power-profiles-daemon inactive, profile `balanced`. All 10 udev rules present. ZRAM 4G/zstd active. All 8 sysctl security baselines correct.
- **`/kiro-check`** — Source-to-installed integrity **CLEAN**. `10-archiso.conf` removed on install, all live-env survivors cleaned, no config drift, all 18 `edu-system-files` scripts present (under their current `kiro-` prefixed names).
- **`Calamares.log`** — no errors or tracebacks. Only benign warnings: `chcon` ×8 (upstream SELinux-distro noise, no `chcon` on Kiro), a transient "EFI but no ESP" before partitioning, and Qt/firmware cosmetics.

**Finding — cosmetic, not a defect:** hostname left at the install default `<user>-systemproductname` (DMI-derived `<username>-<product>`). Install-time choice, user-overridable with `hostnamectl set-hostname`; did not affect any subsystem (it did mean the chosen `.local` mDNS name didn't resolve until set).

**Pending updates at test time:** 0

---

## 2026-05-24 — v26.05.24 (kiro-next) — the test box (bare metal, UEFI, Intel)

**Environment:** the test box — bare-metal Kiro on ASUS STRIX Z270H GAMING, Intel Core i7-7700K, Intel I219-V NIC (e1000e), UEFI/systemd-boot. Kernel `linux-lqx 7.0.10-lqx1-1-lqx`. Installed from the `kiro-next-v26.05.24` ISO (built Sun May 24 12:45 CEST). Resume/swap config also cross-checked on a VirtualBox guest.

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
