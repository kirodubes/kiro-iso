# Distro Testing Log

Results of boot and install testing for kiro-iso builds. Newest first.

---

## 2026-06-09 — Production v26.06.09: new custom Calamares modules + WM editions — 4 installs, both firmware paths, 0 FAIL

Production `kiro-iso` **v26.06.09** (`ISO_BUILD` 20:58, ISO file 21:04) carrying the day's two big shipped changes: the **WM/desktop editions system** (`build-the-iso.sh` `apply_editions()` + `### >>> EDITION-BLOCK >>>` blocks in `packages.x86_64`, promoted from `-next`) and a **ground-up Calamares installer rewrite** in `kiro-calamares-config` — three new custom Python modules **`kiro_bootloader`** (974-line, replaces stock bootloader), **`kiro_displaymanager`** (1101-line, replaces stock displaymanager), and **`kiro_packages`** (832-line, replaces stock packages) — plus the production package-name fix in `kiro_packages.conf`/`kiro_final`. Validated across four installs covering **both firmware paths** and **both bootloader branches of the new `kiro_bootloader`**:

| Target | Firmware / bootloader | New modules ran | Result |
|--------|----------------------|-----------------|--------|
| VirtualBox VM (oracle) | UEFI / systemd-boot | `kiro_bootloader`/`kiro_displaymanager`/`kiro_packages` all ran; `Bootloader: systemd-boot` → SUCCESS | **kiro-audit 134 / 0 / 0** |
| **picard** (real metal, Intel HD630) | UEFI / systemd-boot | all three ran; systemd-boot branch → SUCCESS | **135 / 0 / 0**; install 3m21s |
| **riker** (real metal, i7-7700K, Intel HD630) | UEFI / systemd-boot | all three ran; systemd-boot branch → SUCCESS | **139 / 0 / 0**; install 4m21s |
| **worf** (real metal, MEDION P7624, Fermi GT 620M + Intel) | **BIOS / grub** | all three ran; **GRUB branch executed** — `Bootloader: grub (bios)` → `grub-install --target=i386-pc --recheck --force /dev/sda` → `grub-mkconfig -o /boot/grub/grub.cfg` → SUCCESS | **134 / 2 / 0**; install 5m58s |

- **New `kiro_bootloader` validated on BOTH branches:** systemd-boot (VM + picard + riker) and **GRUB/BIOS (worf)** — `grub-install i386-pc → /dev/sda` + `grub-mkconfig` both ran to SUCCESS on real BIOS metal. This was the decisive gap: the rewrite's GRUB branch had no v26.06.09 validation until worf.
- **New `kiro_displaymanager` + `kiro_packages`** ran on every target; package-removal cleanup correct (production names — `kiro-calamares-config`/`kiro-calamares-tweak-tool`/`calamares` removed, GRUB removed on systemd-boot).
- worf's 2 WARN are `NVIDIA Fermi present but nvidia-open-dkms / nvidia-utils not installed` — **expected/benign** (Fermi can't use the open driver; chwd correctly routes it to nouveau). `GRUB boot-safety hooks installed` PASS on the grub box.
- Install times recorded in [BUILD_TIMES.md](BUILD_TIMES.md) (picard 3m21s, riker 4m21s, worf 5m58s).

## 2026-06-08 — Production v26.06.08: GRUB boot-safety + spice-vdagent — 4 installs, both firmware paths, 0 FAIL

Production `kiro-iso` **v26.06.08** (built 15:13) carrying the day's two new features: **`kiro-bootloader-grub` 26.06-04** (self-healing GRUB — pacman hooks re-run `grub-install`/`grub-mkconfig` on grub/kernel updates), **`spice-vdagent` 0.23.0** (QEMU/SPICE host↔guest clipboard), the updated **`kiro-calamares-config`** (`kiro_final`: spice in the `qemu` cleanup profile + combined `kiro-bootloader-grub`+`grub` removal on systemd-boot), and **`kiro-system-files` 26.06-21** (new `kiro-audit` GRUB boot-safety check). Validated across four installs, both firmware paths:

