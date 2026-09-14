# Distro Testing Log

Results of boot and install testing for kiro-iso builds. Newest first.

> **Test machines** are recorded under generic labels — `metal-A` / `metal-B` (bare metal, UEFI / systemd-boot), `metal-C` (bare metal, BIOS / grub, legacy NVIDIA), `kvm-vm` and `<vm-host>` (virtual machines). Real hostnames and network addresses are deliberately not recorded in this repo; use the same labels for new entries.

---

## 2026-09-14 — v26.09.14, **`linux-lts` + `linux-zen`**, UEFI / systemd-boot: the sort-key mechanism's hardest case, **kiro-audit 132 / 0 / 0**

Full (unstripped) v26.09.14 image (`ISO_BUILD` 06:44:01, 6.3 GB, 1508 packages on the ISO),
installed in the VirtualBox VM on **ext4, unencrypted**, **UEFI / systemd-boot**. 1461 packages
on the installed system. Install finished 07:00:23 (`Remove installation files: SUCCESS`),
Calamares 3.4.3.20260822-841b4785.

**Unlike the v26.09.12 and v26.09.13 runs, this is NOT a stripped test build.** The build tree's
`package-selection.conf` was not applied, so all 1508 packages shipped — this image is
release-shaped and directly comparable to what v26.10.01 will be, which the 1118-package
TIER 3 runs were not.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE) | ext4, unencrypted | UEFI / systemd-boot | Clean install; **kiro-audit 132 PASS / 0 WARN / 0 FAIL**, zero failed units |

### The boot-ordering mechanism, tested where version-sort must lose

Every previous ordering run put the primary kernel first in a field where plain version sort
*might* have produced the same answer by luck. This pairing removes that luck:

```
linux-lts   6.18.51-1        <- primary (booted live), sort-key kiro-0, (default) (selected)
linux-zen   7.2.4.zen2-1     <- secondary,             sort-key kiro-1
```

The secondary kernel's version is **more than a full major release higher** than the primary's.
Any version-derived ordering — including Arch's stock `90-loaderentry`, which builds the sort-key
from the version — puts `7.2.4-zen2` above `6.18.51-lts`. systemd-boot nevertheless offers
`Arch Linux (6.18.51-1-lts)` as **(default) (selected)**, and the machine booted `6.18.51-1-lts`.

The full chain is verifiable on the installed system:

```
/etc/kiro/primary-kernel                     -> linux-lts          (written from the booted live kernel)
/etc/kernel/install.d/95-kiro-sort-key.install -> rewrites sort-key: kiro-0 primary, kiro-1 rest
bootctl list                                  -> kiro-0 = lts (default), kiro-1 = zen
uname -r                                      -> 6.18.51-1-lts
```

So `95-kiro-sort-key.install` is doing real, falsifiable work here: remove it and systemd-boot
would default to zen. This is the UEFI/systemd-boot counterpart to the `grub_move_to_front`
proofs logged for BIOS/GRUB on 2026-09-13.

### Microcode: still no `/boot/*-ucode.img`, still correct

`/boot` holds only the two `vmlinuz-*` and their initramfs. Both ucode packages are installed
(`amd-ucode 20260910-1`, `intel-ucode 20260812-1`) and the `microcode` mkinitcpio hook embeds
them in the early CPIO. Reads like a regression on every fresh-install audit; it is not.

The Calamares offline ucode bundles were verified on both sides for this build —
`/etc/calamares/packages/` on the ISO ships `amd-ucode-20260910-1` and `intel-ucode-20260812-1`,
matching `git ls-files` in kiro-calamares-config and the installed package versions. The §1 P1
staleness gate is satisfied for this image.

### Install-time cleanup clean

`/etc/calamares` is absent and `kiro-calamares-config` is no longer installed on the target —
`kiro_final` removed both as designed.

### Caveats

- One failed unit exists on the **live** ISO only (`systemd-loop@…sr0.service`), the VirtualBox
  CD-ROM loopback artifact. The installed system has zero failed units.
- VM install, so chwd/NVIDIA paths are the no-GPU branches.
- This run validates the `linux-lts` + `linux-zen` pairing. Production `build.conf.defaults`
  remains `linux linux-lts`; the local `build.conf` was realigned to that pairing after this run.

---

## 2026-09-13 — v26.09.13 rebuild, **`linux-xanmod-lts` + `linux-xanmod-x64v3`**, BIOS / GRUB: first **same-family** pairing, first XanMod install, **kiro-check 0 problems**

Fifth run of the day. Rebuilt v26.09.13 image (`ISO_BUILD` 08:42:53, 4.62 GB, 1118 packages) with
`kernel="linux-xanmod-lts linux-xanmod-x64v3"`, installed in the same BIOS VirtualBox VM on
**ext4, unencrypted** — directly comparable to the other runs of the day. Build took ~7 min
(08:42 → 08:49). `build.conf.defaults` was left at `linux linux-lts`, so this was a local-only
override; production defaults untouched.

**This is a stripped test build.** The build tree's `package-selection.conf` excludes **115
TIER 3 packages** (the kiro-iso-builder GUI profile) — the whole PRINTING & SCANNING and
BLUETOOTH groups, plus most optional apps. The canonical repo's copy of that file is **empty**
(ship everything), so a release build is a different, larger image. v26.09.12 was stripped the
same way, which is why the two are comparable to each other but neither is comparable to a
release ISO. 4.62 GB / 1118 packages is a figure for the stripped profile, not for v26.10.01.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE) | ext4, unencrypted | BIOS / GRUB | Clean install; **kiro-check 0 problems / 3 warnings**, zero failed units |

Booted `6.18.51-xanmod1-2-lts`. Both kernels come from **chaotic-aur**
(`linux-xanmod-lts 6.18.51-2`, `linux-xanmod-x64v3 7.2.5-1`), so they stay updatable on the
installed system the same way the cachyos pairing did.

### Two firsts for XanMod

Every previous pairing mixed two kernel *families* (lts+zen, lts+cachyos). This is the first run
where **both entries come from the same family**, and the first XanMod install on any path.

```
grub.cfg menu:
  kiro Linux
  Advanced options for kiro Linux
    kiro Linux, with Linux linux-xanmod-lts      <- lts FIRST
    kiro Linux, with Linux linux-xanmod-x64v3
uname -r: 6.18.51-xanmod1-2-lts
cmdline:  BOOT_IMAGE=/boot/vmlinuz-linux-xanmod-lts root=UUID=… rw quiet nowatchdog
          splash loglevel=3 audit=0 nvme_load=yes
```

Falsifiable exactly like the zen and cachyos pairings: x64v3 `7.2.5` beats lts `6.18.51` on
`version_sort -r`, so lts leading is `grub_move_to_front` doing real work — this time
discriminating between two filenames that differ only by suffix (`vmlinuz-linux-xanmod-lts` vs
`vmlinuz-linux-xanmod-x64v3`), the closest pair the ordering machinery has been given. Both
`vmlinuz-*` images and both `/etc/mkinitcpio.d/*.preset` files are present and correct.

### DKMS is the real result

The open question going in was whether out-of-tree modules would build against XanMod headers,
since the `-headers` packages install to a different path than the vanilla ones DKMS usually sees.
They do, for both kernels, on both the live ISO and the installed system:

```
live ISO:   broadcom-wl/6.30.223.271  6.18.51-xanmod1-2-lts   installed
            broadcom-wl/6.30.223.271  7.2.5-xanmod1-1-x64v3   installed
            nvidia/615.71.09          6.18.51-xanmod1-2-lts   installed
            nvidia/615.71.09          7.2.5-xanmod1-1-x64v3   installed

installed:  broadcom-wl only — nvidia correctly dropped (VM has no NVIDIA GPU)
```

### Microcode: no `/boot/*-ucode.img`, and that is correct

`/boot` holds only the two `vmlinuz-*`, the two `initramfs-*` and `grub/` — no
`intel-ucode.img`/`amd-ucode.img`, and `grub.cfg` carries no ucode `initrd` line, despite both
packages being installed. `HOOKS=(systemd autodetect microcode kms …)` means the **`microcode`
hook embeds it in the initramfs early-CPIO** (640 KiB, mkinitcpio 42, zstd). Not a regression;
worth stating because it reads like one on every fresh-install audit.

### kiro-check: source-to-VM integrity CLEAN

Install-time cleanup proven by `Remove installation files: SUCCESS` at 08:53:40 in
`Calamares.log`, with every live-env survivor gone (`10-archiso.conf`, `do-not-suspend.conf`,
`getty@tty1` autologin, `49-nopasswd_global.rules`, `sudoers.d/g_wheel`, archiso mkinitcpio
hooks). The two 0750 dirs were read under `sudo`, not absence-tested. Sysctl 11/11, udev 10/10,
24 `kiro-*` scripts + the `skell` symlink, no orphan man pages, no duplicate config in
`sysctl.d`/`system.conf.d`. All three source repos clean in git.

Three non-blocking warnings, none XanMod-related and none new:

- `cups-permissions.conf` errors twice per boot — the `cups` group does not exist, so the tmpfiles
  rule cannot apply. **This is an artifact of the stripped profile, not a source defect:** `cups`,
  `cups-filters` and `cups-pdf` are present and uncommented in `packages.x86_64` (PRINTING &
  SCANNING group) and the canonical `package-selection.conf` excludes nothing — the GUI profile
  used for this build drops them. A release build ships cups and the rule goes silent. Nothing to
  fix; expect this warning on every stripped test build.
- `/usr/local/bin/slstatus` is unowned — suckless `make install` from ohmychadwm landing outside
  pacman's file list.
- `vboxvideo: vbva_enable failed` / `hgsmi_get_mode_hints failed: -5` at early boot, on both live
  and installed. The driver binds anyway and mode-setting works (2560x1600 offered, auto-resize
  functional). **Not established whether XanMod introduced this** — it would need a side-by-side
  boot of the 07:28 `linux-lts linux-cachyos` image to tell.

**Not captured:** `kiro-audit` score and `systemd-analyze` boot timing — the VM was powered off
before those ran, so this entry has no comparable `133 / 0 / 0` figure.

---

## 2026-09-13 — v26.09.13 rebuild, **`linux-lts` + `linux-cachyos`**, BIOS / GRUB: cachyos on the GRUB path for the first time, **kiro-audit 133 / 0 / 0**

Fourth run of the day. Rebuilt v26.09.13 image (`ISO_BUILD` 07:28:52) with
`kernel="linux-lts linux-cachyos"`, installed in the same BIOS VirtualBox VM on **ext4,
unencrypted** — so the score is directly comparable to the first run of the day.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE) | ext4, unencrypted | BIOS / GRUB 2:2.14-1 | Clean install; **kiro-audit 133 / 0 / 0**, zero failed units |

Booted `6.18.51-1-lts`; boot 15.691s (1.408s kernel + 7.800s initrd + 6.482s userspace).
`133 / 0 / 0` is **identical to the `linux-lts linux-zen` ext4 run**, which is the expected result —
the kernel pairing changes nothing the audit counts.

### Two firsts for `linux-cachyos`

The only previous cachyos install was UEFI / systemd-boot, and its entry carries a scope caveat:
that pairing was the **identity case**, with `CANONICAL_KERNEL=linux-cachyos` equal to the primary,
so it could not show that the machinery discriminates. This run breaks both limits — cachyos is on
the **GRUB path for the first time**, and it is the **fallback rather than the primary**.

```
/etc/default/grub:  GRUB_TOP_LEVEL="/boot/vmlinuz-linux-lts"
/etc/kiro/primary-kernel:  linux-lts

grub.cfg menu:
  kiro Linux
  Advanced options for kiro Linux
    kiro Linux, with Linux linux-lts        <- lts FIRST
    kiro Linux, with Linux linux-cachyos
uname -r: 6.18.51-1-lts
```

Falsifiable in the same way as the zen pairing — cachyos `7.2.4` beats lts `6.18.51` on
`version_sort -r`, so lts leading is `grub_move_to_front` doing real work, this time on a kernel
filename (`vmlinuz-linux-cachyos`) the GRUB path had never seen. Both `vmlinuz-*` images and both
`/etc/mkinitcpio.d/*.preset` files are present and correct.

### The repo question: cachyos kernels stay updatable — via chaotic-aur, not cachyos

Going in, the concern was that installing a cachyos kernel would strand it: `[cachyos]` is commented
out on an installed system by default, so the kernel would have no update path. **Measured, the
concern does not materialise, but not for the reason expected:**

```
/etc/pacman.conf:106  [chaotic-aur]     <- enabled
/etc/pacman.conf:109  #[cachyos]        <- commented out, as designed

pacman -Si linux-cachyos
  Repository : chaotic-aur
  Version    : 7.2.4-1                  <- same version as installed
```

