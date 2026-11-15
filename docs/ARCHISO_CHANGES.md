# archiso upstream changes per version

What upstream archiso changed from one version to the next: its own CHANGELOG, plus the profile files and
`mkarchiso` lines that actually changed. Kiro's decisions on each change are in
[ARCHISO_HISTORY.md](ARCHISO_HISTORY.md). The current baseline is in [ARCHISO_BASELINE](ARCHISO_BASELINE).

Sources: `/usr/share/doc/archiso/CHANGELOG.rst`, the full copies in `/usr/share/archiso-<version>` on the build host, and
`usr/bin/mkarchiso` from the cached packages (`/var/cache/pacman/pkg/archiso-<version>-any.pkg.tar.zst`).
Add a section on top for every new archiso version (`/kiro-archiso` step 3).

## 92-1 (2026-10-31, from 91-1)

**Upstream changelog**
- Added: boot entries for the Memtest86+ IA32, AA64 and LOONGARCH64 EFI binaries.
- Changed: follows the memtest86+-efi 9.00 file rename (`memtest.efi` → `memtest86<arch>.efi`).
- Removed: `linux-atm` from the releng package lists (ATM support was dropped with linux 7.2).
- Removed: the `kms` mkinitcpio hook.

**Files changed**
- releng: `airootfs/etc/mkinitcpio.conf.d/archiso.conf`, `efiboot/loader/entries/03-archiso-memtest86+x64.conf`,
  new `03-archiso-memtest86+{IA32,AA64,LOONGARCH64}.conf`, `grub/grub.cfg`, `grub/loopback.cfg`, `packages.x86_64`,
  `packages.aarch64`
- baseline: `grub/grub.cfg`, `grub/loopback.cfg`
- mkarchiso: 43 changed lines, all memtest copy logic (per-arch EFI binary, LICENSE copied once, efiboot image glob)

| Change | Kiro today |
|--------|------------|
| `linux-atm` removed | Taken 2026-10-31 |
| `kms` hook removed | Not for now (Kiro keeps `kms` for the plymouth splash) |
| GRUB memtest `memtest86${uefi_machine_type_lower}.efi`, `if/elif` | Not for now (GRUB isn't a Kiro bootmode) |
| systemd-boot memtest x64 entry renamed | Not for now (Kiro has no UEFI memtest entry) |
| memtest IA32 / AA64 / LOONGARCH64 entries | Not relevant (x86_64 only) |
| mkarchiso memtest copy logic | Nothing to do in Kiro's profile |

## 91-1 (2026-09-27, from 90-1)

**Upstream changelog**
- Added: architecture-specific kernel parameters in all boot loaders (`kernel_params_<arch>` → `%KERNEL_PARAMS%`).
- Added: an AArch64 package list for releng; AArch64 EFI executables with stubble and device trees.
- Added: `lz4` and `pzstd` compression for the bootstrap tarball.
- Changed: warns when `mkarchiso` runs as root via sudo/run0 (running as a regular user is supported).
- Changed: simpler UEFI shell entries in the GRUB config.
- Changed: doesn't fail when a mixed-mode (IA32 UEFI) boot loader is missing; mixed mode is skipped instead.
- Fixed: no failure when `bootstrap_tarball_compression` is unset; man page formatting.
- Removed: `buildmodes` from both `profiledef.sh` (same as the default, `iso`).
- Removed: leftover `/etc/modprobe.d/broadcom-wl.conf` from releng.
- Removed: the custom `/etc/mkinitcpio.d/linux.preset` from both profiles.

**Files changed**
- releng: `profiledef.sh`, `efiboot/loader/entries/01-archiso-linux.conf`, `02-archiso-speech-linux.conf`,
  `grub/grub.cfg`, `grub/loopback.cfg`, `syslinux/archiso_sys-linux.cfg`, `syslinux/archiso_pxe-linux.cfg`,
  new `packages.aarch64`, removed `airootfs/etc/mkinitcpio.d/` and `airootfs/etc/modprobe.d/`
- baseline: `profiledef.sh`, `grub/grub.cfg`, `grub/loopback.cfg`, removed `airootfs/etc/mkinitcpio.d/`
- mkarchiso: 117 changed lines (`%KERNEL_PARAMS%`, aarch64/stubble, tarball compressors, root warning)

| Change | Kiro today |
|--------|------------|
| `%KERNEL_PARAMS%` in every boot entry | Taken; Kiro now sets `kernel_params_x86_64`, build needs archiso ≥ 91-1 |
| `buildmodes` removed | Taken |
| `broadcom-wl.conf` removed | Taken |
| GRUB UEFI shell simplification | Taken |
| `linux.preset` removed | Kiro-own: Kiro keeps its preset (one image per kernel) |
| Root warning under sudo | Kiro-own: build still runs `sudo mkarchiso` |
| aarch64 list, stubble, speech entries, lz4/pzstd | Not relevant |

## 90-1 (2026-09-01, from 89-1)

**Upstream changelog**
- Added: `i486` and `pentium4` in the `run_archiso` script.
- Changed: BIOS boot modes are skipped (not failed) on non-x86 architectures.
- Changed: releng squashfs uses xz's `arm64` BCJ filter next to `x86`.
- Fixed: `grubenv` and UUID search files no matter the order of the `iso` and `netboot` build modes.
- Fixed: airootfs `/boot` copied to the work dir, so netboot-before-iso still finds the boot files.
- Removed: `broadcom-wl` from releng (removed from the official repos).

**Files changed**
- releng: `packages.x86_64` (`broadcom-wl` removed), `profiledef.sh` (`-Xbcj x86,arm64`)
- baseline: none
- mkarchiso: 103 changed lines (arch handling, netboot/iso ordering, `/boot` copy)

| Change | Kiro today |
|--------|------------|
| `broadcom-wl` removed | Already: Kiro ships `cachyos/broadcom-wl-dkms` |
| xz `x86,arm64` BCJ filter | Not relevant: Kiro compresses with zstd |
| i486/pentium4, netboot fixes | Not relevant |

No sync decision was recorded at the time; the "Kiro today" column was filled in on 2026-10-31.

## 89-1 (2026-07-25, from 88)

**Upstream changelog**
- Added: `ghostty-terminfo` and `kmscon-terminfo` in releng (for terminals used over SSH).
- Added: `mkarchiso` runs as a regular user through `unshare` (needs user namespaces).
- Added: BIOS boot modes and microcode check on `i486` and `pentium4`.
- Changed: releng ships `ntfsprogs` instead of `ntfs-3g` (only the userspace tools are needed).
- Fixed: `tune2fs` no longer required for `ext4+squashfs`; `install_dir` validated; `uefi.systemd-boot` and
  `uefi.grub` together are rejected; UEFI shell for non-x64; bzip2 bootstrap tarball.

**Files changed:** no 88 copy is kept, so only the changelog above is available.

| Change | Kiro today |
|--------|------------|
| `ghostty-terminfo`, `kmscon-terminfo` | Not in Kiro's package list |
| `ntfsprogs` instead of `ntfs-3g` | Kiro still ships `ntfs-3g` |
| Non-root `mkarchiso` via `unshare` | Kiro still runs `sudo mkarchiso` |
| systemd-boot + GRUB together rejected | Fine: Kiro uses syslinux + systemd-boot |

No sync decision was recorded at the time; the "Kiro today" column was filled in on 2026-10-31.
