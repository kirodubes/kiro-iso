# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Role

**Production** — stable kernel, tested packages, released to users. Paired with `kiro-calamares-config`.

| Repo            | Role                                                                                    | Calamares config             |
|-----------------|-----------------------------------------------------------------------------------------|------------------------------|
| `kiro-iso`      | **Production** — stable kernel, tested packages, released to users                      | `kiro-calamares-config`      |
| `kiro-iso-next` | **Beta/Testing** — experimental features, kernel changes, new packages under evaluation | `kiro-calamares-config-next` |

## Project

Custom Arch Linux ISO builder based on ArchISO. Produces a live/installable ISO with XFCE4 + ohmychadwm desktop, pre-configured packages, and systemd optimizations.

## Build Workflow

A single command does everything — version bump and build are merged:

```bash
# Build the ISO (run as normal user — script calls sudo internally)
cd build-scripts && bash build-the-iso.sh
```

- The script bumps the version (`vYY.MM.DD`) as its **Phase 2**, before the build, gated by the `bump_version` flag in the config block (default `yes`). Set `bump_version="no"` for a same-day rebuild of the currently-pinned version.
- Build output lands in `~/kiro-Out/`
- Build working directory is `~/kiro-build/` (deleted/recreated each run)
- Checksums (sha1, sha256, md5) and a pkglist are auto-generated alongside the ISO

**Do not run `build-the-iso.sh` as root.**

## Version Files

`build-the-iso.sh`'s `apply_version_bump()` (Phase 2) sets the version string (`vYY.MM.DD`) in exactly these three places — keep them in sync:

| File                             | Field                           |
|----------------------------------|---------------------------------|
| `archiso/airootfs/etc/dev-rel`   | `ISO_RELEASE=`                  |
| `archiso/profiledef.sh`          | `iso_label=` and `iso_version=` |
| `build-scripts/build-the-iso.sh` | `kiroVersion=`                  |

For a same-day rebuild that keeps the currently-pinned version, set `bump_version="no"` in the config block of `build-the-iso.sh`.

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
- `build-scripts/build-the-iso.sh` — full build pipeline (includes `apply_version_bump()` as Phase 2)
- `build-scripts/get-pacman-repos-keys-and-mirrors.sh` — installs chaotic-keyring/mirrorlist if missing
- `up.sh` — git pull → `git add --all` + commit `"update"` + push; quick-push only, not for structured commits
- `audit.sh` — installed system health checker; run on a freshly installed Kiro VM to verify all Calamares modules ran correctly

## isoLabel Must Match profiledef.sh

`isoLabel` in `build-the-iso.sh` is constructed as `kiro-${kiroVersion}-x86_64.iso`. It must start with `iso_name` from `profiledef.sh` (`kiro`) — mismatch causes the checksum phase to fail with "No such file or directory".

## Security Baseline

A full Arch vs Kiro security comparison was run 2026-05-19 — results in **`ARCH-VS-KIRO-SECURITY.md`**. All action items resolved:

- `archiso/airootfs/etc/ssh/sshd_config.d/10-archiso.conf` — **kept intentionally**. The `sshd_config.d/` directory must have at least one file or archiso won't create it on the live ISO, causing errors. The file enables root SSH for the live session; `kiro_final` removes it from the installed system. Confirmed absent post-install.
- `archiso/airootfs/etc/tmpfiles.d/cups-permissions.conf` — **added**. Enforces `600 root:cups` on CUPS config files at boot via `systemd-tmpfiles`.
- No firewall — **by design**. `iptables` is installed but intentionally has no rules.
- `virtualbox-guest-utils` / `vboxservice` — **kept intentionally** for testing convenience, despite modules not loading on `linux-lqx` without DKMS.
- `vm.overcommit_memory = 1` — **safe**: ZRAM is always active via `zram-generator` + config from `edu-system-files-git` (`zstd`, `min(ram/2, 4GB)`, priority 100).

## VirtualBox SSH Scripts

Three helper scripts live in `~/DATA/arcolinux-nemesis/scripts/`:
- `ssh-into-kiro-vb.sh` — connects to the Kiro VM (`127.0.0.1:2022`, user `erik`)
- `ssh-into-arch-vb.sh` — connects to a virgin Arch VM (`127.0.0.1:2023`, user `erik`)
- `ssh-into-riker.sh` — connects to riker, real metal Kiro machine (`192.168.1.43:22`, user `erik`)

VirtualBox scripts auto-configure NAT port forwarding (`VBoxManage controlvm natpf1` for running VMs, `modifyvm --natpf1` for stopped VMs) and handle `sshpass` + `known_hosts` cleanup automatically. The riker script just pings first then connects.

## kiro-audit (edu-system-files-git)

`audit.sh` was removed from this repo — the canonical version is `kiro-audit` in `edu-system-files-git`, installed to `/usr/local/bin/kiro-audit` on every Kiro system. Run with `sudo kiro-audit`.

Current checks (as of 2026-05-19): kernel, microcode, mkinitcpio, audio stack, Calamares cleanup, SSH override absent, kiro_final config, MAKEFLAGS CPU count, pacman repos, desktop environments, SDDM, user groups, systemd services, ZRAM, key file permissions, CUPS permissions, sysctl security baseline (8 values), failed units, ISO version, NVIDIA, bootloader, boot time/updates, package integrity.

## Release Workflow Commands

Two Claude Code slash commands formalise the release and verification workflows:

- **`/kiro-ready`** — GO/NO-GO release check (git state, TODO, DISTRO_TESTING, kiro-audit via SSH, ISO recency)
- **`/kiro-check`** — Deep source-vs-VM comparison (security files, live-env survivors, deprecated config warnings, sysctl, udev, scripts, git re-add detection)

Run `/kiro-check` after any build session. Run `/kiro-ready` before publishing.

## Known Issues

- No open known issues as of 2026-05-19. `kiro-calamares-config` removal (previously failing) now passes in kiro-audit at 93/0/0.

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