`chaotic-aur` carries `linux-cachyos` at the same version, so the installed kernel resolves and
updates normally with the cachyos repo left disabled. **Offering `linux-cachyos` as a kernel choice
does not require enabling `[cachyos]` post-install.** Worth recording explicitly, because the
opposite assumption is the natural one to make from the commented-out block.

### Noted, not attributed: initrd 7.800s

Initrd is up from 2.809s on the morning's ext4 run, with no encryption in play. It is **not**
attributable to the kernel pairing: both initramfs images are 18M, `HOOKS` is the standard
unencrypted line, and `systemd-analyze blame` puts 4.586s of it in `initrd-switch-root.service`
alone — host I/O contention on a machine that had been building ISOs throughout the session.
Single-sample VM timing; recorded so a future comparison does not read it as a regression.

### Feature status

| Behaviour | Status |
|---|---|
| `GRUB_TOP_LEVEL` reordering | proven against zen, under cryptodisk, with the snapshot stack, **and now against cachyos** |
| Primary ≠ canonical kernel (non-identity case) | **proven here on the GRUB path** |
| `linux-cachyos` update path with `[cachyos]` disabled | **proven — served by chaotic-aur** |
| Full-package ISO health, ext4 | 133 / 0 / 0, reproduced across two kernel pairings |

---

## 2026-09-13 — v26.09.13 encrypted btrfs + **snapshot stack opted in**: **kiro-audit 146 / 0 / 0**, and Kiro ships no `grub-btrfs`

Third run on the same **v26.09.13** image and the same encrypted-btrfs VM as the entry below, with
the one remaining variable flipped: the snapshot stack opted in through **ATT > Btrfs**. Nothing
else changed — same BIOS VM, same `kernel="linux-lts linux-zen"`, same LUKS2 container.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE) | btrfs on LUKS2, **snapshot stack installed** | BIOS / GRUB 2:2.14-1 | **kiro-audit 146 / 0 / 0**, zero failed units |

`snapper 0.13.1-3`, `snap-pac 3.0.1-3`, plus `btrfs-assistant` and `btrfsmaintenance`. ATT took a
baseline snapshot on opt-in (`#1 single … "ATT baseline"`). **+8 checks over the 138 of the default
encrypted install**, landing exactly on the 146-class score the previous entry predicted.

### The prediction that was wrong: there is no `grub-btrfs`

The previous entry closed by calling this "the first time `grub-btrfs` snapshot boot entries would
meet the `GRUB_TOP_LEVEL` reordering — the one interaction in this series that has never been
observed." **That interaction does not exist.** Kiro's snapshot stack is defined in
`archlinux-tweak-tool/btrfs.py` as

```python
PACKAGES = ("snapper", "snap-pac", "btrfs-assistant", "btrfsmaintenance")
```

`grub-btrfs` is deliberately not in it, `kiro-audit` never looks for it, and `grub-btrfsd.service`
comes back `not-found`. Measured on the installed system: **`grub.cfg` contains zero snapshot
entries**, and the boot menu is unchanged from the run before the opt-in —

```
kiro Linux
Advanced options for kiro Linux
  kiro Linux, with Linux linux-lts     <- lts still first
  kiro Linux, with Linux linux-zen
```

So snapshots on Kiro are a **rollback tool, not a boot-menu feature**. Nothing the snapshot stack
does can perturb `GRUB_TOP_LEVEL` ordering, because it never writes boot entries at all. That is a
stronger guarantee than the test was designed to look for, and it closes the question rather than
leaving it open.

### Kiro's snapshot policy, as the audit states it

```
PASS  TIMELINE_CREATE=no (Kiro policy — snapshots on pacman actions only)
PASS  snapper-timeline.timer not enabled (Kiro policy)
PASS  snapper-cleanup.timer enabled
PASS  btrfsmaintenance-refresh.path enabled (scrub · balance · trim)
PASS  snapper root config present (/etc/snapper/configs/root)
```

Snapshots are taken by `snap-pac` on pacman transactions; there is no hourly timeline. Cleanup and
btrfs maintenance are both live. Worth knowing before reading a future audit: **`snapper-timeline.timer`
showing `disabled` is a PASS, not a finding.**

### Score ladder for the v26.09.13 image

| Configuration | Score | What the delta is |
|---|---|---|
| ext4, unencrypted | 133 / 0 / 0 | baseline |
| btrfs on LUKS2, default | 138 / 0 / 0 | +5 encryption + layout checks |
| btrfs on LUKS2 + snapshot stack | **146 / 0 / 0** | +8 snapper / maintenance checks |

All three are the same ISO on the same VM, and each step changed exactly one thing. The ladder is
the useful artefact: **a Kiro audit score is only interpretable against its install configuration**,
and 146 is the ceiling for the full opt-in path.

### Feature status

| Behaviour | Status |
|---|---|
| Full-package ISO health — ext4 / encrypted / encrypted+snapshots | proven at 133 / 138 / **146**, all 0 FAIL |
| `GRUB_TOP_LEVEL` reordering | proven on ext4, under cryptodisk, **and with the snapshot stack live** |
| GRUB unlocking LUKS with `/boot` inside the container | proven (entry below) |
| Snapshot stack | **proven here — and shown not to touch the boot menu** |
| `grub-btrfs` snapshot boot entries | **not applicable — Kiro does not ship `grub-btrfs`** |

---

## 2026-09-13 — v26.09.13 full package set, **encrypted btrfs / BIOS / GRUB**: **kiro-audit 138 / 0 / 0**, GRUB unlocks LUKS and still reorders

Second run on the same **v26.09.13** image (full TIER 3 set, 1508 packages, 6.69 GB), same
VirtualBox VM still on `firmware="BIOS"`, same `kernel="linux-lts linux-zen"`. The only variables
changed against the ext4 run above are **filesystem and encryption** — deliberately, so the score
delta is attributable.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE) | **btrfs on LUKS2**, full-disk encryption | **BIOS / GRUB 2:2.14-1** | Clean install; **kiro-audit 138 / 0 / 0**, zero failed units |

Booted `6.18.51-1-lts`; boot 15.171s (1.662s kernel + **6.624s initrd** + 6.884s userspace).
Initrd is up from 2.809s on the ext4 run — that delta is the LUKS unlock, and it is the whole of
the regression in boot time. Root is `compress=zstd:3,space_cache=v2` on subvolume `@`, with the
Kiro layout pre-staged: `@ @home @root @srv @cache @log @tmp @snapshots`.

### The result that matters: `/boot` lives *inside* the LUKS container

`findmnt /boot` returns nothing — there is no separate boot partition. The kernels GRUB must
enumerate are inside the encrypted volume, so GRUB has to unlock LUKS itself before it can read a
kernel list at all:

```
/etc/default/grub:  GRUB_ENABLE_CRYPTODISK=y
/boot/grub/grub.cfg: cryptomount ×5
lsblk: sda1 crypto_LUKS -> luks-d475… (btrfs)
```

And the ordering work still holds on the far side of that unlock:

```
/etc/default/grub:  GRUB_TOP_LEVEL="/boot/vmlinuz-linux-lts"
/etc/kiro/primary-kernel:  linux-lts

grub.cfg menu:
  kiro Linux                            <- top-level entry
  Advanced options for kiro Linux       <- submenu
    kiro Linux, with Linux linux-lts    <- lts FIRST
    kiro Linux, with Linux linux-zen
uname -r: 6.18.51-1-lts
```

Same falsifiable pairing as before — zen `7.2.4.zen2` would win `version_sort -r` against lts
`6.18.51` — and lts still leads. `grub_move_to_front` is unaffected by cryptodisk.

Encryption checks all clean: LUKS2, `sd-encrypt` present in a `systemd`-based `HOOKS` line,
`/crypto_keyfile.bin` at `600 root:root`, one active dm-crypt mapping.

### 138, not 146 — the snapshot stack is opt-in

The prediction going in was that btrfs + LUKS would add roughly 13 checks and land near the
**146 / 0 / 0** of the 2026-08-25 run. It added **5**, for 138. The reason is visible in the audit
output itself:

```
PASS  /.snapshots subvolume mounted (Kiro layout pre-staged by Calamares)
PASS  Snapshot stack not installed — opt-in via ATT > Btrfs (expected default)
```

Calamares pre-stages the `@snapshots` subvolume, but `snapper`, `snap-pac` and `grub-btrfs` are
**not installed by default** — they are an opt-in from ATT. So a default encrypted-btrfs install
exercises the LUKS and layout checks but not the snapshot stack, and 138 is the correct ceiling for
it. The 08-25 run reached 146 because that stack was present. **These two numbers are not
comparable, and neither is a regression against the other.**

### Correction to the earlier "UEFI / GRUB" framing

The 08-25 entry is logged as `UEFI / GRUB`. That combination is no longer reachable:
`efiBootLoader: "systemd-boot"` is hardcoded in `kiro_bootloader.conf`, so a UEFI install always
takes the systemd-boot branch and the GRUB path runs only when `fw_type != "efi"`. **BIOS is now
the only way to exercise GRUB at all** — including GRUB-on-LUKS, as here. Any future plan that says
"UEFI + GRUB" needs rewriting as "BIOS + GRUB" or "UEFI + systemd-boot".

### Feature status

| Behaviour | Status |
|---|---|
| Full-package ISO health, ext4 | proven — 133 / 0 / 0 |
| Full-package ISO health, encrypted btrfs | **proven here — 138 / 0 / 0** |
| `GRUB_TOP_LEVEL` reordering | proven on ext4 and **now under cryptodisk** |
| GRUB unlocking LUKS with `/boot` inside the container | **proven here** |
| `netdev_budget_usecs` fix | proven (earlier runs) |
| Snapshot stack (snapper / snap-pac / grub-btrfs) | **still unexercised — opt-in via ATT > Btrfs** |

### Next

The snapshot stack is the remaining gap, and this install is the right host for it: opt in via
**ATT > Btrfs** on this same encrypted-btrfs system and re-audit. That should be the run that
reaches the 146-class score.

> **Followed up the same day — see the entry above.** It reached 146 / 0 / 0. This paragraph
> originally also predicted the run would be "the first time `grub-btrfs` snapshot boot entries
> would meet the `GRUB_TOP_LEVEL` reordering"; that was wrong. Kiro does not ship `grub-btrfs`, so
> no such interaction exists. Corrected here so the prediction is not read as a standing gap.

---

## 2026-09-13 — v26.09.13 lts+zen, **full package set**, BIOS / GRUB: first **kiro-audit 133 / 0 / 0**

First ISO of the day, and the first **built with the complete package set** — the
`package-selection.conf` exclusion list left empty, so the whole TIER 3 set shipped.
**1508 packages, 6.69 GB**, against the 4.44 GB of the previous day's lean KIB test images.
Built through KIB with `kernel="linux-lts linux-zen"`, installed in a VirtualBox VM still on
`firmware="BIOS"`, booting live **entry 1 (`linux-lts`, the primary)**.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE) | ext4, unencrypted | **BIOS / GRUB 2:2.14-1** | Clean install; **kiro-audit 133 / 0 / 0**, zero failed units |

Booted `6.18.51-1-lts`; boot 15.987s (1.724s kernel + 2.809s initrd + 11.453s userspace),
`graphical.target` at 11.411s. Root `/dev/sda1` ext4 on a 48.8 GB disk, 8 GB zram swap.
Carries `kiro-system-files 26.09-02`.

### The clean sweep — and what it proves about the earlier FAILs

Every prior run carried a residue of 3 FAIL / 4 WARN, consistently attributed to the
xfce-only edition selection: `ananicy-cpp` ×2, Bluetooth `AutoEnable`, `firewalld`, `tuned`.
That attribution was plausible but never tested, because every one of those runs was a lean
build with the apps deselected for speed.

This run removes the variable. With the full TIER 3 set shipped, **all five findings are gone
and the audit reports 133 PASS / 0 WARN / 0 FAIL.** The residue was a build-profile artifact
of the test images, not a defect in the distro. Worth stating plainly for future readers:
**a lean test ISO cannot produce a clean audit, and its FAILs should never be read as
regressions.** Only a full-package build is a valid input to a health verdict.

### Boot order — `GRUB_TOP_LEVEL` reordering holds on the full image

```
/etc/default/grub:  GRUB_TOP_LEVEL="/boot/vmlinuz-linux-lts"
/etc/kiro/primary-kernel:  linux-lts

grub.cfg menu:
  kiro Linux                            <- top-level entry
  Advanced options for kiro Linux       <- submenu
    kiro Linux, with Linux linux-lts    <- lts FIRST
    kiro Linux, with Linux linux-zen
uname -r: 6.18.51-1-lts
```