| Target | Firmware | Result |
|--------|----------|--------|
| KVM VM (vda) | BIOS / grub | `kiro-bootloader-grub` kept; `kiro-grub-install -> /dev/vda`; both hooks fire on a `grub` reinstall; `spice-vdagent` kept |
| KVM VM | UEFI / systemd-boot | `grub` + `kiro-bootloader-grub` stripped together; `spice-vdagent` kept (kvm) |
| **worf** (real metal, MEDION P7624, SATA, Fermi GPU) | BIOS / grub | pkg + both helpers; `kiro-grub-install -> /dev/sda`; **kiro-audit: `PASS GRUB boot-safety hooks installed`** — 134 PASS / 2 WARN / 0 FAIL (the 2 WARN = NVIDIA Fermi on nouveau, expected) |
| **picard** (real metal, Intel HD630) | UEFI / systemd-boot | `grub` + `kiro-bootloader-grub` + `spice-vdagent` **all stripped**; **kiro-audit 135 / 0 / 0** |
| **riker** (real metal, Intel HD630) | UEFI / systemd-boot | identical to picard; **kiro-audit 135 / 0 / 0** |

- **Disk auto-detection** proven on `sda` (VirtualBox + worf) and `vda` (QEMU) — never the old hardcoded `/dev/sda`.
- **Removal correctness** confirmed in `Calamares.log`: on systemd-boot it logs *"systemd-boot detected. Removing GRUB"* (grub + hook pkg together); on bare metal *"Virtualization type: none"* strips all VM profiles (so spice-vdagent goes too); on kvm only vmware+vbox are stripped (spice-vdagent kept).
- **New `kiro-audit` check** shows `PASS GRUB boot-safety hooks installed` on a real grub system (worf) and stays correctly **silent** on systemd-boot — audit baseline clean (0 FAIL on every target).

## 2026-06-07 — Production ISO (19:40 rebuild): encrypted + line-3 chwd + new mirror-refresh — 139 PASS / 0 / 0

VM `Kiro-normal` (VirtualBox), installed from the **production `kiro-iso` 19:40 rebuild** (`ISO_BUILD` 19:40) carrying `kiro-calamares-config` **26.06-08**. That package (commit `97a2eb5`) newly brought the **entire chwd online mirror-refresh feature into production** (`_TRUSTED_MIRRORS` / `_ensure_cdn_first` / `_refresh_driver_mirrors` + greppable logging — 83-line add); the earlier 16:23 prod ISO / `26.06-07` had the nvidia fix but no mirror-refresh. The feature was first validated on `-next` (Kiro-E-jfs 390xx) and is here confirmed on production. Full-disk-encrypted layout, boot line 3 `driver=nonfreechwd`. One install exercised four things, all green:

| Target | Result |
|--------|--------|
| nvidia removal (line 3) | open stack removed (`nvidia-open-dkms nvidia-settings nvidia-utils`); post-install only `linux-firmware-nvidia` |
| mirrors update | `chwd: pacman -Sy … OK`; mirrorlists already CDN-led → left unchanged |
| chwd | `--autoconfigure` ran on `vboxvideo` (VM profile), install completed |
| encryption | 2× **LUKS2** — root `sda2`→ext4 + encrypted swap `sda3`; `aes-xts-plain64`/`argon2id`; `sd-encrypt` hook; `/crypto_keyfile.bin` 600 root:root; 2 active dm-crypt maps |
| **kiro-audit** | **139 PASS / 0 WARN / 0 FAIL** |

**New chwd logging validated** (`kiro-calamares-config-next`, this session) — the greppable block renders correctly in a real install:
```
chwd: ──────── mirror refresh ────────
chwd: cachyos-mirrorlist unchanged (already CDN-led or absent)
chwd: chaotic-mirrorlist unchanged (already CDN-led or absent)
chwd: pacman -Sy … OK
chwd: ─────────────────────────────────
```
The CDN-lead correctly reports `unchanged` because the ISO's mirrorlists already lead with the trusted CDN (baked by `host-prep.sh`), and `pacman -Sy … OK` shows the sync result. This is the production behaviour now (mirrored to `kiro-calamares-config` 26.06-08 via `97a2eb5`), validated here on a real install.

**Bare-metal confirmation on the 19:40 / `26.06-08` release ISO** (picard + riker reinstalled from it, both Intel HD 630):
| Box | Boot | nvidia outcome | kiro-audit |
|-----|------|----------------|------------|
| **picard** | line 1 `free` | open stack removed (chwd skipped); only `linux-firmware-nvidia` left | **136 PASS / 0 WARN / 0 FAIL** |
| **riker** | line 2 `nonfree` | baked `nvidia-open-dkms/settings/utils` **kept** (chwd + removal both skipped — correct for nonfree) | **134 PASS / 1 WARN / 0 FAIL** |

riker's single WARN is `nvidia-open-dkms installed but no NVIDIA GPU detected` — **expected/benign**: line 2 deliberately keeps the baked driver, and riker has only an Intel iGPU, so the audit correctly notes the driver is installed-but-unused (the mirror image of worf's line-3 `NVIDIA GPU present but nvidia-open-dkms not installed`). Together with the Kiro-normal encrypted line-3 install above, the 19:40 release ISO is now validated across **all three boot entries (free / nonfree / nonfreechwd) plus full-disk encryption**.

