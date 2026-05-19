# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Role

**BETA / TESTING** — this is the experimental ISO for validating new features before they go to production.

| Repo | Role | Calamares config |
|---|---|---|
| `kiro-iso` | **Production** — stable kernel, tested packages, released to users | `kiro-calamares-config` |
| `kiro-iso-next` | **Beta/Testing** — experimental features, kernel changes, new packages under evaluation | `kiro-calamares-config-next` |

Changes here must be build-tested and boot-tested before being mirrored to `kiro-iso`.
The current experiment: **Liquorix kernel** (`linux-lqx` from Chaotic-AUR) replacing the stock `linux` kernel.

### Current state (2026-05-18)

All validation items are done except one: NVIDIA `driver=nonfree` boot + DKMS against `linux-lqx-headers` on real hardware. UEFI boot, BIOS/syslinux boot, PipeWire stack, and Calamares post-install hooks (microcode, linux.preset cleanup) are all verified.

## Beta Build Workflow

**Always follow this order when testing changes across both repos:**

```
1. Make changes in kiro-calamares-config-next
2. Commit and push: cd ~/KIRO/kiro-calamares-config-next && ./up.sh
3. Wait 5–10 minutes for kiro_repo (GitHub Pages) to rebuild and serve the new package
4. Then build the ISO: cd ~/KIRO/kiro-iso-next/build-scripts && bash build-the-iso.sh
```

**Do not build the ISO immediately after pushing calamares config changes** — the repo won't have the updated package yet and the build will pull the old version.

If you only changed files inside `kiro-iso-next` (packages.x86_64, bootloader entries, syslinux, airootfs), you can skip steps 1–3 and build directly.

## Project

Custom Arch Linux ISO builder based on ArchISO. Produces a live/installable ISO with XFCE4 + ohmychadwm desktop, pre-configured packages, and systemd optimizations.

## Build Workflow

Always run these in order from `build-scripts/`:

```bash
# 1. Bump version across all version files (generates vYY.MM.DD.01)
bash change-version.sh

# 2. Build the ISO (run as normal user — script calls sudo internally)
cd build-scripts && bash build-the-iso.sh
```

- Build output lands in `~/kiro-Out/`
- Build working directory is `~/kiro-build/` (deleted/recreated each run)
- Checksums (sha1, sha256, md5) and a pkglist are auto-generated alongside the ISO

**Do not run `build-the-iso.sh` as root.**

## Version Files

`change-version.sh` updates the version string (`vYY.MM.DD.01`) in exactly these three places — keep them in sync:

| File | Field |
|---|---|
| `archiso/airootfs/etc/dev-rel` | `ISO_RELEASE=` |
| `archiso/profiledef.sh` | `iso_label=` and `iso_version=` |
| `build-scripts/build-the-iso.sh` | `kiroVersion=` |

To bump the `.01` suffix for same-day rebuilds, edit `extra="01"` in `change-version.sh`.

## Nvidia Driver Selection

In `build-scripts/build-the-iso.sh`, set the `nvidia_driver` variable in the **config block at the top of the file** before building:

- `open` — nvidia-open-dkms (default, modern GPUs)
- `580xx` — nvidia-580xx-dkms (legacy)
- `390xx` — nvidia-390xx-dkms (legacy)

The script manipulates `packages.x86_64` in the build folder to inject the chosen driver set.

## Architecture

The build pipeline:
1. `build-the-iso.sh` copies `archiso/` into `~/kiro-build/archiso/`
2. Fetches latest `.bashrc` from `erikdubois/edu-shells` into `airootfs/etc/skel/`
3. Pre-populates the pacman GPG keyring (archlinux + chaotic) in the build tree
4. Injects the correct NVIDIA packages into the package list
5. Calls `mkarchiso` to squash and produce the ISO

`archiso/airootfs/` is the overlay applied on top of the base Arch system — files here end up at `/` on the live ISO. Key subdirectories:
- `etc/` — system config (pacman, NetworkManager, locale, hostname, polkit, modprobe)
- `root/` — root user's home on the live system
- `usr/` — additional binaries/configs

## Package Repositories

Defined in `archiso/pacman.conf` (used during ISO build) and `build-scripts/pacman.conf`:

- `[core]` / `[extra]` / `[multilib]` — standard Arch mirrors
- `[kiro_repo]` — `https://kirodubes.github.io/$repo/$arch` (SigLevel Never)
- `[nemesis_repo]` — `https://erikdubois.github.io/$repo/$arch` (SigLevel Never)
- `[chaotic-aur]` — requires `chaotic-keyring` + `chaotic-mirrorlist` on the build host
- `[personal_repo]` — optional local repo, commented out by default (see in-file comment for path)