Same falsifiable pairing as the 09-12 run: `10_linux` sorts with `version_sort -r`, so zen
`7.2.4.zen2` would precede lts `6.18.51` on version order alone. lts leads regardless, at the
top level and inside the submenu — `grub_move_to_front` is unaffected by the larger package set.

### `netdev_budget_usecs` — still correct

`systemd-sysctl.service` **active**, `systemctl --failed` empty, and
`/proc/sys/net/core/netdev_budget_usecs` at the kernel default **6666** — the shipped
`-net.core.netdev_budget_usecs = 2000` key continues to no-op cleanly on `CONFIG_HZ=300` lts.

### Feature status

| Behaviour | Status |
|---|---|
| `apply_kernel()` fallback retarget | proven (earlier runs) |
| Primary = the kernel actually booted | proven both ways (earlier runs) |
| systemd-boot sort-key ordering | proven (earlier runs) |
| `GRUB_TOP_LEVEL` written, surviving, reordering | proven on BIOS — **re-confirmed here on the full image** |
| `netdev_budget_usecs` fix | proven on live medium and installed system |
| Full-package ISO health | **proven here — 133 / 0 / 0** |

> `kiro-audit` closes with its standing note that it targets bare metal and that VM artifacts
> may appear. On this run nothing appeared to discount.

---

## 2026-09-12 — v26.09.12 lts+zen, **BIOS / GRUB**: `GRUB_TOP_LEVEL` reordering proven, sysctl fix confirmed in a real install

Seventh and final run of the day. Rebuilt ISO (`kernel="linux-lts linux-zen"`) carrying
**`kiro-system-files 26.09-02`** — the first image with both the sort-key plugin *and* the
`netdev_budget_usecs` fix. Installed in a VirtualBox VM switched to `firmware="BIOS"`, booting live
**entry 1 (`linux-lts`, the primary)**.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE) | ext4, unencrypted | **BIOS / GRUB 2:2.14-1** | Clean install; **kiro-audit 124 / 4 / 3**, zero failed units |

Booted `6.18.51-1-lts`; boot 12.581s (1.494s kernel + 6.169s initrd + 4.918s userspace).

### `GRUB_TOP_LEVEL` actually reorders — the gap the 09-12 BIOS run left open

```
/etc/default/grub:  GRUB_TOP_LEVEL="/boot/vmlinuz-linux-lts"
/etc/kiro/primary-kernel:  linux-lts

grub.cfg menu:
  kiro Linux                            <- entry 0, set default="0"
  kiro Linux, with Linux linux-lts      <- submenu, lts FIRST
  kiro Linux, with Linux linux-zen
uname -r: 6.18.51-1-lts
```

`10_linux` builds its list with `version_sort -r`, descending, so **zen `7.2.4.zen2` would precede
lts `6.18.51` on version order alone**. lts appears first instead, both as the top-level entry and
inside the submenu — `grub_move_to_front` did its job. The earlier BIOS run (zen primary) could only
show that `GRUB_TOP_LEVEL` was written and survived; it could not show any effect, because zen won
the version sort anyway. This run separates the two.

Note for future readers: **GRUB's top-level entry is titled plainly `kiro Linux` with no kernel name**,
so the boot menu itself cannot tell you which kernel won. `uname -r`, the submenu order, or
`grub.cfg` are the readouts.

### The `netdev_budget_usecs` fix, confirmed twice

- **On the live medium, before installing.** The live session is itself `CONFIG_HZ=300` lts running
  `kiro-system-files 26.09-02`: `systemd-sysctl.service` **active**, `systemctl --failed` empty, and
  `/proc/sys/net/core/netdev_budget_usecs` left at the kernel default 6666.
- **On the installed system.** Same result, and **`kiro-audit` is back to 3 FAIL** from the 4 seen on
  the unfixed lts install — the `1 failed systemd unit(s)` entry is gone.

The shipped key now reads `-net.core.netdev_budget_usecs = 2000`.

The remaining 3 FAIL / 4 WARN are the familiar package absences from the xfce-only edition selection
(`ananicy-cpp` ×2, Bluetooth AutoEnable, `firewalld`, `tuned`), unrelated to any of this work.

### Feature status after seven runs

| Behaviour | Status |
|---|---|
| `apply_kernel()` fallback retarget | proven across three pairings, incl. the reverse-collision case |
| Primary = the kernel actually booted | proven **both ways** — entry 1 → lts, entry 4 → zen |
| systemd-boot sort-key ordering | proven against version order (lts `kiro-0`, `(default)`) |
| `GRUB_TOP_LEVEL` written and surviving | proven on BIOS |
| `GRUB_TOP_LEVEL` reordering | **proven here** |
| `netdev_budget_usecs` fix | proven on live medium and installed system |

### Methodological note worth keeping

Four of the seven runs produced a *correct-looking* result that proved nothing, because the primary
kernel also happened to win the version tiebreak. **A boot-order test is only meaningful when the
intended winner would lose on version order** — here, making `linux-lts` the primary against
`linux-zen`. The same applies to package delivery: three runs were compromised or nearly so by an
ISO shipping a stale `kiro-system-files`, so checking the version in the ISO's `.pkglist.txt` before
installing is now a standing precondition rather than an afterthought.

---

## 2026-09-12 — v26.09.12 lts+zen ISO, **fallback entry booted**: primary follows the booted kernel

Sixth run of the day, on the **same ISO** as the entry below (`kernel="linux-lts linux-zen"`), but
booting live **entry 4 — the fallback, `linux-zen`** — instead of entry 1. This is the first test of
the design decision behind the feature: the installed default follows the kernel the user actually
booted, not the ISO's build-time primary. Someone who picks the fallback because the primary will
not run on their hardware must not be handed a system that defaults back to it.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE) | ext4, unencrypted | UEFI / systemd-boot | Clean install; **kiro-audit 123 / 4 / 3**, zero failed units |

Booted `7.2.4-zen2-1-zen`; boot 16.042s (2.249s kernel + 6.154s initrd + 7.638s userspace).

### The result, and why it is discriminating

```
/etc/kiro/primary-kernel:  linux-zen

title: Arch Linux (7.2.4-zen2-1-zen)  sort-key: kiro-0  (default) (selected)
title: Arch Linux (6.18.51-1-lts)     sort-key: kiro-1
```

Three candidate implementations predict different answers here, and only one matches:

| If the primary were taken from… | would give |
|---|---|
| the ISO's build-time first kernel | `linux-lts` |
| the old alphabetical `names[0]` (`sorted(glob(...))`) | `linux-lts` |
| **the kernel actually booted** | **`linux-zen`** ✓ |

**The menu order alone settles it**, because the previous entry established the control: on the very
same ISO, booting entry 1 produced `linux-lts` at `kiro-0` and lts **first despite its lower
version**. Had the primary been the build-time kernel or the alphabetical one, lts would have
topped the menu again here. It did not — the sort-keys are exactly inverted. Two runs off one ISO,
differing only in which live entry was chosen, producing opposite and correct orderings.

Both mkinitcpio presets are Calamares-generated, `95-kiro-sort-key.install` is present, and
`kiro-system-files 26.09-01` is installed.

### Incidental corroboration of the `netdev_budget_usecs` diagnosis

The entry below recorded `systemd-sysctl.service` failing on that ISO, diagnosed as
`net.core.netdev_budget_usecs = 2000` falling below linux-lts's `CONFIG_HZ=300` floor of 6666us.

**This run has zero failed units and one fewer audit FAIL (3, not 4)** — same ISO, same
`kiro-system-files 26.09-01` without the fix, the only difference being that the booted kernel is
`linux-zen` at `CONFIG_HZ=1000`, where 2000us is exactly on the floor and accepted. The failure
appearing and disappearing purely with the booted kernel is independent confirmation that the cause
is the HZ-derived floor and nothing else.

The remaining 3 FAIL / 4 WARN are the familiar package absences from the xfce-only edition
selection (`ananicy-cpp`, Bluetooth AutoEnable, `firewalld`, `tuned`).

### Still open

- **GRUB half, discriminatingly** — a BIOS install with **lts** as the booted primary would show
  whether `GRUB_TOP_LEVEL` actually reorders. Needs the VM's firmware set to BIOS; UEFI always takes
  the systemd-boot branch because `efiBootLoader: "systemd-boot"` is hardcoded.
- Re-test once `kiro-system-files` is rebuilt with the `-net.core.netdev_budget_usecs` fix.

---

## 2026-09-12 — v26.09.12 **`linux-lts` + `linux-zen`**, UEFI install: sort-key plugin proven, and a latent linux-lts sysctl bug found

Fifth run of the day, on a KIB-built ISO (file 18:55, 4.44 GB) with `kernel="linux-lts linux-zen"`.
**The first pairing whose primary loses the version tiebreak** — `linux-lts 6.18.51` sorts below
`linux-zen 7.2.4.zen2` — which is what finally made the result falsifiable. The three earlier runs
all had a primary that would have won on version order anyway, so "primary boots first" proved
nothing in any of them.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE) | ext4, unencrypted | UEFI / systemd-boot | Clean install; **kiro-audit 122 / 4 / 4** (see below) |

Booted `6.18.51-1-lts`, 1068 packages, boot 12.155s (1.173s kernel + 4.508s initrd + 6.474s
userspace). Live boot entry 1 was used, so the primary kernel is what Calamares saw.

### The delivery gate, checked first this time

`kiro-system-files` **26.09-01** is on the ISO — the version carrying
`etc/kernel/install.d/95-kiro-sort-key.install`. The previous ISO shipped 26.08-04 because the
build's pacman sync beat the GitHub Pages republish, which produced a meaningless result. Checking
the `.pkglist.txt` before installing is now the standing precondition for this test.

### `apply_kernel()` — third distinct shape, correct

Read out of the ISO before booting: `01-archiso-linux.conf`, `02`, `02b`, `03` →
`vmlinuz-linux-lts`; `04-fallback.conf` → `vmlinuz-linux-zen`; `default 01-archiso-linux.conf`;
both kernels and both initramfs present. This is the exact inverse of the previous build's mapping,
which is the strongest evidence so far that the retarget is genuinely computed rather than
coincidentally right.

### Sort-key plugin — proven, and not by luck

```
title: Arch Linux (6.18.51-1-lts)      sort-key: kiro-0   (default) (selected)
title: Arch Linux (7.2.4-zen2-1-zen)   sort-key: kiro-1

.../4496…-6.18.51-1-lts.conf:sort-key   kiro-0
.../4496…-7.2.4-zen2-1-zen.conf:sort-key   kiro-1
loader.conf: default 4496…*            (unchanged glob)
```

**lts carries the lower version and still wins.** With `loader.conf` still holding the plain
`<machine-id>*` glob, the only thing that can put lts first is the sort-key — confirming both that
the plugin ran and that the glob resolves to the first entry in sort order. The full chain is
exercised: package ships the plugin → `kiro_kernel` writes `/etc/kiro/primary-kernel` (`linux-lts`)
→ `kernel-install` invokes the plugin → systemd-boot honours the result. Both mkinitcpio presets
are Calamares-generated.

### Found: `net.core.netdev_budget_usecs = 2000` fails `systemd-sysctl` on linux-lts

One failed unit — `systemd-sysctl.service`, *"Couldn't write '2000' to
'net/core/netdev_budget_usecs': Invalid argument"* — and the fourth `kiro-audit` FAIL is that unit.

The kernel enforces a floor of 2 jiffies, `2 * (1000000 / CONFIG_HZ)`. linux-zen and linux-cachyos
ship `CONFIG_HZ=1000`, giving a 2000us floor that our value sits exactly on; **linux-lts ships
`CONFIG_HZ=300`, so the floor is 6666us** and 2000 is rejected. Boundary probed on the running
kernel rather than inferred: 1000 / 2000 / 4000 rejected, 8000 / 10000 / 20000 accepted.

Every earlier install test booted a 7.2.4 HZ=1000 kernel, which is why four clean runs never saw
it — **the upcoming October `linux linux-lts` pairing would have shipped it**. Impact was limited:
`systemd-sysctl` continues past a rejected key, so `netdev_budget`, `vm.swappiness` and
`netdev_max_backlog` all applied; the cost was a permanently failed unit.

Fixed the same day in `kiro-system-files` by prefixing the key with `-` (skip on failure),
verified on this very install: unit `active`, `systemctl --failed` empty, other keys still applied.
**Needs a `kiro-system-files` rebuild to reach an ISO.**

### The other three audit FAIL/WARN are package absence

`ananicy-cpp` (2 FAIL), Bluetooth AutoEnable, `firewalld`, `tuned` — all absent from the ISO
because only the **xfce** edition was ticked on the KIB Editions screen, which also explains the
1068-package count against the morning's 1510. Not a regression.