---

## 2026-06-07 — Release check: fresh full install from `kiro-v26.06.07` ISO — 134 PASS / 0 / 0

Ran `/kiro-ready` against the production `kiro-v26.06.07` ISO (built 16:29) and did a clean end-to-end install from the live medium into the `Kiro-normal` VirtualBox guest (UEFI/systemd-boot, unencrypted ext4 root). Installed-system `kiro-audit`: **134 PASS / 0 WARN / 0 FAIL** ("all checks passed") — same clean baseline as v26.06.06.

| Stage | Result |
|-------|--------|
| **Live-ISO** boot | clean (hostname `kiro`, `liveuser`) |
| **Installed** kiro-audit | **134 PASS / 0 WARN / 0 FAIL** |
| NVIDIA removal on non-NVIDIA HW | driver stack absent post-install (only `linux-firmware-nvidia` firmware remains); `kiro_remove_nvidia` ran, install completed |

**Honest scope note on today's `kiro_remove_nvidia` fix (`kiro-calamares-config@41d9388`):** this install does **NOT** exercise the fix. The normal ISO bakes in the **open** stack under its real package names (`nvidia-open-dkms` / `nvidia-utils` / `nvidia-settings`, `nvidia_driver=open`). On that ISO the old hardcoded-name code and the new discovery code behave identically — both find the three real names and remove them. The bug the fix addresses only triggers on a **390xx/580xx** ISO, where `nvidia-utils` is a *provide* (`nvidia-390xx-utils`) that `pacman -Q` matches but `pacman -Rns` does not. No 390xx/580xx ISO was built or shipped today (`kiro-Out/` holds only `kiro-v26.06.07-x86_64.iso`), so the fix's actual target path remains **untested** — but it is not in this release. The fix lives in the `kiro-calamares-config` *package*, not the `kiro-iso` repo; when a 390xx/580xx ISO is next built, confirm the package carrying `41d9388` is baked in and test that install path then.

**Other `/kiro-ready` gates:** 5 repos' committed code pushed (only doc/internal files uncommitted — `kiro-iso` BUILD_TIMES.md/RELEASES.md, `kiro-iso-next` CHANGELOG.md); no §1/§3 P1 TODO blockers; iso↔iso-next drift all intentional variant pairs (calamares/-next, config/-next, plymouth/-nemesis); production ISO (16:29) postdates latest non-doc commit (15:06); name-leakage scan **0 Tier-1 / 0 Tier-3** (only Tier-2/4 maintainer-script + doc hygiene); CHANGELOG documents the day's changes.

**Bare-metal confirmation — picard (real Intel HD 630, boot line 1 `driver=free`):** clean install from the same `v26.06.07` ISO (`ISO_BUILD` 16:23). `kiro-audit` **135 PASS / 0 WARN / 0 FAIL**. `Calamares.log` shows `kiro_remove_nvidia` running the **new** discovery code: `"Removing NVIDIA packages: nvidia-open-dkms nvidia-settings nvidia-utils"` → `pacman -Rns --noconfirm` removed the open stack in one transaction (~1 GB; dkms removed for both `7.0.11-1-cachyos` and `7.0.11-zen1-1-zen`). Post-install only `linux-firmware-nvidia` remains. Confirms the fixed module runs correctly on metal — but the open stack uses *real* names, so this still does not exercise the 390xx/580xx provide-resolution path.

**Bare-metal confirmation — riker (real Intel HD 630, boot line 1 `driver=free`):** same `v26.06.07` ISO, identical result — `kiro-audit` **135 PASS / 0 WARN / 0 FAIL**; `Calamares.log` shows `driver=free` → `"Removing NVIDIA packages: nvidia-open-dkms nvidia-settings nvidia-utils"` then `"Skipping chwd because 'driver=free'"`. Two independent metal boxes (picard + riker) now confirm the production open ISO.