## Key Files

- `archiso/airootfs/etc/dev-rel` — ISO version string (`ISO_RELEASE=`, `ISO_CODENAME=`, `ISO_BUILD=`)
- `archiso/packages.x86_64` — full package list (one package per line, comments with `#`)
- `archiso/profiledef.sh` — ArchISO profile: name, label, version, bootmodes, compression
- `archiso/pacman.conf` — pacman config used inside the ISO build
- `archiso/efiboot/loader/entries/` — UEFI boot entries (kernel + initrd paths; must match kernel in packages.x86_64)
- `build-scripts/build-the-iso.sh` — full build pipeline
- `build-scripts/get-pacman-repos-keys-and-mirrors.sh` — installs chaotic-keyring/mirrorlist if missing
- `change-version.sh` — version bump script
- `up.sh` — git pull → `git add --all` + commit `"update"` + push; quick-push only, not for structured commits
- `audit.sh` — installed system health checker; run on a freshly installed Kiro VM to verify all Calamares modules ran correctly

## isoLabel Must Match profiledef.sh

`isoLabel` in `build-the-iso.sh` is constructed as `kiro-next-${kiroVersion}-x86_64.iso`. It must start with `iso_name` from `profiledef.sh` (`kiro-next`) — not just `kiro`. Mismatch causes the checksum phase to fail with "No such file or directory".

## Known Issues

- **`kiro-calamares-config-next` not removed post-install** — `kiro_final`'s final cleanup step runs `pacman -R --noconfirm kiro-calamares-config-next` inside a `try/except` that swallows failures silently. The package is removable manually (`sudo pacman -R kiro-calamares-config-next`) but the root cause (likely a pacman lock race during Calamares) needs investigation. Confirmed on v26.05.18.01 VirtualBox install.

## pacman.conf — Installed System vs Build Time

There are three pacman.conf files with different roles:
- `archiso/pacman.conf` — used by `mkarchiso` during the ISO build; includes `kiro_repo`
- `archiso/airootfs/etc/pacman.conf` — ends up on the installed system; does NOT include `kiro_repo` (intentional — kiro_repo is used by Calamares at install time only)
- `build-scripts/pacman.conf` — host-side reference for setting up Chaotic-AUR on the build machine

## Changelog Style

When updating `CHANGELOG.md`:
- **Newest commits first**
- **Group pure daily rebuilds** (version bump + mirrorlist only) into a single line: `## YYYY-MM-DD — vXX.XX.XX.XX` with bullet `- **Version bump** + mirrorlist refresh`
- **Separate substantive changes** into their own dated section with prose paragraphs explaining what changed, why it was done, and what benefit it brings — not just a list of file names
- Use **bold** for file names, package names, and key actions
- Use sub-headers (`###`) for multi-commit days with distinct themes
- **Elaborate, not concise** — each entry should read like a developer-facing narrative, not a dry diff summary

## Script Template

All bash scripts in this repo follow the standard template:
1. `#!/bin/bash` + `set -euo pipefail`
2. Header block (Author / Website / DO NOT JUST RUN banner)
3. `SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"`
4. TTY-safe colors block (`tput` with `[[ -t 1 ]]` guard, fallback to empty strings)
5. Log functions: `log_section` (green), `log_info` (blue), `log_warn` (yellow), `log_error` (red), `log_success` (green)
6. `on_error()` + `trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR`
7. Functions
8. `main()` ending with `log_success "$(basename "$0") done"`
9. `main "$@"`

All four build scripts (`build-the-iso.sh`, `get-pacman-repos-keys-and-mirrors.sh`, `install-yay-or-paru.sh`, `change-version.sh`) conform to this template as of 2026-05-18.

## Commit Conventions

Semantic commit messages are in use:
- `feat: add <package/feature>`
- `fix: <what was broken>`
- `chore: version bump vXX.XX.XX.XX`
- `refactor: <what changed and why>`
- `docs: update CHANGELOG / README`

## Branding Notes

- Project was originally based on ArcoLinux — references to `arcolinux-*` are being replaced with `edu-*` or `kiro-*` equivalents
- Desktop environments: XFCE4 (primary), ohmychadwm
- Package repos: Chaotic-AUR + optional local `personal_repo`
- Git remote uses SSH alias `github.com-edu` (configured by `setup.sh`)