### Still open

- **GRUB half, discriminatingly.** A BIOS install off this same ISO would show whether
  `GRUB_TOP_LEVEL` actually reorders: lts should become the top-level `menuentry 'kiro Linux'`
  despite zen sorting higher. The 09-12 BIOS run proved the value is written and survives, but its
  pairing could not prove the reordering had any effect.
- Re-test once `kiro-system-files` is rebuilt with the sysctl fix.

---

## 2026-09-12 — v26.09.12 zen+lts, **BIOS / GRUB** install: `GRUB_TOP_LEVEL` verified, menu order not yet discriminating

Same ISO as the entry below (`ISO_BUILD` Sat Sep 12 13:48:23 CEST 2026, file 13:55), installed a
second time in a **BIOS** VirtualBox VM to reach the GRUB path. `efiBootLoader: "systemd-boot"` is
hardcoded in `kiro_bootloader.conf`, so UEFI always takes the systemd-boot branch and GRUB runs only
when `fw_type != "efi"` — a BIOS install is the only way to exercise it, and it needs no rebuild.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE/ohmychadwm) | ext4, unencrypted | **BIOS / GRUB 2:2.14-1** | Clean install; **kiro-audit 124 / 4 / 3** (same package-absence set as the UEFI run) |

- Booted `7.2.4-zen2-1-zen`. 1072 packages, **zero failed units**, boot 11.294s
  (759ms kernel + 5.678s initrd + 4.856s userspace).
- `[core] [extra] [nemesis_repo] [chaotic-aur]` active.

### What the GRUB path showed

- **`/etc/default/grub` carries `GRUB_TOP_LEVEL="/boot/vmlinuz-linux-zen"` and it survives.** On the
  UEFI run the same line was written (proved in `Calamares.log`) and then removed — `kiro_final`
  deletes the GRUB package set, `/boot/grub` and every `/etc/default/grub*` when systemd-boot is in
  use. On BIOS it persists, which is the half UEFI could not show.
- `grub 2:2.14-1` is installed and **owns** `/etc/default/grub`, so writing that file can never
  leave an unowned file for a later `pacman -S grub` to collide with.
- `/etc/kiro/primary-kernel` reads `linux-zen` here too.
- `grub.cfg`: `set default="0"` (line 31), and entry 0 is the single top-level
  `menuentry 'kiro Linux'` (line 131) that `10_linux` builds from the first kernel in its list.

### Two corrections to what was previously written about this path

The `kiro-calamares-config` CHANGELOG originally reasoned from `grubcfg.conf`'s
`GRUB_DEFAULT: "saved"` and `GRUB_DISABLE_SUBMENU: true`. **Neither reaches the installed system.**
`/etc/default/grub` is owned by the `grub` package and `grubcfg` runs with `overwrite: false`, so
the installed copy keeps `GRUB_DEFAULT=0` and has no `GRUB_DISABLE_SUBMENU` at all:

- the default comes from a literal `set default="0"`, not from a `saved_entry` fallback — a more
  direct chain than the one described, and `grubenv` holds no `saved_entry`;
- a submenu **is** generated ("Advanced options for kiro Linux", line 148) holding both kernels. It
  does not affect which entry is 0.

Worth noting separately, and unrelated to the kernel work: **`grubcfg.conf`'s `defaults:` block is
largely inert on Kiro** for that same `overwrite: false` reason.

### Why "zen is first" is still not proof

`10_linux` sorts its kernel list with `version_sort -r`, descending. `7.2.4.zen2` beats `6.18.51`,
so **zen tops the menu with or without `GRUB_TOP_LEVEL`** — the same version-luck trap the UEFI run
hit on the systemd-boot side. This run proves the code executes, writes the correct value and
survives to the installed system; it does not prove the reordering has any effect.

**The discriminating test is a pairing whose primary loses the version sort** — build
`kernel="linux-lts linux-zen"` (lts primary) and confirm `menuentry 'kiro Linux'` is still built
from **lts** despite zen sorting higher. One line in `build.conf`.

### Still open

- The **sort-key plugin** (`kiro-system-files 26.09-01`) remains untested; it needs a
  UEFI/systemd-boot system, and the UEFI VM from the previous entry no longer exists.
- The same `linux-lts linux-zen` build would make **both** halves discriminating at once: lts as
  primary loses the version tiebreak under GRUB *and* under systemd-boot, so either mechanism
  working becomes visible rather than coincidental.

---

## 2026-09-12 — v26.09.12 KIB rebuild, `linux-zen` + `linux-lts`: the fallback retarget proven, sort-key plugin missed the ISO

Fourth run of the day, on a **KIB-built `v26.09.12` ISO** (ISO file 13:55, 4.44 GB, 1118 packages),
built with `kernel="linux-zen linux-lts"`. This is the pairing the previous entry called for: unlike
`linux-cachyos linux-zen` it is **not** the identity case, so `apply_kernel()` actually has work to do.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE/ohmychadwm) | ext4, unencrypted | UEFI / **systemd-boot** | Clean install; **kiro-audit 123 / 4 / 3** (see below — all package-absence, unrelated) |

### `c42c4cd` proven: the reverse-collision case

This is the first build where `PRIMARY_KERNEL` equals `CANONICAL_FALLBACK` (`linux-zen`). The
primary rewrite is a file-wide `s/linux-cachyos/linux-zen/g`, so afterwards the **main** menu
entries carry the very token the fallback rewrite keys on. Confining the fallback `sed` to the
`KIRO_FALLBACK_BEGIN/END` marker range is what stops it clobbering them — and that is exactly what
happened, verified by extracting the boot config from the ISO itself:

- `01-archiso-linux.conf`, `02-nvidianouveau.conf`, `02b-nvidiachwd.conf`, `03-nomodeset.conf`
  → `vmlinuz-linux-zen` (primary, untouched by the fallback pass)
- `04-fallback.conf` → `vmlinuz-linux-lts`, titled "fallback kernel linux-lts"
- syslinux `KIRO_FALLBACK` block → `LABEL arch_fallback`, `vmlinuz-linux-lts`
- all four images present: `vmlinuz-linux-{zen,lts}` + `initramfs-linux-{zen,lts}.img`

The 09-12 cachyos+zen run could not show this: there both tokens were already correct and Phase 9
rewrote nothing.

### The new default-kernel work — two thirds verified

- **`booted_kernel_package()` end to end.** The live session booted `7.2.4-zen2-1-zen`;
  `/usr/lib/modules/7.2.4-zen2-1-zen/pkgbase` reads `linux-zen`; the installed system's
  **`/etc/kiro/primary-kernel` reads `linux-zen`**. This is the mechanism the whole feature rests
  on, confirmed on a real live medium rather than on the workstation.
- **`set_grub_top_level()` fires with the right value.** From `/var/log/Calamares.log`:
  `[PYTHON JOB]: "Setting GRUB_TOP_LEVEL=\"/boot/vmlinuz-linux-zen\" in .../etc/default/grub"`.
- **`/etc/default/grub` is absent on the installed system, and that is correct.** `kiro_final`
  removes the GRUB package set, `/boot/grub` and every `/etc/default/grub*` file when
  `boot/efi/loader/loader.conf` shows systemd-boot is in use. So the file is written and then
  deliberately swept up. It also settles the "could this leave an unowned file for a later
  `pacman -S grub` to collide with" question in both directions: on systemd-boot nothing survives,
  and on a GRUB install the `grub` package owns the file.
- Both presets are Calamares-generated (`# ... generated by Calamares (kiro_kernel)`) and both
  kernels have an initramfs.

### The sort-key half was NOT tested — and would have looked like a pass

The ISO shipped **`kiro-system-files 26.08-04`**, not the `26.09-01` built at 13:46 carrying
`95-kiro-sort-key.install`. `/etc/kernel/install.d/` on the installed system is empty.
`kiro-calamares-config 26.09-03` *did* make it, which is why the two items above are real.

Cause: `nemesis_repo` is pulled from `https://erikdubois.github.io/nemesis_repo/$arch`, and the
build's pacman sync beat the GitHub Pages republish. The published DB was serving `26.09-01` when
checked shortly afterwards, so nothing was wrong with the package or the push — only the timing.

**The result is a false pass, which is the point worth recording.** With no plugin, both entries
keep `sort-key: kiro` and the tie falls to the version string — `7.2.4-zen2-1-zen` sorts above
`6.18.51-1-lts`, so zen came out `(default)` and the system booted zen. That is the intended
outcome arrived at by the old accident, and reading it as success would have been wrong. A rebuild
carrying `kiro-system-files 26.09-01` is still required; check the ISO's `.pkglist.txt` for the
version before trusting the next run.

### kiro-audit 123 / 4 / 3 — package absence, not regression

```
FAIL  ananicy-cpp not installed
FAIL  ananicy-cpp.service not enabled
WARN  firewalld not installed / firewalld.service not enabled
WARN  bluetooth not enabled
WARN  tuned-adm not found; cannot verify active profile
```

`ananicy-cpp`, `firewalld`, `tuned` and `bluez` are **absent from the ISO while being listed in
`build-scripts/package-selection.conf`**, and account for much of the 392-package gap against the
morning's 1510-package build. None of it touches the kernel work. Worth a separate look: if the
lighter set was chosen on the KIB Packages screen this is expected, and if it was not, the
selection file was not honoured.

### Still open

- **GRUB path end to end.** `efiBootLoader: "systemd-boot"` is hardcoded in `kiro_bootloader.conf`,
  so UEFI always takes the systemd-boot branch; GRUB runs only when `fw_type != "efi"`. A **BIOS**
  install off this same ISO covers it with no rebuild — expect `GRUB_TOP_LEVEL` to survive, zen
  first in `grub.cfg` (no submenu, `GRUB_DISABLE_SUBMENU: true`) and zen booted by default.
- **sort-key ordering**, once an ISO carries `kiro-system-files 26.09-01`.

---

## 2026-09-12 — v26.09.12 KIB rebuild, `linux-cachyos` + `linux-zen`: VirtualBox install — kiro-audit 132 / 0 / 0

Third run of the day, on a **KIB-built `v26.09.12` ISO** (`ISO_BUILD` Sat Sep 12 12:41:47 CEST 2026,
ISO file 12:50, 6.23 GB, 1510 packages). Purpose: exercise a **non-default kernel pairing** —
`kernel="linux-cachyos linux-zen"` instead of the shipped `linux linux-lts` — to answer whether a
user who wants the old kernels back, or a completely different pair, gets a working ISO and a
working install.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE/ohmychadwm) | **ext4**, unencrypted, ESP vfat at `/boot/efi` | UEFI / **systemd-boot 261.3** | Clean install; **kiro-audit 132 / 0 / 0** |

**Scope caveat — this pairing is the identity case for `c42c4cd`.** `CANONICAL_KERNEL=linux-cachyos`
and `CANONICAL_FALLBACK=linux-zen`, so `apply_kernel()` skipped the primary rewrite *and* took the
"already targets linux-zen — no rewrite needed" branch. Phase 9 rewrote **zero boot entries**; the
only file it touched was `packages.x86_64`. The run therefore validates the **as-shipped** boot tree
and the two-kernel install path, **not** the fallback-retarget logic. A pairing such as
`linux-zen linux-lts` is still needed to exercise that.

**ISO verified from the image itself** (`bsdtar` extraction, before any boot):
- `arch/boot/x86_64/` carries **both** `vmlinuz-linux-cachyos` + `vmlinuz-linux-zen` and **both**
  `initramfs-*.img` — a fallback entry pointing at a missing initramfs would have been silent.
- `loader.conf` → `default 01-archiso-linux.conf`; entries `01`, `02`, `02b`, `03` all reference
  `linux-cachyos` (the primary), `04-fallback.conf` references `linux-zen`.
- syslinux `KIRO_FALLBACK_BEGIN/END` block intact, `LABEL arch_fallback`, correct kernel + initrd.
- `kiro-polybar` absent from the pkglist (`aa20e34`).

**`apply_kernel()` scoping confirmed.** The KIB's clone still read `linux-cachyos` only in
`archiso/packages.x86_64` — `PACKAGES_FILE` resolves into `${buildFolder}`, so the repo tree was
left clean while the build copy got both kernels plus headers.

**Mid-install snapshot** (caught after `unpackfs`, before `kiro_kernel`): the target held four preset
files — the two **package-shipped** presets (`linux-cachyos.preset` 644 b, `linux-zen.preset` 616 b)
plus the two live-only artifacts (`kiro`, and the archiso `linux.preset` with `PRESETS=('archiso')`).
Useful because it shows the purge target is unambiguous in this pairing: neither installed kernel is
named `linux`, so the archiso `linux.preset` cannot be confused for a real one.