**Bare-metal — worf (real NVIDIA Fermi GT 620M + Intel iGPU, boot line 3 `driver=nonfreechwd`):** installed from the **production open** `v26.06.07` ISO (confirmed: `390xx` appears **0×** in `Calamares.log`; baked stack removed was `nvidia-open-dkms nvidia-settings nvidia-utils`). `kiro_remove_nvidia` removed the open stack, then chwd ran and routed the Fermi card to **nouveau** (`> Successfully installed intel`; active `i915` + `nouveau`). `kiro-audit` **133 PASS / 2 WARN / 0 FAIL** — the 2 WARN (`NVIDIA GPU present but nvidia-open-dkms not installed`, `nvidia-utils not installed`) are **expected/benign** for a legacy-NVIDIA-on-nouveau box (open driver intentionally removed; Fermi can't use it). This validates the **line-3 nonfreechwd path + chwd nouveau routing on real NVIDIA hardware** — but it is the open stack under real names, so it still does **not** exercise the 390xx/580xx provide-resolution path. **Audit-refinement TODO:** kiro-audit should treat nouveau-on-legacy-NVIDIA as valid instead of warning.

**★ 390xx provide-resolution fix — PROVEN (the decisive test).** VM `Kiro-E-jfs`, installed from the **`kiro-next-v26.06.07`** ISO (`nvidia_driver=390xx`, `ISO_BUILD` 17:42), boot line 3 `driver=nonfreechwd`. `Calamares.log` shows `kiro_remove_nvidia` discovered the baked **390xx** stack by real name and removed it in one transaction:
```
"Removing NVIDIA packages: nvidia-390xx-dkms nvidia-390xx-settings nvidia-390xx-utils"
.. Running ("pacman","-Rns","--noconfirm","nvidia-390xx-dkms","nvidia-390xx-settings","nvidia-390xx-utils")
nvidia-390xx-dkms 390.157-21  -27.19 MiB ; nvidia-390xx-utils -106.63 MiB ; nvidia-390xx-settings -1.51 MiB  → removed
```
**Install completed** (`kiro_final` ran, no abort); post-install only `linux-firmware-nvidia` remains; **`kiro-audit` 134 PASS / 0 WARN / 0 FAIL**. This is exactly the case the old hardcoded code broke: `pacman -Q nvidia-utils` resolved the provide (`nvidia-390xx-utils`) but `pacman -Rns nvidia-utils` could not → `target not found` → `nvidia-remove-failed` → **install aborted**. The fix (`installed_nvidia_stack()` via `pacman -Qq`, removing real variant names) resolves it — confirmed end-to-end on a real 390xx install. (`kiro-calamares-config@41d9388` / `-next@a7bcd09`.) **580xx** variant is the analogous path (same code, same provide mechanism); validate similarly when a 580xx ISO is installed.

**Verdict:** production `v26.06.07` (normal/open ISO) verified release-ready by full install (VM + picard + riker metal + worf metal/line-3). Today's `kiro_remove_nvidia` install-blocking fix is **PROVEN** on the 390xx provide-resolution path (Kiro-E-jfs) — install no longer aborts on 390xx/580xx ISOs; the staleness gate for `41d9388` is cleared by this logged test. 580xx pending the same check.

---

## 2026-06-06 — Release GO: fresh full install from `kiro-v26.06.06` ISO — 134 PASS / 0 / 0

Ran `/kiro-ready` against the production `kiro-v26.06.06` ISO and did a clean end-to-end install from the live medium into a VirtualBox guest (UEFI/systemd-boot, unencrypted ext4 root). All release gates green → **GO, "you are ready to release."**

| Stage | Result |
|-------|--------|
| **Live-ISO** kiro-audit | 108 PASS / 6 WARN / **22 FAIL** — all expected live-medium state (kernels in squashfs, calamares present-to-install-from, ppd/tuned pins applied at install, archiso leftovers). Not blockers. |
| **Installed** kiro-audit | **134 PASS / 0 WARN / 0 FAIL** — "all checks passed". |
| Sysctl staleness verify | `/etc/sysctl.d/99-kiro-optimizations.conf` md5 `d6394931…` on the installed system is **byte-identical to `kiro-system-files@5cf21bf` HEAD** — confirms the 2026-06-06 sysctl reshuffle shipped and is tested, not stale. |

`/kiro-ready` full tally: 5 repos clean+pushed; no §1/§3 P1 TODO blockers; iso↔iso-next drift all intentional (`-next`/`-nemesis` package variants + a comment reflow in `partition.conf`); production ISO (built 08:13) postdates the latest non-doc commit (07:31, version-bump trio only); name-leakage scan **0 Tier-1/Tier-3** (only Tier-4 maintainer-script hygiene). `kiro-system-files 26.06-15` installed.

**Verdict:** production `v26.06.06` verified release-ready by full install. This supersedes the post-upgrade syscheck below as the stronger same-day evidence.

---

## 2026-06-06 — `kiro-system-files 26.06-15` post-upgrade syscheck on `Kiro-normal` VM — clean

Ran `/kiro-syscheck` against the `Kiro-normal` VirtualBox guest after upgrading **`kiro-system-files 26.06-14 → 26.06-15`** (`pacman -Syu`, hooks ran clean) on the freshly-installed v26.06.06 ISO (built same day 07:28, unencrypted ext4 root, systemd-boot/UEFI). The change is fully healthy — nothing in the journal, audit, or unit state traces back to it, and every artifact the package ships verified present and correct.

| Area | Result |
|------|--------|
| **kiro-audit** | **134 PASS / 0 WARN / 0 FAIL** ("all checks passed") |
| Failed units | 0 (`systemctl --failed` + audit) |
| Udev rules | all 10 present (60→68); IO schedulers correct |
| Systemd drop-ins | all 6 kiro drop-ins present (logind/system/journald/coredump/user/oomd) |
| Power | `ppd_base_profile=performance`, tuned active (`throughput-performance`), ppd inactive |
| Firewall | firewalld active+enabled, zone `public` |
| Printing | `cups.socket` enabled+active; `cups.service` inactive-until-triggered (correct) |
| Log rotation | `logrotate.timer` enabled+active |
| NIC | clean — zero ethtool/e1000e noise |
| CachyOS repo | `#[cachyos]` commented out (opt-in, as shipped) |
| Name leakage | **no Tier-1 leak** — `/etc/skel` and package-owned files clean; the only `/home/erik` hits are `.fehbg` + `/etc/passwd`, expected because this VM's user is literally named `erik` (the caveat case) |

Benign noise only, all pre-existing VM/live artifacts (not regressions from this change): `vboxsf 'tag'` / `vbg err -78` kernel lines, `pktsetup sr0` + `alsactl card0 exit 19` udev workers, `gkr-pam` keyring, Calamares `chcon`/EFI-no-ESP/`autoLoginUser` install-log warnings. One `sddm-helper crashed (exit 1)` appeared at the **reboot boundary** (SIGTERM, reboot.target queued) — transient, the current session logged in fine.

**Source state at test time:** `kiro-system-files` clean (matches deployed 26.06-15); `kiro-iso` only `M BUILD_TIMES.md` (internal build record, not a deploy gap); `kiro-calamares-config` clean.

**Verdict:** `kiro-system-files 26.06-15` verified clean on VM. Note: `/etc/os-release` reads stock "Arch Linux" by design (Kiro builds on Arch, keeps the Arch identity/logo) — not a branding gap.

---

## 2026-06-04 — Production ISO: three install modes (unencrypted / LUKS-ext4 / LUKS-btrfs) all PASS on VM

Tested the new **production** `kiro-iso` across three VirtualBox guests in parallel, covering the disk-layout matrix Calamares offers. All three booted into the installed system and pass `kiro-audit` clean (0 WARN / 0 FAIL):

| VM | Disk layout | Root unlock | kiro-audit |
|----|-------------|-------------|------------|
| `Kiro-normal`  | unencrypted, `sda2` → ext4 root | n/a | **132 PASS / 0 / 0** |
| `Kiro-E-ext4`  | LUKS: `sda2` → `crypto_LUKS` → ext4 root | passphrase | **132 PASS / 0 / 0** |
| `Kiro-E-btrfs` | LUKS: `sda2` → `crypto_LUKS` → btrfs root (subvols incl. `/.snapshots`, `/var/cache`); **separate encrypted swap** on `sda3` → `crypto_LUKS` → swap | passphrase | **133 PASS / 0 / 0** |
| `Kiro-E-xfs`   | LUKS: `sda2` → `crypto_LUKS` → xfs root; **separate encrypted swap** on `sda3` → `crypto_LUKS` → swap | passphrase | **133 PASS / 0 / 0** |
| `Kiro-E-jfs`   | LUKS: `sda2` → `crypto_LUKS` → jfs root (zram swap only) | passphrase | **132 PASS / 0 / 0** |

(The five baseline counts above are pre-`check_disk_format`; with that section added the same installs read 133/137/139/138/137 — see the follow-up note below.)

Notes:
- **LUKS version: LUKS2** on every encrypted container (both VMs, root **and** swap), confirmed via `cryptsetup luksDump`. Cipher `aes-xts-plain64`, 512-bit key, PBKDF **argon2id** (1 GiB memory cost) — modern Calamares defaults, not legacy LUKS1/PBKDF2.
- The btrfs-encrypted install lays down **two LUKS2 containers** — one for the btrfs root, a separate one for swap — both unlock and mount correctly. The `/.snapshots` subvolume is present (Calamares pre-stages the Kiro btrfs layout); snapshot stack remains opt-in via ATT (audit PASS, expected default).
- The btrfs run audits at **133** vs 132 for the two ext4 runs — the +1 is the two btrfs-specific checks (`/.snapshots` mounted + snapshot-stack-opt-in) replacing the single "root is ext4, not btrfs" check.
- No encryption-specific failures: no boot-time unlock errors, no failed units, package integrity intact on all three.

**Verdict:** encrypted (ext4 + btrfs) and unencrypted production installs all verified on VM.

**Follow-up shipped same day:** `kiro-audit` gained a `check_disk_format` section (kiro-system-files) that now asserts the encryption directly — LUKS2 per container, `sd-encrypt`/`encrypt` initramfs hook, `/crypto_keyfile.bin` 600 root:root, active dm-crypt mapping — plus INFO lines reporting the chosen root fstype/cipher. `kiro-report` got a matching `section_encryption` (root fs · LUKS2/N-containers · encrypted-swap yes/no), redaction-safe. Re-verified live on **all five VMs** with the new section: normal-ext4 133, LUKS-ext4 137, LUKS-btrfs 139, LUKS-xfs 138, LUKS-jfs 137 — all 0 WARN / 0 FAIL. Both checks read the root fstype generically, so xfs and jfs work with no fs-specific code. `/kiro-syscheck` inherits the asserts via its existing kiro-audit call.

**Bare-metal confirmation (two real machines, same v26.06.04 ISO):**
- **picard** — tested across two reinstalls, both **0 WARN / 0 FAIL**, "all checks passed":
  - unencrypted ext4 → **134 PASS** (`check_disk_format` reports `ext4 (unencrypted)`);
  - reinstalled btrfs-encrypted (LUKS2 root + separate encrypted swap) → **148 PASS** (LUKS2 ×2, `sd-encrypt` hook, keyfile 600, 2 dm-crypt mappings; snapshot stack opt-in installed & passing). kiro-report: `btrfs · LUKS2 (2 containers) · encrypted swap yes`, 0 UUID leaks.
- **riker** (`192.168.1.14`, **encrypted** ext4-on-LUKS2 + separate encrypted swap, 2 containers) — **139 PASS / 0 WARN / 0 FAIL**, "all checks passed". On real hardware the encryption asserts all pass (LUKS2 ×2, `sd-encrypt` hook, `/crypto_keyfile.bin` 600 root:root, 2 active dm-crypt mappings); kiro-report shows `ext4 · LUKS2 (2 containers) · encrypted swap yes` with 0 raw UUIDs after redaction.

This **closes the bare-metal encrypted gap** — full-disk LUKS is now verified on real hardware, not just in VMs. No VM-artifact caveat on either box. Encrypted layouts now proven across ext4/btrfs/xfs/jfs (VM) plus encrypted-ext4 on metal (riker).

---

## 2026-05-31 — 3-mode NVIDIA driver: `nonfree` (UEFI) + `nonfreechwd` (BIOS) installs verified on VM; real-NVIDIA conflict case still pending

After the staleness clearance below was written, two functional changes shipped on 2026-05-31:
the **3-mode NVIDIA driver** (`free` / `nonfree` / `nonfreechwd` — boot-menu entries plus the
`kiro_remove_nvidia` + `chwd` gating in kiro-calamares-config) and the **kiro-skell split**
(edu-system-files; a user maintenance command, not boot/install logic).

Per-path status of the NVIDIA modes:

- **`driver=free`** (strip NVIDIA → mesa, open stack) — proven (2026-05-28 bare-metal baseline).
- **`driver=nonfree`** (keep the baked `nvidia-open-dkms`, no chwd) — proven on real modern NVIDIA hardware,
  and **VM install PASS (UEFI/systemd-boot, 2026-05-31).** `kiro_remove_nvidia` logged "Keeping NVIDIA packages
  … (baked nvidia-open-dkms)" → SKIPPED; `chwd` logged "Skipping chwd because 'driver=nonfree'". nvidia kept,
  chwd not run — exactly as designed.
- **`driver=nonfreechwd`** (chwd `--autoconfigure`) — **VM install PASS (logic verified).** First test on a
  VirtualBox guest, new ISO (UUID `2026-05-31-13-03-36`), "NVIDIA proprietary, auto-detect" entry; the
  updated `kiro-calamares-config` modules were confirmed baked in. From `/root/.cache/calamares/session.log`:
  `kiro_remove_nvidia` fired on `nonfreechwd` → `pacman -Rns --noconfirm nvidia-open-dkms nvidia-utils
  nvidia-settings` removed them (-131.99 MiB) → `Remove NVIDIA packages: SUCCESS`; then `chwd
  --autoconfigure` ran (`Start chwd` → `End chwd`, no `chwd-failed`/conflict). Confirms the remove-then-chwd
  clean-slate ordering works. **Still pending:** the NVIDIA *card* conflict case (chwd → `nvidia-open-dkms`
  on a modern card, or → `470xx`/`390xx` on an older one) — a VM routes to the `virtualbox` profile, so no
  NVIDIA driver was installed; worf (Fermi) can only route to nouveau, never exercise this. Needs a real
  modern/mid NVIDIA box.

**Unrelated finding (not a blocker) — installed default kernel differs by firmware path:** the
**UEFI/systemd-boot** install defaults to **linux-cachyos** (correct, matches policy); the **BIOS/GRUB**
install defaults to **linux-zen** (booted system reported `7.0.10-zen1-1-zen`). cachyos should be the
post-install default on both — GRUB-path-only ordering issue, tracked for a post-launch fix. Both kernels
install and boot fine; this is a default-selection nit, not a failure.

**Verdict:** the 3-mode gating is **verified on VM** — `nonfree` (UEFI: nvidia kept, chwd skipped) and
`nonfreechwd` (BIOS: nvidia removed, chwd ran clean), with `free` per the 2026-05-28 baseline. **The one
remaining open verification** is chwd's proprietary NVIDIA install on real hardware (modern card →
`nvidia-open-dkms`, older → `470xx`/`390xx`) — a VM can't exercise it and worf (Fermi) can't either.

