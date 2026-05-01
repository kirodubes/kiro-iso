# CHANGELOG

> Organized by commit — newest first. Daily ISO rebuilds (version bump + mirrorlist refresh only) are grouped.

---

## 2026-05-01 — `v26.05.01.01`
- **Version bump** + mirrorlist refresh

## 2026-04-30 — `v26.04.30.01`
- **Version bump** + mirrorlist refresh (removed a mirror entry)

## 2026-04-29 — `v26.04.29.01`
- **Version bump** + mirrorlist refresh

## 2026-04-28
- **`up.sh`** — added 2 new lines
- **`profiledef.sh`** — empty file touch (no content change)
- **Version bump** `v26.04.28.01`

## 2026-04-26
- **Renamed** `setup-git-v5.sh` → `setup.sh`
- **Mirrorlist** — removed 2 entries
- **Version bump** `v26.04.26.01`

## 2026-04-25 — `v26.04.25.01`
- **Package added:** `capitaine-cursors`

## 2026-04-20 — `v26.04.20.01`
- **`systemd-resolved` enabled** — added service symlinks:
  - `dbus-org.freedesktop.resolve1.service`
  - `systemd-resolved-monitor.socket`
  - `systemd-resolved-varlink.socket`
  - `systemd-resolved.service` (sysinit)

## 2026-04-19 — `v26.04.19.01`
- **Packages added:** `edu-powermenu-git`, `edu-system-files-git`, `cpuid`
- **Desktop label** updated → `xfce4/edu-chadwm/ohmychadwm`

## 2026-04-17 — `v26.04.17.01`
- **`get-pacman-repos-keys-and-mirrors.sh`** — mirror URL updated

---

## 2026-04-16 — OOMD, Cleanup & Docs Day

Multiple commits on this date:

### Scripts & Docs
- **Added `OVERVIEW.md`** — full project structure and component documentation
- **`README.md`** — major expansion (detailed setup, features, structure)
- **Screenshots** moved to `images/` subfolder

### OOMD (Out-of-Memory Daemon)
- **Enabled `systemd-oomd`** in ISO — added service/socket symlinks, added package
- **Added OOMD slice configs:**
  - `system.slice.d/oomd.conf`
  - `user.slice.d/oomd.conf`
  - `system.conf.d/memory-accounting.conf`
- **`enable-oomd.sh`** — added full enable script (181 lines)
- **`disable-oomd.sh`** — added companion disable script
- Later cleaned up and removed both scripts (folded into ISO config directly)

### `.bashrc` Rebranding & Cleanup
- **Debranded** from `arcolinux-*` → `edu-*` aliases and tool references
- **PATH deduplication** — replaced naive `PATH=` appends with `case ":$PATH:"` guard
- **Alias cleanup:** removed ArcoLinux-specific aliases (`toboot`, `togrub`, `vbm`, `rvariety`, `keyfix`, etc.)
- **Added:** `alias u="sudo pacman -Syu"`, `alias neo="neofetch"`, `alias npicom`, `alias nchaoticmirrorlist`
- **Added `EDU-SHELLS` section** header

---

## 2026-04-15 — PCI Latency & Ananicy

- **Added `pci-latency` script** (`/usr/local/bin/pci-latency`) — 56-line optimization script
- **Added `pci-latency.service`** systemd unit + `multi-user.target.wants` symlink
- **Added `ananicy-cpp.service`** symlink — process scheduler enabled at boot
- **Added `profile.d/userbin.sh`** — ensures `~/.local/bin` is in PATH
- Later removed `pci-latency` from ISO (moved to external dotfiles)

---

## 2025-06-19 — Personal Repo

- **Added `personal_repo`** support:
  - `pacman.conf` — added `[personal_repo]` section
  - `updaterepo.sh` — script to rebuild repo database
  - Added `kiro-dummy-git` package
  - Added initial DB/files binaries

## 2025-06-17 — Installation Scripts Refactor

- **`get-pacman-repos-keys-and-mirrors.sh`** — rewrote with proper ANSI colors, error handling, `set -euo pipefail`, dynamic Chaotic-AUR package URL fetching
- **Added `install-yay-or-paru.sh`** — AUR helper installer script
- **Added `pacman.conf`** to installation scripts
- **Renamed** `get-the-keys-and-mirrors-chaotic-aur.sh` → merged into new combined script
- **Removed** `get-the-keys-and-mirrors-arcolinux.sh`

---

## 2025-05-29 — Cleanup & Simplification

- **Removed** ArcoLinux-specific scripts:
  - `arcolinux-snapper`
  - Installation flag files (`chaotics-repo`, `no-chaotics-repo`, `personal-repo`)
- **`pacman.conf`** — removed commented-out kiro/arcolinux repo blocks
- **Syslinux** — stripped down `archiso_sys-linux.cfg` (removed all but one boot entry)
- **GRUB** — removed boot menu entries, added `grub` package instead
- **Removed `virtual-machine-check.service`** from startup
- **`build-the-iso.sh`** — removed 3 outdated lines, simplified flow

---

## 2025-05-23 — Package List Expansion

- **Uncommented and added many packages:**
  - Apps: `chromium`, `gimp`, `inkscape`, `meld`, `nitrogen`, `qbittorrent`, `scrot`, `vlc`, `variety`, `simplescreenrecorder-qt6-git`
  - Utils: `galculator`, `arandr`, `baobab`, `gnome-screenshot`
- **Removed** `arc-gtk-theme`, various ArcoLinux font packages
- **`archiso/test`** — added test/scratch file (72 lines)

---

## 2025-04-29 — Versioning & Repo Setup

- **Added `change-version.sh`** — version management utility script
- **Added `up.sh`** — update/maintenance helper
- **Added `pacman.conf.kiro`** — alternate pacman config variant
- **Removed `linux-zen.preset`** — dropped zen kernel support
- **`pacman.conf`** — added Chaotic-AUR repo block

---

## 2025-04-27 — Initial Commit

- **Full ISO configuration bootstrapped** from ArcoLinux base:
  - `archiso/` — complete airootfs overlay (93 files, 4683 insertions)
  - Packages: full `packages.x86_64` list
  - Boot: GRUB, syslinux, systemd-boot EFI entries
  - Desktop: XFCE4 + chadwm/ohmychadwm
  - Services: SDDM, NetworkManager, Bluetooth, Avahi, CUPS
  - `installation-scripts/40-build-the-iso.sh` — main build automation (465 lines)
  - `setup-git-v5.sh`, `up.sh`