**Installed system:**
- `/etc/mkinitcpio.d/` holds exactly `linux-cachyos.preset` (173 b) and `linux-zen.preset` (165 b),
  **both** headed `# mkinitcpio preset file - generated by Calamares (kiro_kernel)`. Provenance, not
  mere presence: these replaced the larger package-shipped files seen mid-install, proving
  `kiro_kernel` ran on both kernels. `kiro` and `linux.preset` are gone.
- Both `vmlinuz-*` copied at 12:48 and both `initramfs-*.img` built at 12:55 (~18.5 MB each), so both
  presets are functional, not just present.
- **No stray `.claude` dirs** — `/.claude` and `/etc/pacman.d/.claude` absent (`0543fa3`, second
  confirmation, first on a KIB-built image).
- **`kiro-polybar` not installed.** 1465 packages, zero failed units, boot 10.642s (1.596 kernel +
  4.078 initrd + 4.967 userspace). `pacman -Qk`: no missing files.
- pacman.conf: `[core] [extra] [nemesis_repo] [chaotic-aur]` active; `#[cachyos]` and `#[multilib]`
  commented, both deliberate.

**Finding — the installed-system default kernel is not driven by `kernel=` order.** `bootctl list`
shows both BLS entries carrying the **identical `sort-key: kiro`**:

```
title: Arch Linux (7.2.4-1-cachyos) (default) (selected)   sort-key: kiro
title: Arch Linux (7.2.4-zen2-1-zen)                       sort-key: kiro
```

`kernel-install` generated the two entries symmetrically and systemd-boot broke the tie on the
version string alone, so `linux-cachyos` winning the default is **incidental**. Nothing propagates
the ISO's primary-kernel choice to the target: `kiro_kernel` stores it in globalstorage as
`kiroKernel`, but a grep across `kiro-calamares-config` finds no consumer outside the CHANGELOG.
On the live medium first-in-`kernel=` *is* authoritative (`loader.conf` default); on the installed
system it is not. A pairing whose version strings sort the other way would boot the secondary kernel
by default — relevant before the October `linux` + `linux-lts` pairing ships.

Related: `kiro_kernel.detect_kernels()` returns `sorted(glob(...))` — alphabetical, not primary
order — and `run()` stores `names[0]` as the "primary". For cachyos+zen the two orders coincide, so
this run could not surface it; `linux-zen linux-lts` would (primary zen, sorted gives lts first).
Latent only while nothing reads `kiroKernel`.

**No repo risk from the cachyos kernel.** `linux-cachyos` resolves from **chaotic-aur**, which is
enabled on the installed system, so the kernel stays updatable even though `[cachyos]` itself is
commented out by default.

---

## 2026-09-12 — v26.09.12 ISO: VirtualBox install — `linux.preset` fix verified, kiro-audit 131 / 0 / 0

Second run of the day, on the **rebuilt `v26.09.12` ISO** (`ISO_BUILD` Sat Sep 12 08:33:18 CEST
2026). Purpose: confirm the `kiro_final` fix that stops Calamares deleting the installed `linux`
kernel's mkinitcpio preset, plus the two fixes the morning's metal-B run flagged as un-shipped.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE/ohmychadwm) | **ext4**, unencrypted | UEFI / systemd-boot | Clean install; **kiro-audit 131 / 0 / 0** |

**The preset fix, verified end to end:**
- `/etc/mkinitcpio.d/` holds **both** `linux.preset` (157 b) and `linux-lts.preset` (165 b).
- Both read `# mkinitcpio preset file - generated by Calamares (kiro_kernel)`, with
  `ALL_kver='/boot/vmlinuz-linux'` and `.../vmlinuz-linux-lts`. Provenance matters: this proves the
  preset **survived `kiro_final`**, rather than being regenerated later by Arch's
  `90-mkinitcpio-install.hook` (which writes a 588-byte stock file). That distinction is what made
  the earlier metal-B run look like a false pass.
- `mkinitcpio -P` built from **both** presets, and both initramfs were rewritten (08:45 → 08:51),
  so the preset is functional and not merely present.
- `kiro-audit` went from **130 / 0 / 1** (`FAIL linux.preset missing`) on the 07:45 build to
  **131 / 0 / 0** here.

Also confirmed on the installed system (the two defects the morning run found un-shipped):
- **No stray `.claude` dirs** — `/.claude` and `/etc/pacman.d/.claude` absent (`0543fa3`).
- **`kiro-polybar` not installed**, no polybar config anywhere (`aa20e34`).
- Zero failed units. Boot 9.761s (899ms kernel + 1.626s initrd + 7.234s userspace).

Packages carrying the fixes were verified by **extraction, not version number**:
`kiro-calamares-config-26.09-02` (builddate 08:31) contains the patched
`kiro_final/main.py` with no `linux.preset` removal entry, and its bundled offline microcode is
`amd-ucode-20260910-1` + `intel-ucode-20260812-1`, matching the repo HEAD after `cb8a761`.

---

## 2026-09-12 — Dev v26.09.11 ISO: first bare-metal ext4 / systemd-boot run (metal-B) — kiro-audit 131 / 0 / 0, two un-shipped fixes confirmed

The **`v26.09.11` dev ISO** (`ISO_BUILD` Fri Sep 11 18:33:54 CEST 2026, ISO file 18:41) installed on
**real hardware** (metal-B — i7-7700K, Intel HD630, Samsung SSD 860 EVO 500GB, ASUS STRIX Z270H,
real UEFI firmware). The two previous entries were both VirtualBox, so this is the **first
bare-metal ext4 / systemd-boot run in this log** — the 08-25 entry covered btrfs + LUKS + GRUB, so
the two runs validate different install paths and neither supersedes the other.

| Target (metal-B) | FS / encryption | Bootloader | Result |
|------------------|-----------------|------------|--------|
| Kiro default (XFCE/ohmychadwm) | **ext4**, unencrypted | UEFI / **systemd-boot 261.3** | Clean install; **kiro-audit 131 / 0 / 0** |

The 131 (vs 146 on 08-25) is **not** lost coverage: metal-B is ext4, so the btrfs/snapper and LUKS
sections do not apply — the audit says so itself ("Root filesystem is ext4, not btrfs — snapshot
stack not applicable").

Shipped-content verification on the installed system:
- **Release identity:** `/etc/dev-rel` `ISO_RELEASE=v26.09.11`, `ISO_CODENAME=kiro`.
- **pacman.conf:** `[core] [extra] [nemesis_repo] [chaotic-aur]` active; `#[cachyos]` correctly
  commented (opt-in post-install) and `#[multilib]` commented — both deliberate. `kiro_repo` does
  not leak to the target.
- **Boot:** 19.738s total (7.213 firmware + 5.471 loader + 1.782 kernel + 1.932 initrd + 3.338
  userspace); `graphical.target` at 3.260s. Secure Boot disabled, TPM2 absent.
- **Kernels:** `linux` and `linux-lts` both present with initramfs; running `7.2.4-arch1-2`.
- **Zero failed units** (`systemctl --failed` empty). 1460 packages. SDDM, NetworkManager and
  bluetooth enabled. `pacman -Qk`: no missing files.
- **Journal, priority ≤3, whole boot: three lines, all benign** — `x86/cpu: SGX disabled or
  unsupported by BIOS`, `virt/tdx: TDX not supported by the host platform` (CPU feature probes) and
  `sddm-helper: gkr-pam: unable to locate daemon control file` (gnome-keyring PAM at greeter time,
  cosmetic).

**Two defects found — both already fixed in git, neither in this ISO:**
1. **Stray `.claude` tooling dirs reached the installed root.** `/.claude/.cc-writes` and
   `/etc/pacman.d/.claude/.cc-writes` are present, empty, root-owned and **unowned by any package**
   (`pacman -Qo /.claude` → "No package owns"). This is the defect `0543fa3` fixes by stripping them
   from the build tree before mkarchiso — that commit landed at **19:47**, about 74 minutes *after*
   this ISO was built, so the image predates its own fix. First confirmation that the dirs survive
   Calamares onto a target, not just the live medium.
2. **`kiro-polybar` shipped with no polybar.** The package was installed (25 config files under
   `/etc/skel/.config/polybar/`), but the `polybar` binary was never on the ISO and nothing
   autostarts it — no reference in the ohmychadwm session autostart, `/etc/xdg/autostart/`,
   `.xprofile` or `.xinitrc`. Removed from both package lists the next morning (`aa20e34`).

**Consequence for release readiness:** this run does **not** clear the staleness gate. It validates
`c42c4cd` (kernel-agnostic fallback boot entry, committed 09-11 11:08, so baked into this 18:33
build) in the field, but `0543fa3` and `aa20e34` have never existed inside any ISO — only a fresh
build plus a fresh install test can cover those.

---

## 2026-08-25 — Production v26.08.25 release ISO: VirtualBox install — GRUB + LUKS + btrfs, kiro-audit 146 / 0 / 0

The **`v26.08.25` release ISO** (`ISO_BUILD` Tue Aug 25 06:44:05 CEST 2026, ISO file 06:52)
installed in **VirtualBox**. First logged run of the **encrypted btrfs** path — the previous
entry covered ext4/unencrypted, so this exercises LUKS, GRUB and the subvolume layout for the
first time in this log.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE/ohmychadwm) | **btrfs on LUKS** (full-disk encryption) | UEFI / **GRUB** | Clean install; **kiro-audit 146 / 0 / 0** |

**Second consecutive run with zero FAIL and zero WARN**, and across a different install path
(GRUB/LUKS/btrfs rather than systemd-boot/ext4), which is the more meaningful result — the
146 checks include the encryption and btrfs paths the 08-23 run never touched.

Delta verification — the three commits made after the v26.08.23 test are baked in and applied:
- **`kiro-system-files` 26.08-02 → 26.08-04.** `8cbac77` (drop distro attribution from the seven
  shipped tuning configs) and `3621ef6` (`kiro-audit`: rename the imports section to
  "Hardening & tuning"). All seven `/etc` configs verified clean on the installed system —
  no `Adopted from` headers, no dead `garuda-comparison-2026-05-28.md` pointer; `kiro-audit`
  reports 0 occurrences of the old name and carries the renamed section.
  *Note:* the fix nearly missed this ISO — `26.08-03` was built seven minutes **before**
  `8cbac77` landed, so the shipped package still had the old text while reporting the expected
  version. Caught by extracting the config out of the `.pkg.tar.zst` rather than trusting
  `pacman -Q`; `26.08-04` (built 06:28) carries it.
- **`kiro-calamares-config`** `5f6478f` — sidebar current-step style keys renamed for
  Calamares 3.4. Installer ran to completion with correct branding.

Live-session verification (before install), which an installed system cannot show:
- **`kiro-trust-desktop-launchers` confirmed working end-to-end** — the fix for this shipped in
  `calamares-…-17` on 08-22 but had only ever been checked against package contents, because the
  script installs under `/home/liveuser` and runs only in a live session. On this boot the user
  unit ran and exited `0/SUCCESS`, the script is mode `0755`, and `cal-kiro.desktop` carries the
  exec bit, `metadata::trusted: true` and an `xfce-exe-checksum` matching its own sha256 — the
  value Thunar 4.20 actually tests. Calamares launches from the desktop icon with **no
  "Untrusted application launcher" prompt** (confirmed by Erik clicking it).
- **`ohmychadwm` unowned-binary fix confirmed on a fresh ISO.** The only unowned binary in
  `/usr/local/bin` is `slstatus`, which is correct — it is packaged nowhere else and must be
  built there. No unowned `ohmychadwm` shadowing the packaged `/usr/bin/ohmychadwm`.

Shipped-content verification on the installed system:
- **Release identity:** `/etc/dev-rel` `ISO_RELEASE=v26.08.25`.
- **kiro_final cleanup:** `"Remove installation files: SUCCESS"` and
  `"Disable cachyos repo: SUCCESS"` in `/var/log/Calamares.log`. `/etc/calamares` gone;
  `calamares`, `mkinitcpio-archiso` and `kiro-calamares-config` all absent post-install.
  `/etc/ssh/sshd_config.d/` holds only `20-systemd-userdb.conf` and `99-archlinux.conf` —
  `10-archiso.conf` absent. No `liveuser` account on the target.
- **pacman.conf:** `[core] [extra] [nemesis_repo] [chaotic-aur]` active; `#[cachyos]` correctly
  commented (opt-in post-install, per `kiro_final` step 9); `#[multilib]` commented, which is
  deliberate — Kiro is not targeting a gaming audience. **`kiro_repo` does not leak to the
  target**, which closes the long-standing open question in Kiro-HQ's CLAUDE.md.