---

## 2026-05-31 — v26.05.31 staleness clearance — no functional changes since 2026-05-28 test

All commits to `kiro-iso`, `kiro-calamares-config`, and `edu-system-files` since the 2026-05-28 bare-metal test (128 PASS / 0 WARN / 0 FAIL) are cosmetic only: trailing newline fixes on efiboot entries and `services-systemd.conf`, plus the version bump to `v26.05.31`. No shipped config, package list, or installer logic changed. The 2026-05-28 test result stands as the functional baseline for this release.

**Verdict:** test result carries forward — staleness cleared for v26.05.31 release.

---

## 2026-05-29 — chwd NVIDIA routing on worf (nonfree path) — **PARTIAL: routing PASS, `nvidia-open-dkms` path untested** — real metal (Optimus laptop, UEFI)

**Environment:** Test install on **worf** (`erik-p7624`), an Optimus laptop — Intel HD (2nd-gen) iGPU + NVIDIA **GF108M / GeForce GT 620M** (Fermi, PCI `10de:0de9`). Booted with the **non-free** GRUB entry (`driver=nonfree`). Transcribed into the test log from the `bdca88b` findings so the chwd integration shipping in production has a logged test (was previously only in the kiro-iso CHANGELOG).

**chwd routing — PASS.** Calamares log confirms `Kernel parameter 'driver' = nonfree` → `chwd --autoconfigure`, which made the right per-device calls: `intel` for the iGPU and **`nouveau` for the GT 620M**. chwd's device DB classifies that Fermi card as nouveau (not 390xx), so it never attempted a proprietary driver — pulled `nouveau-fw` + mesa/opencl and finished cleanly. Installed system runs Intel `i915` + Xorg `modesetting`; display healthy.

