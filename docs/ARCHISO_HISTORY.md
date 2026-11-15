# archiso sync history

Every upstream `archiso` version Kiro was compared against, and what was decided for each upstream change.
`/kiro-archiso` reads this file first. What upstream changed in each version is in [ARCHISO_CHANGES.md](ARCHISO_CHANGES.md).
The upstream copies used for each diff are kept in `/usr/share/archiso-<version>` on the build host.
The current baseline is in [ARCHISO_BASELINE](ARCHISO_BASELINE).

Decision classes: **Taken** (applied to Kiro), **Not for now** (Erik deferred it, reason given; re-ask only when upstream changes it again or Erik asks), **Kiro-own** (Kiro deliberately
differs), **N/A** (Kiro doesn't have the file or feature), **Already** (Kiro already had it).

**Standing Kiro-own removals (2026-11-15, kiro-iso audit):** no `grub/grub.cfg` (no grub bootmode; only `grub/loopback.cfg` ships) and no PXE (`archiso_pxe_*` mkinitcpio hooks, `syslinux/archiso_pxe.cfg`, `syslinux/archiso_pxe-linux.cfg`, the `LABEL pxe` in `syslinux.cfg`). Upstream hunks to those are **N/A**. The `nbd` / `mkinitcpio-nfs-utils` packages stay in the verbatim ARCHISO BASE block of `packages.x86_64`.

## archiso 92-1 (compared against 91-1, 2026-10-31)

Upstream changelog: memtest86+-efi 9.00 renamed its EFI binaries (`memtest.efi` → `memtest86<arch>.efi`), new
memtest entries for the other UEFI architectures, `linux-atm` removed, `kms` hook removed.

| Change | Decision | Reason |
|--------|----------|--------|
| Remove `linux-atm` from `packages.x86_64` | Taken | ADSL ATM userspace; upstream says ATM support was dropped with linux 7.2 |
| Remove `kms` from the mkinitcpio `HOOKS` | Not for now | Kiro's `plymouth` splash relies on early KMS; upstream gave no reason |
| GRUB memtest entry in `grub/loopback.cfg`: `memtest86${uefi_machine_type_lower}.efi`, `if/elif` | Taken (2026-11-15) | Re-decided by Erik: loopback.cfg does reach the ISO (the menu GRUB loopback tools show) and became a Kiro menu in kiro-iso audit item 1; without the rename its UEFI memtest entry never appears |
| GRUB memtest entry in `grub/grub.cfg` | N/A (2026-11-15) | Kiro removed `grub/grub.cfg` (kiro-iso audit item 2): no grub bootmode, so it never reached the ISO. Future `grub/grub.cfg` hunks are N/A; take releng's file again only if a grub bootmode is added |
| systemd-boot memtest x64 entry (`memtest86x64.efi`) | Not for now | Kiro has never had a UEFI memtest entry. Taking it later means renaming it to `05-…` (sort-key 03 is Kiro's nomodeset) and raising `check_archiso_version` to 92-1 |
| systemd-boot memtest IA32 / AA64 / LOONGARCH64 entries | N/A | Kiro is x86_64 only and targets newer machines |
| mkarchiso copies `memtest86<arch>.efi` | Already | Builder-side; works with Kiro's profile unchanged, nothing breaks |
| `packages.aarch64`: `linux-atm` removed | N/A | Kiro has no aarch64 list |

BIOS memtest is unchanged: `memtest86+` still ships `memtest.bin`, which mkarchiso installs as `memtest` for syslinux.

## archiso 91-1 (compared against 90-1, 2026-10)

From the CHANGELOG entry "archiso profile synced with upstream archiso 91" (commit `b60cf13`).

| Change | Decision | Reason |
|--------|----------|--------|
| `profiledef.sh`: drop `buildmodes=('iso')` | Taken | `iso` is mkarchiso's default |
| Remove `airootfs/etc/modprobe.d/broadcom-wl.conf` | Taken | Empty override for a package Kiro no longer ships |
| GRUB UEFI Shell entries collapsed into `uefi_machine_type_lower` | Taken | Same behaviour, upstream patches apply cleanly |
| `%KERNEL_PARAMS%` at the end of every boot entry | Taken | Later used for `kernel_params_x86_64`; `check_archiso_version` requires 91-1 |
| Upstream deleted `airootfs/etc/mkinitcpio.d/linux.preset` | Kiro-own | Kiro builds one image per kernel and the build script retargets the preset |
| mkarchiso warns when run as root via sudo | Kiro-own | Kiro's build still runs `sudo mkarchiso`; warning only |
| aarch64 package list, `kernel_params_aarch64`, stubble DTB images, speech entries | N/A | x86_64 only |

## archiso 90-1 and 89-1

No sync decisions were recorded. What Kiro has today for those changes is in [ARCHISO_CHANGES.md](ARCHISO_CHANGES.md).