- **btrfs layout:** `@`, `@home`, `@root`, `@srv`, `@cache`, `@log`, `@tmp`, `@snapshots` —
  `snapper 0.13.1-3` installed and already holding 3 snapshots.
- **systemd-oomd:** enabled and active.
- **Zero failed units** (`systemctl --failed` empty).

**Observation, not a failure:** the running kernel is `7.1.9-zen1-2-zen` while
`linux-cachyos 7.2.0-1` is also installed — on this GRUB install the default entry resolved to
zen rather than cachyos. Worth confirming whether the GRUB entry ordering is intended, since the
systemd-boot path may order them differently.

---

## 2026-08-23 — Production v26.08.23 release ISO: VirtualBox install — default install, kiro-audit 132 / 0 / 0

The **`v26.08.23` release ISO** (`ISO_BUILD` Sun Aug 23 06:19:44 CEST 2026, ISO file 06:27)
installed in **VirtualBox** (UEFI, NAT, ext4, unencrypted). This run validates the three
ISO-affecting changes committed after the v26.08.22 build.

| Target (VirtualBox) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE/ohmychadwm) | **ext4**, unencrypted | UEFI / systemd-boot | Clean install; **kiro-audit 132 / 0 / 0** |

**First run with zero FAIL and zero WARN.** The single FAIL of the v26.08.22 real-metal run was
the `check_microcode()` false positive; the fix shipped in this ISO and the check now reports
`PASS  Microcode embedded in the initramfs by the mkinitcpio 'microcode' hook`.

Delta verification — every change committed between the two builds is baked in and applied:
- **`kiro-system-files` 26.08-01 -> 26.08-02** (pkglist and installed system agree).
  - `kiro-audit` carries `microcode_in_initramfs()` and the new branch fires — PASS, not the old FAIL.
  - Orphaned `kiro-install-tools` documentation gone: no man page, no leftover files owned by the package.
- **`kiro-calamares-config` 26.08-05 -> 26.08-06** — the `hostname.template` revert. The pkgrel
  bump is the evidence that the corrected `users.conf` shipped; the config itself is removed at
  install time, so it cannot be read back afterwards. Cross-check on the installed system:
  `/var/log/Calamares.log` contains no `kiro-x8664` and no `kiro-systemproductname` — the two names
  the rejected templates would have produced — and the hostname actually set matches the stock
  `${first}-${product}` expansion.
- Also refreshed by the rebuild: `linux-cachyos` 7.1.8-1 -> **7.2.0-1**, `linux-zen` 7.1.8.zen1-3 ->
  **7.1.9.zen1-2**, `mesa` 26.1.8 -> **26.2.1**, `poppler` 26.07 -> **26.08**,
  `cachyos-ananicy-rules-git`, `inkscape`, `jansson`, `libdeflate`, `oh-my-zsh-git`, the two Nerd Fonts.

Shipped-content verification on the installed system:
- **Release identity:** `/etc/dev-rel` `ISO_RELEASE=v26.08.23`.
- **kiro_final cleanup:** `"Remove installation files: SUCCESS"` in `/var/log/Calamares.log`;
  `/etc/ssh/sshd_config.d/` holds only `20-systemd-userdb.conf` and `99-archlinux.conf` —
  `10-archiso.conf` absent; `/etc/calamares` gone; `calamares` and `mkinitcpio-archiso` not installed;
  `kiro-calamares-config` correctly removed post-install (the old 2026-05-18 FAIL stays fixed).
- **fstab:** efi `defaults,umask=0077`, ext4 root `defaults,noatime`. No `/tmp` tmpfs line — expected,
  the virtual disk reports as rotational and `tmpOptions` only applies its `ssd` branch to a
  non-rotational root. Not a regression.
- **Boot:** 19.3s (kernel 2.2s + initrd 6.2s + userspace 11.0s); `graphical.target` after 9.1s.
  No failed systemd units. **0 pending updates.**
- `sshd` is `disabled`/inactive on a fresh install — as designed; `kiro-enable-ssh` is the opt-in.
  This audit ran over the VirtualBox guest-control channel, so the guest was not modified to test it.
- `pacman -Qk`: only the known cosmetic `amd-ucode.img` absence (the anti-downgrade guard skips the
  standalone image; the blob is in the initramfs early cpio) plus root-only `bind` zone files.

This validates the **v26.08.23 production release ISO in VirtualBox**.

## 2026-08-22 — Production v26.08.22 release ISO: REAL-METAL install — default install, 0 real FAIL

The **`v26.08.22` release ISO** (`ISO_BUILD` Sat Aug 22 11:46:57 CEST 2026, ISO file 11:54,
build 8m53s) installed on a **real-metal test box** (Intel, Samsung SSD 870 EVO 500GB, real UEFI
firmware). This is the test that validates every ISO-affecting commit landed since the 2026-06-30
v26.07.01 run — 20 non-doc commits across `kiro-iso` (6), `kiro-calamares-config` (7) and
`kiro-system-files` (7), including the bootctl-failure gate and the microcode anti-downgrade guard.

| Target (real metal) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| Kiro default (XFCE/ohmychadwm) | **ext4**, unencrypted | UEFI / systemd-boot | Clean install; **kiro-audit 131 / 0 / 1** |

**The single kiro-audit FAIL was a false positive in the audit itself, not a defect** —
`check_microcode()` looked only for a standalone `/boot/*-ucode.img` and did not recognise
Arch's `microcode` mkinitcpio hook, which embeds the vendor blob in the initramfs early cpio.
Microcode was verified working: `intel-ucode 20260812-1` (current — the anti-downgrade guard
held, no rollback to the May blob), `kernel/x86/microcode/GenuineIntel.bin` present in the early
cpio, and the kernel log shows `microcode: Updated early from: 0x000000e2` to
`Current revision: 0x00000100`. `kiro-audit` was fixed the same day to detect the hook layout.

Shipped-content verification on the installed system:
- **Release identity:** `/etc/dev-rel` `ISO_RELEASE=v26.08.22`.
- **Package currency:** the ISO pkglist carries every package changed since v26.08.20 —
  `kiro-calamares-config` 26.08-02 -> **26.08-05**, `kiro-system-files` 26.07-08 -> **26.08-01**,
  `archlinux-tweak-tool-gtk4` 26.08-01 -> **26.08-02**, `calamares` -16 -> **-17**.
- **New mount options applied end-to-end:** `/etc/fstab` matches the rewritten `mount.conf` /
  `fstab.conf` exactly — efi `defaults,umask=0077`, ext4 root `defaults,noatime`, swap `defaults`,
  and `/tmp` as tmpfs `defaults,noatime,mode=1777` (SSD root, so the `ssd` branch of `tmpOptions`).
- **kiro_final cleanup:** `"Remove installation files: SUCCESS"` in `/var/log/Calamares.log`;
  `10-archiso.conf`, `do-not-suspend.conf`, getty autologin and the polkit/sudoers live-env rules
  all confirmed removed; no archiso hooks in `mkinitcpio.conf`.
- All 11 hardening sysctl values, all 10 udev rules, 24/24 `kiro-*` scripts + the `skell` symlink,
  no orphan man pages, no duplicate `sysctl.d` / `system.conf.d` files.
- Kernels `linux-cachyos` 7.1.8-1 (+ `linux-zen` fallback); boot 21.3s; 0 pending updates;
  `pacman -Qk` clean.

This validates the **v26.08.22 production release ISO on real metal**.

## 2026-06-30 — Production v26.07.01 release ISO: first REAL-METAL install (metal-A) — default install, 0 FAIL

The same **`v26.07.01` release ISO** validated earlier in VirtualBox, now installed on **real
hardware** (metal-A — physical box, Samsung SSD 860 EVO 500GB, real UEFI firmware). This is the
bare-metal counterpart to the VBox test below: it confirms the production release installs and
boots cleanly off real firmware/storage, not just the emulated path. Default-edition install
validated over SSH (`<user>@<ip>`):

| Target (real metal) | FS / encryption | Bootloader | Result |
|---------------------|-----------------|------------|--------|
| **metal-A** Kiro default (XFCE/ohmychadwm) | **ext4**, unencrypted | UEFI / systemd-boot 261.1 | Clean install; **kiro-audit 133 / 0 / 0** |