**Patched chwd shipped — PASS (by inspection).** Installed box carries **`chwd 1.21.0-4`** (our patched build); `/var/lib/chwd/db/pci/graphic_drivers/profiles.toml` shows the patched `[nvidia-open-dkms]` block (`nvidia-open-dkms` + per-kernel `-headers`, old `${kernel}-nvidia-open` prebuilt logic gone). `linux-cachyos-nvidia-open` not installed.

**KNOWN GAP — `nvidia-open-dkms` proprietary path NOT exercised.** worf's Fermi card routed to nouveau, so the `nvidia-open-dkms` profile never fired. The modern-NVIDIA + nonfree scenario (chwd selects `nvidia-open-dkms`, DKMS **builds** not just `added`, `nvidia-smi` works, no `linux-cachyos-nvidia-open`) is confirmed present/correct in config but **never run end-to-end**. Needs a box with a modern NVIDIA GPU that chwd routes to that profile. **Open at launch — documented limitation; install is non-fatal (nouveau fallback), and `nvidia-open-dkms` is known to build on 7.0 kernels.**

**KNOWN DEAD — `nvidia-390xx` (390.157) cannot build on the 7.0 kernel.** Manual DKMS build fails `nvidia/os-interface.c:1136: error: 'screen_info' undeclared` (removed from modern kernels); the EOL 390 branch is non-viable. For Fermi-class cards, **nouveau is the only working driver** — which is what chwd picks. The `nvidia_driver=390xx` ISO option + chwd `nvidia-dkms-390xx` profile are effectively dead; `470xx` likely the same (verify). A card routed there gets a driverless (non-fatal) system. See MASTER_TODO §1.

**Verdict:** chwd integration itself is sound and tested for the nouveau/Intel cases. The proprietary `nvidia-open-dkms` install is shipped-but-unverified — a known, documented launch limitation, not a brick risk.

---

## 2026-05-28 — cachyos+zen, **first bare-metal install, all-green** — real metal (UEFI, Intel desktop + Samsung 860 EVO SSD)

**Environment:** Live ISO `v26.05.28` booted on a bare-metal Intel desktop (UEFI/systemd-boot, Samsung 860 EVO 250GB). Install monitored over SSH from the dev box after `kiro-enable-ssh` on the live session. The Calamares cleanup wave from the morning's VM session carried over cleanly — no `qemu-guest-agent` or `virtualbox-guest-utils` left over after the chroot cleanup.

**Boot + install:** PASS end-to-end. Reboot into `linux-cachyos 7.0.10` is clean; SDDM + XFCE come up; sshd off by default on the installed system (correct).

**Score: 128 PASS / 0 WARN / 0 FAIL** (`kiro-audit`) — **first-ever zero-WARN result**. The long-standing `multilib missing` WARN was removed earlier today (multilib intentionally out of scope for Kiro), so this is the first audit that runs entirely silent. Coverage now includes the full Garuda-imports surface: oomd drop-ins (system + user slice), mei/mei_me blacklist, `btusb reset=1`, zswap disabled, NM `unmanaged-lo`, sysctl baseline (8 values), resolved mDNS off (avahi owns mDNS), key-file permissions, cgroup delegation, ananicy-cpp, firewalld, logrotate.timer, ZRAM 4G zstd, all 10 udev rules.