Verification on the installed system:
- **Release identity:** `/etc/dev-rel` `ISO_RELEASE=v26.07.01`, `ISO_BUILD=Tue Jun 30 01:18:30 PM CEST 2026` — identical ISO to the VBox run.
- **kiro-audit 133 / 0 / 0** (one PASS more than the VBox run's 132 — the extra check is hardware-dependent, present on real metal / N-A in the VM).
- **fish default end-to-end:** installed `erik` login shell = `/bin/fish`.
- Kernels `linux-cachyos` 7.1.2-3 (+ `linux-zen` 7.0.14 fallback); sessions `ohmychadwm` / `xfce` / `xfce-wayland`; UEFI / systemd-boot 261.1; boot 18.6s; 0 failed units.
- Service baseline: firewalld active+enabled (zone `public`), `cups.socket` enabled+active, `logrotate.timer` enabled+active, tuned `throughput-performance` (ppd inactive), all 10 udev rules present.
- Signing: Kiro key **TRUSTED**, global `SigLevel = Required DatabaseOptional`.
- Name-leakage clean (only `/home/erik` archive-doc prose under `kiro-assistant/knowledge`, not config).
- Host `erik-systemproductname` (installer left default hostname). NIC quiet (no e1000e/ethtool noise). Only benign journal lines (`alsactl restore` exit 19, `gkr-pam` first-login keyring note).

This validates the **v26.07.01 production release ISO on real metal** in addition to the VBox run.

## 2026-06-30 — Production v26.07.01 release ISO: fish default + Kiro-menu reorg — default install, 0 FAIL

The **actual `v26.07.01` release ISO** (`ISO_BUILD` Tue Jun 30 13:18, ISO file 13:25) — built today
via the new `version_override` knob and installed via Calamares. This supersedes the 2026-06-28 RC
test: it validates the same fish default **plus** the `kiro-system-files` **26.06-116** menu
reorganization that landed 2026-06-29 (after the RC test) and ships in this ISO. Default-edition
install validated over SSH (`<user>@<vm-host>`):

| Target (VBox) | FS / encryption | Bootloader | Result |
|---------------|-----------------|------------|--------|
| **Kiro default** (XFCE/ohmychadwm) | **ext4**, unencrypted | UEFI / systemd-boot | Clean install; **kiro-audit 132 / 0 / 0** |

Shipped-content verification on the installed system:
- **Release identity:** `/etc/dev-rel` `ISO_RELEASE=v26.07.01`, `ISO_BUILD=Tue Jun 30 01:18:30 PM CEST 2026`.
- **fish default end-to-end:** installed `erik` login shell = `/bin/fish`. fish-stack present:
  `fish 4.7.1`, `starship 1.26.0`, `fish-tweak-tool 26.06-32`, `kiro-starship 26.06-06`,
  `kiro-fish-config 26.06-10`; `seahorse 47.0.1` (keyring GUI) present.
- **Kiro-menu reorg (the content that postdated the RC test):** `kiro-system-files 26.06-116`
  installed; `/usr/share/desktop-directories/kiro-apps.directory` present; all four
  `kiro-link-*.desktop` launchers carry `Categories=X-Kiro;` (moved out of the Internet menu into
  the Kiro menu). **This clears the distro-test staleness check** for kiro-system-files commits
  `8c29d4e` / `9d08636` / `93dcf8d`.
- **Calamares cleanup clean:** `calamares` binary removed (`pacman -Q` = not found); `/etc/calamares`
  gone.
- Kernels `linux-cachyos` 7.1.2-3 (+ `linux-zen` 7.0.14 fallback); sessions `ohmychadwm` / `xfce` /
  `xfce-wayland`; UEFI / systemd-boot; ZRAM 8G zstd; 0 failed units; boot 16.6s; host
  `<vm-host>`, VirtualBox (oracle).

This validates the **v26.07.01 production release ISO** on the default edition and clears the
distro-test staleness check for everything shipping in it.

## 2026-06-28 — Production v26.06.28: fish default (Starship + fish-tweak-tool) — default install, 0 FAIL

Production `kiro-iso` **v26.06.28** (`ISO_BUILD` 11:03) — the **July-1 `v26.07.01` release candidate**
in everything but the version string (the release-day build bumps the version only). It carries the
completed **bash → fish default**: the live `liveuser` and the installed user both log into fish, with
the **Starship** prompt and the **fish-tweak-tool** GUI now shipped. Default-edition install validated
over SSH (`<user>@<vm-host>`):

| Target (VBox) | FS / encryption | Bootloader | Result |
|---------------|-----------------|------------|--------|
| **Kiro default** (XFCE/ohmychadwm) | **ext4**, unencrypted | UEFI / systemd-boot | Clean install; **kiro-audit 132 / 0 / 0** |

Shipped-content verification on the installed system:
- **fish is the default shell end-to-end:** installed `erik` login shell = `/bin/fish` (via
  `kiro-calamares-config` `users.conf shell: /bin/fish`); the live ISO's `liveuser` is also `/bin/fish`.
- **fish-stack present:** `starship 1.25.1`, `fish-tweak-tool 26.06-23`, `kiro-starship 26.06-06`,
  `kiro-fish-config 26.06-09`, `kiro-shells 26.06-103` (meta), `fish 4.7.1` — the new prompt engine,
  preset and GUI all land. `seahorse 47.0.1` (keyring GUI) also present.
- **Calamares cleanup clean:** calamares binary, `mkinitcpio-archiso`, `memtest86+`,
  `kiro-calamares-tweak-tool` and `kiro-calamares-config-next` all removed; `/etc/calamares` gone;
  no autologin / nopasswd survivors.
- Kernel `linux-cachyos` 7.1.2-2 (+ `linux-zen` fallback); sessions `ohmychadwm` / `xfce` /
  `xfce-wayland`; UEFI / systemd-boot; ZRAM 8G zstd; 0 failed units; boot 15.6s; host `<vm-host>`,
  VirtualBox (oracle).

This validates the v26.06.28 production ISO on the default edition and **clears the distro-test
staleness check** for the fish-default release shipping as `v26.07.01` on 2026-07-01.

## 2026-06-14 — Production v26.06.14: AI assistant + signed-package enforcement + sdl2-compat pre-seed — default install, 0 FAIL

Production `kiro-iso` **v26.06.14** (`ISO_BUILD` 07:45, ISO file 07:54) carrying the day's shipped
changes: the new **AI TOOLS** TIER-3 group (`kiro-assistant` + `claude-code`), the **`sdl2-compat`
pre-seed** (kills the first-`-Syu` sdl2 replace prompt), and — promoted from `-next` —
**package-signature enforcement** (global `SigLevel = Required DatabaseOptional`; signed
`nemesis_repo`/`kiro_repo` verified out of the box). Default-edition install validated over SSH
(`<user>@<vm-host>`):

| Target (VBox) | FS / encryption | Bootloader | Result |
|---------------|-----------------|------------|--------|
| **Kiro default** (XFCE/ohmychadwm) | **ext4**, unencrypted | UEFI / systemd-boot | Clean install; **kiro-audit 133 / 0 / 0** |

Shipped-content verification on the installed system:
- **AI tools present:** `kiro-assistant 26.06-04` + `claude-code 2.1.175-1` installed — the new
  **AI TOOLS** group lands as expected.
- **sdl2-compat pre-seed:** `sdl2-compat 2.32.70-1` installed and `pacman -Q sdl2` resolves to it
  (`Provides`) — no old `sdl2`, so the first `-Syu` has nothing to replace.
- **Signed-package enforcement:** `/etc/pacman.conf` carries `SigLevel = Required DatabaseOptional`
  — signed repos verified out of the box.
- **kiro-link menu + Onboard themes:** all four `kiro-link-*.desktop` entries and all five
  `Kiro *.theme` Onboard themes present (from `kiro-system-files 26.06-34`).
- Sessions `xfce` / `xfce-wayland` / `ohmychadwm`; host `<vm-host>`, VirtualBox (oracle).

This validates the v26.06.14 production ISO on the default edition and **clears the distro-test
staleness check** for the day's shipped changes.

## 2026-06-11 — New Budgie ISO: CTT menu-launch fix + encrypted-btrfs and regular installs — both boot, 0 real FAIL

New `kiro-iso` build carrying the **calamares-tweak-tool menu-launch fix** (`.desktop` dropped
bare `sudo` for `pkexec`; no `exec` so the menu launcher doesn't leave pkexec a dead parent;
socket-based Wayland detection — see `kiro-calamares-tweak-tool` CHANGELOG 2026.06.11). On the
live **Budgie/Wayland** ISO, CTT now launches **from the menu** (previously did nothing) and
Calamares launches. Two installs off this ISO, both UEFI, validated over SSH (`<user>@<vm-host>`):

| Target (VBox) | FS / encryption | Bootloader | Result |
|---------------|-----------------|------------|--------|
| **Kiro** (Budgie edition) | **btrfs + LUKS2/argon2id** (aes-xts-plain64) | UEFI / systemd-boot | Booted = LUKS unlocks at boot; full `@`/`@home`/`@root`/`@snapshots`/`@log`/`@cache`/`@srv`/`@tmp` subvol layout; Calamares.log clean; **kiro-audit 4 FAIL = all edition artifacts** (see note) |
| **Kiro default** (XFCE/ohmychadwm) | **ext4**, unencrypted | UEFI / systemd-boot 260.2 | Clean default install; no LUKS; Calamares.log clean; **kiro-audit 0 / 0 / 0** |

- **CTT encrypted-btrfs path validated end-to-end:** `cryptsetup luksDump /dev/sda2` = **LUKS2 +
  argon2id**, root is **btrfs** with the standard subvol scheme, and the system **boots** — so the
  installed bootchain unlocks the LUKS2/argon2id volume. Exactly CTT's headline claim.
- **The encrypted box's 4 kiro-audit FAILs are NOT install failures:** `ohmychadwm not installed`
  / `xfwm4 not installed` / `ohmychadwm.desktop missing` / `xfce.desktop missing`. `kiro-audit`
  hardcodes the default **XFCE + ohmychadwm** edition; this install is a **Budgie** edition, so
  those checks miss. Real install health is clean (Calamares log, btrfs, LUKS2, boot all correct).
  → **Fixed same day:** `kiro-audit` `check_desktop()` is now edition-agnostic + Wayland-aware
  (scans `/usr/share/xsessions` + `/usr/share/wayland-sessions`; passes on any session) — see
  `kiro-system-files` CHANGELOG 2026.06.11. Rebuild `kiro-system-files` to clear these on Budgie.

**Re-verified on the FINAL ISO (`v26.06.11`, 08:35 build — new `kiro-audit` shipped).** A fresh
**encrypted-btrfs** install, this time the **default XFCE + ohmychadwm** edition (sessions
`xfce` / `xfce-wayland` / `ohmychadwm`), VirtualBox UEFI:

| Check | Result |
|-------|--------|
| Encryption | `/dev/sda2` **LUKS2** / aes-xts-plain64; btrfs root unlocks at boot ✓ |
| Subvolumes | full `@ @home @root @srv @cache @log @tmp @snapshots` ✓ |
| Bootloader | UEFI / **systemd-boot 260.2** ✓ |
| **kiro-audit (new tool)** | **136 PASS / 0 WARN / 0 FAIL** ✓ |

This is the **first installed-system run of the edition-aware audit + live-guard build**, and it
comes back **0 FAIL** — confirming all four 2026-06-11 `kiro-audit` fixes ship clean on a real
install: edition-agnostic desktop check, `/run/archiso` live-guard, cachyos-enabled→PASS, and
`MAKEFLAGS` `nproc-1`/`nproc-2`→PASS. No false FAILs.

## 2026-06-09 — Production v26.06.09: new custom Calamares modules + WM editions — 4 installs, both firmware paths, 0 FAIL

Production `kiro-iso` **v26.06.09** (`ISO_BUILD` 20:58, ISO file 21:04) carrying the day's two big shipped changes: the **WM/desktop editions system** (`build-the-iso.sh` `apply_editions()` + `### >>> EDITION-BLOCK >>>` blocks in `packages.x86_64`, promoted from `-next`) and a **ground-up Calamares installer rewrite** in `kiro-calamares-config` — three new custom Python modules **`kiro_bootloader`** (974-line, replaces stock bootloader), **`kiro_displaymanager`** (1101-line, replaces stock displaymanager), and **`kiro_packages`** (832-line, replaces stock packages) — plus the production package-name fix in `kiro_packages.conf`/`kiro_final`. Validated across four installs covering **both firmware paths** and **both bootloader branches of the new `kiro_bootloader`**:

| Target | Firmware / bootloader | New modules ran | Result |
|--------|----------------------|-----------------|--------|
| VirtualBox VM (oracle) | UEFI / systemd-boot | `kiro_bootloader`/`kiro_displaymanager`/`kiro_packages` all ran; `Bootloader: systemd-boot` → SUCCESS | **kiro-audit 134 / 0 / 0** |
| **metal-A** (real metal, Intel HD630) | UEFI / systemd-boot | all three ran; systemd-boot branch → SUCCESS | **135 / 0 / 0**; install 3m21s |
| **metal-B** (real metal, i7-7700K, Intel HD630) | UEFI / systemd-boot | all three ran; systemd-boot branch → SUCCESS | **139 / 0 / 0**; install 4m21s |
| **metal-C** (real metal, MEDION P7624, Fermi GT 620M + Intel) | **BIOS / grub** | all three ran; **GRUB branch executed** — `Bootloader: grub (bios)` → `grub-install --target=i386-pc --recheck --force /dev/sda` → `grub-mkconfig -o /boot/grub/grub.cfg` → SUCCESS | **134 / 2 / 0**; install 5m58s |

- **New `kiro_bootloader` validated on BOTH branches:** systemd-boot (VM + metal-A + metal-B) and **GRUB/BIOS (metal-C)** — `grub-install i386-pc → /dev/sda` + `grub-mkconfig` both ran to SUCCESS on real BIOS metal. This was the decisive gap: the rewrite's GRUB branch had no v26.06.09 validation until metal-C.
- **New `kiro_displaymanager` + `kiro_packages`** ran on every target; package-removal cleanup correct (production names — `kiro-calamares-config`/`kiro-calamares-tweak-tool`/`calamares` removed, GRUB removed on systemd-boot).
- metal-C's 2 WARN are `NVIDIA Fermi present but nvidia-open-dkms / nvidia-utils not installed` — **expected/benign** (Fermi can't use the open driver; chwd correctly routes it to nouveau). `GRUB boot-safety hooks installed` PASS on the grub box.
- Install times recorded in [BUILD_TIMES.md](BUILD_TIMES.md) (metal-A 3m21s, metal-B 4m21s, metal-C 5m58s).

## 2026-06-08 — Production v26.06.08: GRUB boot-safety + spice-vdagent — 4 installs, both firmware paths, 0 FAIL

Production `kiro-iso` **v26.06.08** (built 15:13) carrying the day's two new features: **`kiro-bootloader-grub` 26.06-04** (self-healing GRUB — pacman hooks re-run `grub-install`/`grub-mkconfig` on grub/kernel updates), **`spice-vdagent` 0.23.0** (QEMU/SPICE host↔guest clipboard), the updated **`kiro-calamares-config`** (`kiro_final`: spice in the `qemu` cleanup profile + combined `kiro-bootloader-grub`+`grub` removal on systemd-boot), and **`kiro-system-files` 26.06-21** (new `kiro-audit` GRUB boot-safety check). Validated across four installs, both firmware paths:

| Target | Firmware | Result |
|--------|----------|--------|
| KVM VM (vda) | BIOS / grub | `kiro-bootloader-grub` kept; `kiro-grub-install -> /dev/vda`; both hooks fire on a `grub` reinstall; `spice-vdagent` kept |
| KVM VM | UEFI / systemd-boot | `grub` + `kiro-bootloader-grub` stripped together; `spice-vdagent` kept (kvm) |
| **metal-C** (real metal, MEDION P7624, SATA, Fermi GPU) | BIOS / grub | pkg + both helpers; `kiro-grub-install -> /dev/sda`; **kiro-audit: `PASS GRUB boot-safety hooks installed`** — 134 PASS / 2 WARN / 0 FAIL (the 2 WARN = NVIDIA Fermi on nouveau, expected) |
| **metal-A** (real metal, Intel HD630) | UEFI / systemd-boot | `grub` + `kiro-bootloader-grub` + `spice-vdagent` **all stripped**; **kiro-audit 135 / 0 / 0** |
| **metal-B** (real metal, Intel HD630) | UEFI / systemd-boot | identical to metal-A; **kiro-audit 135 / 0 / 0** |

- **Disk auto-detection** proven on `sda` (VirtualBox + metal-C) and `vda` (QEMU) — never the old hardcoded `/dev/sda`.
- **Removal correctness** confirmed in `Calamares.log`: on systemd-boot it logs *"systemd-boot detected. Removing GRUB"* (grub + hook pkg together); on bare metal *"Virtualization type: none"* strips all VM profiles (so spice-vdagent goes too); on kvm only vmware+vbox are stripped (spice-vdagent kept).
- **New `kiro-audit` check** shows `PASS GRUB boot-safety hooks installed` on a real grub system (metal-C) and stays correctly **silent** on systemd-boot — audit baseline clean (0 FAIL on every target).

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

**Bare-metal confirmation on the 19:40 / `26.06-08` release ISO** (metal-A + metal-B reinstalled from it, both Intel HD 630):
| Box | Boot | nvidia outcome | kiro-audit |
|-----|------|----------------|------------|
| **metal-A** | line 1 `free` | open stack removed (chwd skipped); only `linux-firmware-nvidia` left | **136 PASS / 0 WARN / 0 FAIL** |
| **metal-B** | line 2 `nonfree` | baked `nvidia-open-dkms/settings/utils` **kept** (chwd + removal both skipped — correct for nonfree) | **134 PASS / 1 WARN / 0 FAIL** |

metal-B's single WARN is `nvidia-open-dkms installed but no NVIDIA GPU detected` — **expected/benign**: line 2 deliberately keeps the baked driver, and metal-B has only an Intel iGPU, so the audit correctly notes the driver is installed-but-unused (the mirror image of metal-C's line-3 `NVIDIA GPU present but nvidia-open-dkms not installed`). Together with the Kiro-normal encrypted line-3 install above, the 19:40 release ISO is now validated across **all three boot entries (free / nonfree / nonfreechwd) plus full-disk encryption**.

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

**Bare-metal confirmation — metal-A (real Intel HD 630, boot line 1 `driver=free`):** clean install from the same `v26.06.07` ISO (`ISO_BUILD` 16:23). `kiro-audit` **135 PASS / 0 WARN / 0 FAIL**. `Calamares.log` shows `kiro_remove_nvidia` running the **new** discovery code: `"Removing NVIDIA packages: nvidia-open-dkms nvidia-settings nvidia-utils"` → `pacman -Rns --noconfirm` removed the open stack in one transaction (~1 GB; dkms removed for both `7.0.11-1-cachyos` and `7.0.11-zen1-1-zen`). Post-install only `linux-firmware-nvidia` remains. Confirms the fixed module runs correctly on metal — but the open stack uses *real* names, so this still does not exercise the 390xx/580xx provide-resolution path.

**Bare-metal confirmation — metal-B (real Intel HD 630, boot line 1 `driver=free`):** same `v26.06.07` ISO, identical result — `kiro-audit` **135 PASS / 0 WARN / 0 FAIL**; `Calamares.log` shows `driver=free` → `"Removing NVIDIA packages: nvidia-open-dkms nvidia-settings nvidia-utils"` then `"Skipping chwd because 'driver=free'"`. Two independent metal boxes (metal-A + metal-B) now confirm the production open ISO.

**Bare-metal — metal-C (real NVIDIA Fermi GT 620M + Intel iGPU, boot line 3 `driver=nonfreechwd`):** installed from the **production open** `v26.06.07` ISO (confirmed: `390xx` appears **0×** in `Calamares.log`; baked stack removed was `nvidia-open-dkms nvidia-settings nvidia-utils`). `kiro_remove_nvidia` removed the open stack, then chwd ran and routed the Fermi card to **nouveau** (`> Successfully installed intel`; active `i915` + `nouveau`). `kiro-audit` **133 PASS / 2 WARN / 0 FAIL** — the 2 WARN (`NVIDIA GPU present but nvidia-open-dkms not installed`, `nvidia-utils not installed`) are **expected/benign** for a legacy-NVIDIA-on-nouveau box (open driver intentionally removed; Fermi can't use it). This validates the **line-3 nonfreechwd path + chwd nouveau routing on real NVIDIA hardware** — but it is the open stack under real names, so it still does **not** exercise the 390xx/580xx provide-resolution path. **Audit-refinement TODO:** kiro-audit should treat nouveau-on-legacy-NVIDIA as valid instead of warning.

**★ 390xx provide-resolution fix — PROVEN (the decisive test).** VM `Kiro-E-jfs`, installed from the **`kiro-next-v26.06.07`** ISO (`nvidia_driver=390xx`, `ISO_BUILD` 17:42), boot line 3 `driver=nonfreechwd`. `Calamares.log` shows `kiro_remove_nvidia` discovered the baked **390xx** stack by real name and removed it in one transaction:
```
"Removing NVIDIA packages: nvidia-390xx-dkms nvidia-390xx-settings nvidia-390xx-utils"
.. Running ("pacman","-Rns","--noconfirm","nvidia-390xx-dkms","nvidia-390xx-settings","nvidia-390xx-utils")
nvidia-390xx-dkms 390.157-21  -27.19 MiB ; nvidia-390xx-utils -106.63 MiB ; nvidia-390xx-settings -1.51 MiB  → removed
```
**Install completed** (`kiro_final` ran, no abort); post-install only `linux-firmware-nvidia` remains; **`kiro-audit` 134 PASS / 0 WARN / 0 FAIL**. This is exactly the case the old hardcoded code broke: `pacman -Q nvidia-utils` resolved the provide (`nvidia-390xx-utils`) but `pacman -Rns nvidia-utils` could not → `target not found` → `nvidia-remove-failed` → **install aborted**. The fix (`installed_nvidia_stack()` via `pacman -Qq`, removing real variant names) resolves it — confirmed end-to-end on a real 390xx install. (`kiro-calamares-config@41d9388` / `-next@a7bcd09`.) **580xx** variant is the analogous path (same code, same provide mechanism); validate similarly when a 580xx ISO is installed.

**Verdict:** production `v26.06.07` (normal/open ISO) verified release-ready by full install (VM + metal-A + metal-B metal + metal-C metal/line-3). Today's `kiro_remove_nvidia` install-blocking fix is **PROVEN** on the 390xx provide-resolution path (Kiro-E-jfs) — install no longer aborts on 390xx/580xx ISOs; the staleness gate for `41d9388` is cleared by this logged test. 580xx pending the same check.

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
- **metal-A** — tested across two reinstalls, both **0 WARN / 0 FAIL**, "all checks passed":
  - unencrypted ext4 → **134 PASS** (`check_disk_format` reports `ext4 (unencrypted)`);
  - reinstalled btrfs-encrypted (LUKS2 root + separate encrypted swap) → **148 PASS** (LUKS2 ×2, `sd-encrypt` hook, keyfile 600, 2 dm-crypt mappings; snapshot stack opt-in installed & passing). kiro-report: `btrfs · LUKS2 (2 containers) · encrypted swap yes`, 0 UUID leaks.
- **metal-B** (`<ip>`, **encrypted** ext4-on-LUKS2 + separate encrypted swap, 2 containers) — **139 PASS / 0 WARN / 0 FAIL**, "all checks passed". On real hardware the encryption asserts all pass (LUKS2 ×2, `sd-encrypt` hook, `/crypto_keyfile.bin` 600 root:root, 2 active dm-crypt mappings); kiro-report shows `ext4 · LUKS2 (2 containers) · encrypted swap yes` with 0 raw UUIDs after redaction.

This **closes the bare-metal encrypted gap** — full-disk LUKS is now verified on real hardware, not just in VMs. No VM-artifact caveat on either box. Encrypted layouts now proven across ext4/btrfs/xfs/jfs (VM) plus encrypted-ext4 on metal (metal-B).

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
  NVIDIA driver was installed; metal-C (Fermi) can only route to nouveau, never exercise this. Needs a real
  modern/mid NVIDIA box.

**Unrelated finding (not a blocker) — installed default kernel differs by firmware path:** the
**UEFI/systemd-boot** install defaults to **linux-cachyos** (correct, matches policy); the **BIOS/GRUB**
install defaults to **linux-zen** (booted system reported `7.0.10-zen1-1-zen`). cachyos should be the
post-install default on both — GRUB-path-only ordering issue, tracked for a post-launch fix. Both kernels
install and boot fine; this is a default-selection nit, not a failure.

**Verdict:** the 3-mode gating is **verified on VM** — `nonfree` (UEFI: nvidia kept, chwd skipped) and
`nonfreechwd` (BIOS: nvidia removed, chwd ran clean), with `free` per the 2026-05-28 baseline. **The one
remaining open verification** is chwd's proprietary NVIDIA install on real hardware (modern card →
`nvidia-open-dkms`, older → `470xx`/`390xx`) — a VM can't exercise it and metal-C (Fermi) can't either.

---

## 2026-05-31 — v26.05.31 staleness clearance — no functional changes since 2026-05-28 test

All commits to `kiro-iso`, `kiro-calamares-config`, and `edu-system-files` since the 2026-05-28 bare-metal test (128 PASS / 0 WARN / 0 FAIL) are cosmetic only: trailing newline fixes on efiboot entries and `services-systemd.conf`, plus the version bump to `v26.05.31`. No shipped config, package list, or installer logic changed. The 2026-05-28 test result stands as the functional baseline for this release.

**Verdict:** test result carries forward — staleness cleared for v26.05.31 release.

---

## 2026-05-29 — chwd NVIDIA routing on metal-C (nonfree path) — **PARTIAL: routing PASS, `nvidia-open-dkms` path untested** — real metal (Optimus laptop, UEFI)

**Environment:** Test install on **metal-C** (`<host>`), an Optimus laptop — Intel HD (2nd-gen) iGPU + NVIDIA **GF108M / GeForce GT 620M** (Fermi, PCI `10de:0de9`). Booted with the **non-free** GRUB entry (`driver=nonfree`). Transcribed into the test log from the `bdca88b` findings so the chwd integration shipping in production has a logged test (was previously only in the kiro-iso CHANGELOG).

**chwd routing — PASS.** Calamares log confirms `Kernel parameter 'driver' = nonfree` → `chwd --autoconfigure`, which made the right per-device calls: `intel` for the iGPU and **`nouveau` for the GT 620M**. chwd's device DB classifies that Fermi card as nouveau (not 390xx), so it never attempted a proprietary driver — pulled `nouveau-fw` + mesa/opencl and finished cleanly. Installed system runs Intel `i915` + Xorg `modesetting`; display healthy.

**Patched chwd shipped — PASS (by inspection).** Installed box carries **`chwd 1.21.0-4`** (our patched build); `/var/lib/chwd/db/pci/graphic_drivers/profiles.toml` shows the patched `[nvidia-open-dkms]` block (`nvidia-open-dkms` + per-kernel `-headers`, old `${kernel}-nvidia-open` prebuilt logic gone). `linux-cachyos-nvidia-open` not installed.

**KNOWN GAP — `nvidia-open-dkms` proprietary path NOT exercised.** metal-C's Fermi card routed to nouveau, so the `nvidia-open-dkms` profile never fired. The modern-NVIDIA + nonfree scenario (chwd selects `nvidia-open-dkms`, DKMS **builds** not just `added`, `nvidia-smi` works, no `linux-cachyos-nvidia-open`) is confirmed present/correct in config but **never run end-to-end**. Needs a box with a modern NVIDIA GPU that chwd routes to that profile. **Open at launch — documented limitation; install is non-fatal (nouveau fallback), and `nvidia-open-dkms` is known to build on 7.0 kernels.**

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

**Environment:** Same "Kiro" VirtualBox VM, UEFI/systemd-boot. New ISO built after [kiro-calamares-config](/home/erik/KIRO/kiro-calamares-config) commits `8195c9f` (multi-kernel install fixes: cmdline dedup + mkinitcpio churn cut) and `b49668c` (.gitignore for makepkg artifacts), plus [calamares-3.4.2.r4.g841b478-6](/home/erik/KIRO-PKG-BUILD/calamares-3.4.2.r4.g841b478-6/) package carrying the bootloader/main.py `list()` defensive copy. Calamares `3.4.3.20260528-841b4785-dirty`. Host: <vm-host>.

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
- `kiro-enable-ssh` now does `pacman -Sy` first and (on the live ISO only) sets `liveuser`'s password to a known value so SSH actually works after the one-command opt-in — verified the live-ISO gate via `/run/archiso/bootmnt` is a no-op on the installed system (this install correctly logged "Not on live ISO… skipping").

---

## 2026-05-28 — cachyos+zen default kernels — VirtualBox VM (UEFI, Intel i7-10700K)

**Environment:** "Kiro" VirtualBox VM, UEFI/systemd-boot. Live ISO built today after the [build-the-iso.sh:101](build-scripts/build-the-iso.sh) `kernel=` flip from `linux-lqx` → `linux-cachyos linux-zen`. Calamares 3.4.3.20260528-841b4785-dirty. Host: <vm-host>.

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

**Environment:** VirtualBox 7.x, UEFI firmware, Intel CPU (6 cores), NAT networking with SSH port forwarding host:<port>→guest:22

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