**Boot time (kiro-audit info):** firmware 13.6s + loader 5.4s + kernel 2.1s + userspace 4.0s = **25.2s total**. Firmware dominates on bare metal as expected (vs ~1s on a VM).

**Failed units: 0. NIC noise: 0. Calamares Python tracebacks: 0.** Only first-boot baseline noise: `alsactl restore` exit 19 on card0/card1 (no saved state yet — normal on a freshly-installed system), `bluetoothd` hci0 default-config, `gkr-pam: unable to locate daemon control file` (well-known SDDM/gnome-keyring cosmetic).

**Fixes from earlier sessions that held on bare metal:**
- Cmdline-dedup ([kiro-calamares-config](../kiro-calamares-config) `8195c9f`) — bootloader audit clean, no duplicate `rw root=UUID=`.
- `cups.socket` enabled by Calamares (2026-05-26 fix) — socket active, service inactive-until-triggered as designed.
- `logrotate.timer` enabled by Calamares (2026-05-26) — file-based log rotation persists across reboot.
- `firewalld` default-on (2026-05-25 ufw→firewalld swap) — `active`+`enabled`, zone `public`.
- `linux-cachyos` boot default, `linux-zen` fallback — both kernels installed, both initramfs files generated, both systemd-boot loader entries written.
- `kiro-enable-ssh` flow: `pacman -Sy` + openssh reinstall + firewalld rule add (firewalld correctly logged `ALREADY_ENABLED: ssh` since the rule was already present in the default zone).

**Post-install actions performed during the session:**
- `pacman -Syu` picked up `archlinux-tweak-tool-gtk4-git 368→370` + `exfatprogs 1.4.0→1.4.1`. 1 pending update remains.
- `kiro-enable-ssh` to make the installed system reachable for follow-up syscheck.

**Hardware quirks (informational only, none actionable):** SGX disabled in BIOS; MDS / MMIO Stale Data / VMSCAPE SMT mitigation advisories at boot (standard Intel/SMT); Samsung 860 EVO kernel ATA quirks auto-applied (`noncqtrim`, `zeroaftertrim`, `noncqonati`, `nolpmonati`); `intel_pmc_core` BAR-overlap notice (common Intel platform-driver chatter).

**Verdict:** Bare-metal milestone unlocked. The 2026-05-28 cachyos+zen ISO is now proven on both VirtualBox and real Intel desktop hardware, with a strictly cleaner audit than every prior VM run. The "two physical machines to test next" item from the prior entry is now half-cleared — one more bare-metal pass would close it.

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
