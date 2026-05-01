# CHANGELOG

> Complete history of the KIRO ISO project — newest first. Each entry explains not just what changed, but why it was done and what benefit it brings. Daily rebuilds (version bump + mirrorlist refresh only) are grouped into a single line.

---

## 2026-05-01 — `v26.05.01.01`
- **Version bump** + mirrorlist refresh

## 2026-04-30 — `v26.04.30.01`

- **Version bump** + mirrorlist refresh — removed one stale mirror entry to keep the list clean and reduce the chance of hitting a dead server on first boot

## 2026-04-29 — `v26.04.29.01`
- **Version bump** + mirrorlist refresh

---

## 2026-04-28 — `v26.04.28.01`

### `up.sh` — maintenance improvements

Two new lines were added to **`up.sh`**, the daily ISO maintenance helper script. This script is what drives the version bump + mirrorlist cycle that keeps every ISO build fresh and reproducible.

---

## 2026-04-26 — `v26.04.26.01`

### Script renamed: `setup-git-v5.sh` → `setup.sh`

The developer environment bootstrap script was renamed from **`setup-git-v5.sh`** to the simpler **`setup.sh`**. The old name carried an explicit version number in the filename, which is an anti-pattern — the version is already tracked by git. The new name is cleaner, easier to type, and makes it obvious what the script does without implying it is just one in a long series of sequential versions.

### Mirrorlist cleanup

Two mirror entries were removed from the embedded mirrorlist. Stale or unreliable mirrors slow down the first `pacman -Syu` run on a freshly booted live system, so keeping the list curated is worth the small maintenance cost.

---

## 2026-04-25 — `v26.04.25.01`

### Package added: `capitaine-cursors`

**`capitaine-cursors`** is a clean, modern X11 cursor theme inspired by macOS. Adding it to the ISO ensures that every desktop environment — XFCE4, ohmychadwm, and edu-chadwm — ships with a polished, HiDPI-aware cursor out of the box, rather than falling back to the default X11 arrow. This is a small quality-of-life detail that significantly improves the first-impression polish of the live session.

---

## 2026-04-20 — `v26.04.20.01`

### Enabled `systemd-resolved` as a DNS resolver

Four systemd symlinks were added to enable **`systemd-resolved`** at boot:

- `dbus-org.freedesktop.resolve1.service` — exposes the resolver on D-Bus so applications can query it via the standard API
- `systemd-resolved-monitor.socket` — allows runtime monitoring of DNS state
- `systemd-resolved-varlink.socket` — the modern varlink IPC socket used by newer tools
- `systemd-resolved.service` (under `sysinit.target.wants`) — starts the resolver early in boot

**Why this matters:** `systemd-resolved` is the recommended DNS resolver for systemd-based systems. It provides automatic mDNS (Avahi-style local hostname resolution), DNSSEC validation, DNS-over-TLS support, and proper integration with VPNs and per-interface DNS settings. Without it enabled, the live system falls back to basic `/etc/resolv.conf` parsing, which can cause subtle failures on networks with mDNS hostnames or split-horizon DNS. This change pairs with the `nsswitch.conf` update made on 2026-03-22 (which set the host resolution order to `files mymachines mdns_minimal [NOTFOUND=return] resolve dns wins myhostname`) to create a fully modern DNS stack that works reliably on home networks, office environments, and bare-metal servers alike.

---

## 2026-04-19 — `v26.04.19.01`

### New packages: `edu-powermenu-git`, `edu-system-files-git`, `cpuid`

- **`edu-powermenu-git`** — adds the KIRO/edu branded power menu (shutdown, reboot, suspend, lock) that integrates consistently with all three desktop environments. Previously users had to reach into a terminal or use desktop-specific logout dialogs; this gives a single consistent entry point regardless of which WM is active.

- **`edu-system-files-git`** — pulls in the curated set of system configuration files maintained in the edu ecosystem. These cover sensible defaults for things like font rendering, GTK theming, locale settings, and input handling. Shipping them through a package (rather than baking raw config files into the ISO airootfs) means they can be updated independently via `pacman -Syu` without requiring a full ISO rebuild.

- **`cpuid`** — a command-line tool that decodes the CPU identification registers and reports detailed processor information (family, model, features, cache topology). Useful for hardware debugging, virtualization compatibility checks, and verifying that CPU feature flags needed for specific workloads are actually present. Particularly valuable on a live ISO where users may be running it on unfamiliar hardware.

### Desktop label updated

The ISO desktop label in **`build-the-iso.sh`** was updated from `xfce4/chadwm` to `xfce4/edu-chadwm/ohmychadwm`. This accurately reflects the three desktop environments that ship in the ISO and makes it immediately clear to anyone reading the build output (or examining the ISO metadata) what they are getting.

---

## 2026-04-17 — Mirror URL fix in `get-pacman-repos-keys-and-mirrors.sh`

The Chaotic-AUR mirror URL inside the installation script was updated to point to the current active endpoint. Mirror URLs for Chaotic-AUR have changed over the project's lifetime as the infrastructure evolved; using a stale URL causes the Chaotic-AUR key import and repository setup to fail silently or with a confusing error, which blocks the entire installation workflow for users who want AUR packages. Keeping this URL current is maintenance work that directly affects the user's first-boot experience.

---

## 2026-04-16 — OOMD, Shell Debranding, and Documentation Day

This was a dense day of work with multiple distinct themes. Seven commits landed.

### systemd Out-of-Memory Daemon (OOMD) — fully integrated

The live ISO now ships with **`systemd-oomd`** enabled and configured. OOMD is systemd's built-in out-of-memory killer, and unlike the kernel's OOM killer — which is a last resort that can freeze a system for tens of seconds before acting — OOMD monitors memory pressure proactively at the cgroup level and kills the heaviest-consuming processes before the system becomes completely unresponsive.

The following was added:

- **`archiso/airootfs/etc/systemd/oomd.conf`** — global OOMD configuration tuned for desktop workloads: swap usage threshold and memory pressure thresholds set to intervene before the system locks up
- **`system.slice.d/oomd.conf`** — applies OOMD monitoring to all system-level services, so a runaway daemon doesn't take the entire system down
- **`user.slice.d/oomd.conf`** — applies OOMD monitoring to the user session, so a memory-hungry browser or desktop app triggers a clean kill rather than a kernel panic cascade
- **`system.conf.d/memory-accounting.conf`** — enables per-cgroup memory accounting, which is a prerequisite for OOMD to work; without this, OOMD cannot observe per-process memory usage

The service and socket symlinks (`dbus-org.freedesktop.oom1.service`, `systemd-oomd.service`, `systemd-oomd.socket`) were added to ensure OOMD starts automatically on boot.

During the day, both an `enable-oomd.sh` and `disable-oomd.sh` helper script were created and then removed. The initial plan was to provide opt-in scripts for post-install systems, but the right approach turned out to be integrating OOMD directly into the ISO configuration so every boot has it active without any user intervention. The scripts were folded into the static config and deleted.

### `.bashrc` — ArcoLinux debranding and shell hygiene

The default **`/etc/skel/.bashrc`** that every new user inherits received a significant cleanup pass, completing the transition away from the ArcoLinux branding that was present in the original base.

**What was removed:**

- `alias toboot`, `togrub`, `torefind` — these called `arcolinux-toboot`, `arcolinux-togrub`, `arcolinux-torefind`, scripts that do not exist in a KIRO system
- `alias vbm` — called `arcolinux-vbox-share`, an ArcoLinux-specific VirtualBox helper
- `alias rvariety`, `rkmix`, `rconky` — called ArcoLinux removal scripts; replaced `rvariety` with the edu equivalent `edu-remove-variety`
- `alias whichvga` — updated from `arcolinux-which-vga` to `edu-which-vga`
- `alias narcomirrorlist` — replaced with `alias nchaoticmirrorlist` pointing to the Chaotic-AUR mirrorlist, which is actually present on the system
- `alias iso`, `isoo` — these printed ArcoLinux version info; removed entirely since the KIRO version is in `/etc/dev-rel`
- `alias vbm` — ArcoLinux VirtualBox mounting helper, not applicable

**What was added:**

- `alias u="sudo pacman -Syu"` — a short, memorable shortcut for the most common maintenance operation
- `alias neo="neofetch"` — quick system info display
- `alias npicom="$EDITOR ~/.config/arco-chadwm/picom/picom.conf"` — quick editor access to the picom compositor config, useful for chadwm users tuning their compositor
- `alias nchaoticmirrorlist="sudo $EDITOR /etc/pacman.d/chaotic-mirrorlist"` — quick access to edit the Chaotic-AUR mirrorlist
- `### EDU-SHELLS` section header — organizes the file to match the structure used in the edu-shells package

**PATH deduplication fix:**

The old `~/.bashrc` used naive `PATH="$HOME/.bin:$PATH"` assignments to add local directories to `PATH`. If `.bashrc` is sourced more than once (which happens in nested shells, tmux, and some login scenarios), these assignments duplicate the same directory in `PATH` repeatedly. The fix uses the standard `case ":$PATH:" in *":$dir:"*` guard pattern, which is a well-known shell idiom that only appends the directory if it is not already present. This prevents PATH from ballooning with repeated entries and avoids subtle issues where the wrong version of a tool might be picked up due to a duplicated and reordered PATH.

### Documentation — `OVERVIEW.md` added, `README.md` expanded

A new **`OVERVIEW.md`** file was added (214 lines) with a complete structural breakdown of the repository: what each directory contains, how the build system works, which services are enabled by default, and how the three desktop environments relate to each other. This is intended as a quick-start reference for anyone contributing to the project or trying to understand the ISO without having to read every config file individually.

**`README.md`** was nearly tripled in size (from ~90 lines to ~370 lines), adding detailed sections on:

- Prerequisites and build steps
- What each package category includes and why
- How to customize the package list
- Service topology (which services are enabled and what they do)

### Screenshots reorganized into `images/`

The four screenshot images (`kiro-chadwm.jpg`, `kiro-ohmychadwm.jpg`, `kiro-xfce.jpg`, `kiro.jpg`) were moved from the repository root into a dedicated **`images/`** subfolder, and the `README.md` image references were updated accordingly. This is a housekeeping change that keeps the root of the repository clean — a flat root directory with a mix of scripts, configs, and image files makes it hard to quickly find what you are looking for.

---

## 2026-04-15 — PCI Latency, Optimization Config Separation

### System optimization configs moved to `edu-dot-files`

Several systemd drop-in config files that were previously baked directly into the ISO airootfs were removed:

- `systemd/journald.conf.d/volatile-storage.conf`
- `systemd/system.conf.d/10-parallel-services.conf` (at this point)

These configs are now delivered by the **`edu-dot-files-git`** package instead. This is an important architectural decision: configs that live inside the ISO can only be updated by rebuilding and redistributing the ISO, which is a multi-hundred-megabyte operation. Configs delivered by a package can be updated with a simple `pacman -Syu`. Moving non-ISO-critical configuration out of the airootfs and into the dotfiles package reduces the ISO size slightly and means users always get the latest tuning without waiting for a new ISO release.

### PCI Latency optimization — added and removed in the same day

A **`pci-latency`** script was added (`/usr/local/bin/pci-latency`, 56 lines) along with a `pci-latency.service` systemd unit that runs it at boot. The script reads each PCI device's latency timer register and sets it to an optimal value, which can reduce audio crackling under load and improve I/O responsiveness, particularly on older hardware and systems with multiple PCI peripherals competing for bus time.

Later the same day, the script and service were removed from the ISO. The decision was made to keep PCI latency tuning in the external dotfiles (`edu-dot-files`) rather than the ISO configuration, for the same reason as above: it is a user-facing optimization rather than something required for the live session to function. Users who want it can install the dotfiles package. This keeps the ISO lean and focused on boot-critical configuration only.

### `ananicy-cpp.service` enabled

**Ananicy-cpp** (Another Auto NICe daemon, C++ rewrite) is a process scheduler that automatically adjusts process priorities and I/O scheduling classes based on a curated rules database. Enabling it at boot via a symlink means the live session immediately benefits from better CPU scheduling: interactive applications like browsers and terminals get higher priority, build tools and background processes get lower priority, and the system feels more responsive under mixed workloads. This pairs with `cachyos-ananicy-rules-git` (already in the package list) which provides the extensive rules database.

### `profile.d/userbin.sh` — `~/.local/bin` in PATH at login

A small `profile.d` script was added to ensure `~/.local/bin` is present in `PATH` for all login sessions. This is where pip, pipx, cargo, and other language-specific installers place user-owned executables. Without this, tools installed to `~/.local/bin` are invisible to the shell unless the user manually adds the path, which is a common source of confusion on Arch-based systems where the default shell config is minimal.

---

## 2026-04-14 — Power Management Iteration, Nanorc, Boot Config

This day involved several commits that explored and then refined the power management configuration.

### Power management tuning

The power management stack was iterated through several states:

1. **`tlp` removed, `tuned` added** — TLP (Laptop Power Saving) was replaced by `tuned`, a daemon from Red Hat/Fedora that uses profiles to tune system performance vs. power tradeoffs. Unlike TLP, which is focused primarily on laptops and batteries, `tuned` works equally well on desktops and servers, making it a better fit for a general-purpose ISO. `upower` was added at the same time — it provides a D-Bus API for battery and power state that desktop environments use to show charge level and trigger suspend.

2. **CPU governor config added** — `cpupower` was added with a config file (`/etc/default/cpupower`) setting `governor='performance'`, which keeps the CPU at maximum frequency. For a live ISO used for testing and installation, maximum performance is generally preferable over power saving.

3. **`cpupower` and `tuned` removed** — After testing, both were removed from the package list. The conclusion was that for a live ISO session, the kernel's default scheduler and governor behavior is sufficient, and adding power management daemons introduces complexity without clear benefit in a short-lived session. `alsa-utils` was also removed (ALSA is handled via the higher-level PipeWire/PulseAudio stack already present). `ntp` was removed in favor of `systemd-timesyncd` which is already part of systemd.

### `archlinux-tweak-tool` upgraded to GTK4

The **`archlinux-tweak-tool-git`** package was replaced with **`archlinux-tweak-tool-gtk4-git`**. The GTK4 version is the actively maintained branch; the GTK3 version is legacy. This ensures the tweak tool works correctly under modern GTK theme configurations and is compatible with the libadwaita-based theming that newer GTK4 applications use.

### `10-parallel-services.conf` — systemd timeout tuning

A new drop-in config at `system.conf.d/10-parallel-services.conf` was added with two settings:

```ini
[Manager]
DefaultTimeoutStopSec=10s
DefaultTimeoutAbortSec=5s
```

The default `DefaultTimeoutStopSec` is 90 seconds — meaning systemd will wait up to 90 seconds for a service to stop before killing it. On a live ISO, this makes shutdown feel extremely slow if any service hangs. Reducing it to 10 seconds means a clean shutdown completes in well under 30 seconds total even with misbehaving services. `DefaultTimeoutAbortSec=5s` similarly limits the time given to services that are force-killed before systemd gives up entirely.

### `nanorc` — syntax highlighting for the default editor

A comprehensive **`nanorc`** configuration file (349 lines) was added to the ISO's `/etc/nanorc`. The default nano on Arch Linux ships with minimal syntax highlighting; this config enables color-coded syntax for: shell scripts, Python, C/C++, Makefiles, INI files, systemd unit files, pacman config files, and several other formats. Since `nano` is the default editor in the ISO (set in `.bashrc`), this means users editing config files during installation get a readable, color-coded experience rather than plain monochrome text.

---

## 2026-03-27 — systemd-networkd: Type-Based Interface Matching

The network configuration files in `archiso/airootfs/etc/systemd/network/` were updated to use type-based interface matching instead of name-based glob matching:

**Before:**

- `20-ethernet.network`: matched `Name=en*` and `Name=eth*`
- `20-wlan.network`: matched `Name=wl*`
- `20-wwan.network`: matched `Name=ww*`

**After:**

- `20-ethernet.network`: matches `Type=ether` with `Kind=!*` to exclude virtual interfaces
- `20-wlan.network`: matches `Type=wlan`
- `20-wwan.network`: matches `Type=wwan`

**Why this matters:** Predictable Network Interface Names (the `en*`/`wl*` prefix convention) are not guaranteed. On some systems, particularly with USB ethernet adapters, VM guests, or exotic hardware, interface names may not follow the `en`/`wl` convention. By matching on `Type=` instead of `Name=`, the network configuration works correctly on any hardware regardless of what the kernel chose to name the interface. The `Kind=!*` filter on the ethernet rule excludes virtual ethernet interfaces (veth, bridge members, etc.) which should not be managed by the live session's network config — this was an existing issue noted in the previous config via a comment referencing Arch bug #70892.

---

## 2026-03-22 — `nsswitch.conf` — Host Resolution Order Fixed

The Name Service Switch configuration (`/etc/nsswitch.conf`) was updated to change the `hosts:` line:

**Before:** `hosts: mymachines resolve [!UNAVAIL=return] files dns mdns wins myhostname`

**After:** `hosts: files mymachines mdns_minimal [NOTFOUND=return] resolve dns wins myhostname`

**Why this matters:** The original order put `resolve` (systemd-resolved) before `files`, meaning `/etc/hosts` was not consulted first. This caused two problems: (1) local hostname overrides in `/etc/hosts` were ignored, which is unexpected behavior; (2) on systems where `systemd-resolved` is not yet started, host lookups could time out instead of falling back gracefully. The new order matches the recommended Arch Linux configuration: `files` first (so `/etc/hosts` always wins), then `mymachines` (for systemd container hostnames), then `mdns_minimal` with `[NOTFOUND=return]` (mDNS for `.local` hostnames, with early exit to avoid false positives), then `resolve` (systemd-resolved for everything else), then `dns` (direct DNS as a fallback).

---

## 2026-03-14 — Package added: `lxappearance`

**`lxappearance`** is the GTK theme, icon, and font configuration tool from the LXDE project. While KIRO uses XFCE4's settings manager for the primary desktop, `lxappearance` is indispensable for configuring GTK appearance in the tiling window manager environments (ohmychadwm, edu-chadwm) where there is no XFCE settings daemon running. Without it, users of those WMs would have no GUI way to change the GTK theme or cursor, and would need to edit `~/.config/gtk-3.0/settings.ini` by hand.

---

## 2025-12-26 — `up.sh` Major Rewrite

The **`up.sh`** daily maintenance script — used to bump the version, refresh the mirrorlist, and prepare each new ISO build — was rewritten from scratch with significantly better engineering:

**Before:** Basic bash script with `set -eo pipefail`, inline code, and a simple toggle variable for mirrorlist fetching.

**After:**

- `#!/usr/bin/env bash` shebang instead of `#!/bin/bash` — more portable and respects the user's PATH
- `set -Eeuo pipefail` — the `-E` flag ensures ERR traps are inherited by functions and subshells, `-u` treats unset variables as errors (catches typos in variable names), together making the script fail fast and visibly rather than silently producing wrong results
- Dedicated helper functions: `die()`, `info()`, `ensure_paths()`, `write_static_mirrorlist()` — replacing inline code with named functions makes the script readable and testable
- Configurable connection timeouts (`CONNECT_TIMEOUT=5`, `MAX_TIME=20`, `RETRIES=3`) — instead of letting curl hang indefinitely on a slow mirror, these limits ensure the script fails predictably if the network is unavailable
- `trap cleanup EXIT` — a cleanup handler that removes temporary files even if the script exits with an error, preventing stale temp files from accumulating

This rewrite makes the daily build process more reliable, particularly in CI-like environments or when the network is flaky.

---

## 2025-12-21 — Removed `nvidia-dkms` from package list

**`nvidia-dkms`** was removed from `packages.x86_64`. The DKMS version of the NVIDIA driver requires the kernel headers and a build toolchain at install time, and rebuilds the kernel module every time the kernel updates. On a live ISO, this is inappropriate: the ISO cannot know which NVIDIA driver will match the user's card, the build process is slow, and DKMS modules built in the live session do not persist to the installed system. Users with NVIDIA hardware should install the appropriate driver (either `nvidia` or `nvidia-dkms`) after installation via the KIRO hardware detection tooling. The open-source `nouveau` driver (handled via mesa) remains available for basic display output during the live session.

---

## 2026-04-09 — Application Layer Expansion

### New user-facing applications

A substantial set of new packages was added to bring the ISO closer to a complete daily-driver environment:

- **`gcolor3`** — a modern GTK3 color picker with hex, RGB, and HSL output. Useful for design work, theming, and web development. A basic but frequently-needed tool that was absent.
- **`hw-probe`** — uploads hardware probe data to the Linux Hardware Database (`linux-hardware.org`), helping the community track hardware compatibility. Also useful locally as a `lshw`-style diagnostic tool. (Note: an initial typo `hwprobe` was corrected to `hw-probe` in a follow-up commit.)
- **`resources`** — a GNOME-style system monitor with per-process CPU, memory, GPU, and network usage. A modern alternative to the aging `gnome-system-monitor` and more informative than plain `htop` for desktop users.
- **`signal-desktop`** + **`signal-in-tray`** — Signal, the end-to-end encrypted messaging application. Including it in the ISO signals (no pun intended) that privacy is a priority. `signal-in-tray` adds a system tray icon so Signal can run in the background without occupying a taskbar slot.
- **`shortwave`** — an internet radio player with a searchable station database. A lightweight application for background music during work sessions.
- **`spotify`** — the desktop Spotify client for music streaming. While not open-source, it is one of the most commonly requested applications on Linux and including it avoids users having to go through the AUR manually after installation.

### `archlinux-logout` upgraded to GTK4

**`archlinux-logout-git`** was replaced with **`archlinux-logout-gtk4-git`**, the actively maintained GTK4 port of the ArcoLinux logout dialog. The GTK3 version is no longer developed. The GTK4 version is visually identical but built on the modern toolkit, ensuring compatibility with current GNOME and GTK theming systems.

### Build script improvements

Two fixes landed in **`build-the-iso.sh`**:

1. **`set -e` re-enabled** — the `set -e` flag (exit on error) had been commented out with `#set -e`. This meant build failures could be silently swallowed and the script would continue in a broken state, potentially producing a corrupt ISO. Re-enabling it makes the build fail loudly and immediately when something goes wrong.

2. **`installed_dir` path detection fixed** — the previous method used `dirname $(readlink -f $(basename pwd))`, which is unreliable: `basename pwd` just returns the directory name without a path, so `readlink -f` was resolving relative to the current directory in an unpredictable way. The replacement `"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."` is a standard idiom that correctly resolves the script's parent directory regardless of how or from where the script is invoked.

---

## 2026-04-05 — Window Manager Package Additions

Several packages needed by the tiling window manager environments (ohmychadwm, edu-chadwm) were added:

- **`fastcompmgr-git`** — a lightweight X11 compositor forked from `compton`. While `picom` is used for the main chadwm setup, `fastcompmgr` is an alternative that some chadwm configurations prefer for its lower overhead on older hardware.
- **`maim`** — a screenshot tool designed as a modern replacement for `scrot`. It supports region selection, window selection, and piping output to other tools. Used by chadwm keybindings for quick screenshots.
- **`octopi`** — a Qt5 graphical frontend for pacman. Provides a package manager GUI for users who prefer not to use the terminal for package operations. Important for the live ISO where new users may be evaluating the system.
- **`redshift`** — adjusts the screen's color temperature based on time of day (warmer/orange at night, neutral during the day). Reduces eye strain during extended sessions. Unlike `f.lux`, Redshift is fully open-source and integrates cleanly with both X11 and Wayland.
- **`xautolock`** — automatically locks the screen after a configurable idle timeout. The chadwm setups use `xautolock` + `i3lock` (or similar) to implement session locking, since there is no desktop environment managing this automatically.
- **`xclip`** — a command-line clipboard interface. Used heavily in chadwm dotfiles for copy/paste operations in scripts (e.g., copying a color hex code from `gcolor3` into a config file).
- **`autorandr`** was removed — it was present in the chadwm package section but is not used by any of the window manager configurations in the ISO. `autorandr` is a tool for automatically applying monitor layout profiles, a function that is handled by `arandr` (which is already in the list) for interactive use and by `xrandr` scripts for programmatic use.

---

## 2025-06-19 — Personal Repository Support

A local **`personal_repo`** infrastructure was added for hosting custom or private packages that should not go into the public Chaotic-AUR:

- **`pacman.conf`** — a `[personal_repo]` section was added, pointing to a local database file. This allows the ISO build system to install packages from a local repo during the build, without those packages needing to be available on the internet.
- **`updaterepo.sh`** — a helper script that rebuilds the local repository database using `repo-add`. Run after adding a new `.pkg.tar.zst` to the repo directory.
- **`kiro-dummy-git`** — a placeholder package used to test that the personal repo infrastructure is working before real packages are added.
- Initial database and files binaries included to bootstrap the repo structure.

This feature allows KIRO-specific packages (branding assets, configuration packages, proprietary binaries) to be installed without publishing them to a public repository.

---

## 2025-06-17 — Installation Scripts Refactor

The scripts used to set up Chaotic-AUR on a freshly installed system were rewritten and consolidated:

### `get-pacman-repos-keys-and-mirrors.sh` — complete rewrite

The new script replaced both the old `get-the-keys-and-mirrors-chaotic-aur.sh` and `get-the-keys-and-mirrors-arcolinux.sh` with a single, unified script. Key improvements:

- **ANSI color output** — progress steps, warnings, and errors are now color-coded, making it immediately obvious when something goes wrong vs. completing successfully
- **`set -euo pipefail`** — the script now fails fast on any error rather than continuing in a broken state. The `-u` flag catches undefined variable references (typos in variable names), and `pipefail` ensures errors in piped commands are not masked
- **Dynamic Chaotic-AUR package URL fetching** — instead of hardcoding the URL of the Chaotic-AUR keyring and mirrorlist packages, the script now fetches the current package URL dynamically from the Chaotic-AUR CDN. This means the script continues to work even when the Chaotic-AUR team updates their package versioning scheme
- **Error handling** — each major step (key import, mirrorlist installation, pacman.conf editing) now has explicit error handling and user-readable failure messages

### `install-yay-or-paru.sh` added

A new script for bootstrapping an AUR helper (either `yay` or `paru`) was added. AUR helpers are not available in the official Arch repositories, so installing one requires a manual `git clone` + `makepkg` process. This script automates that process, detecting which helper the user prefers and handling the bootstrap from scratch.

### `pacman.conf` added to installation scripts

A template **`pacman.conf`** was added to the `installation-scripts/` directory for use as a reference during post-install setup, pre-configured with the Chaotic-AUR repository block.

---

## 2025-05-29 — ArcoLinux Cleanup and Simplification

A focused cleanup pass removed ArcoLinux-specific infrastructure that was no longer needed:

### Scripts removed

- **`arcolinux-snapper`** — ArcoLinux's BTRFS snapshot helper. KIRO does not mandate BTRFS, so this script was unused and confusing to have present.
- **Installation flag files** (`chaotics-repo`, `no-chaotics-repo`, `personal-repo`) — these were marker files used by the ArcoLinux build system to conditionally include repositories. The KIRO build system handles this differently, and these files served no function.

### `pacman.conf` cleaned up

The ISO's embedded `pacman.conf` had several commented-out sections referencing the ArcoLinux and Kiro package repositories from earlier development iterations. These were removed, leaving only the active repository configuration (Chaotic-AUR + optional `personal_repo`). Commented-out repository blocks are confusing because they imply the repositories exist and could be uncommented, when in reality they are stale references.

### Syslinux boot menu simplified

The `archiso_sys-linux.cfg` (syslinux boot configuration) was stripped down to a single, clean boot entry. The original ArcoLinux config had multiple boot options (safe mode, various kernel parameters), most of which were not relevant to KIRO and added visual noise to the BIOS boot menu. A single, well-labeled default entry is cleaner and reduces the chance of a user accidentally booting with the wrong parameters.

### GRUB simplified; `grub` package added

The GRUB boot menu entries were similarly reduced, and the `grub` package itself was added to `packages.x86_64`. This ensures the installed system has GRUB available for configuration after installation, and that the live session's boot menu is clean and minimal.

### `virtual-machine-check.service` removed

This service — inherited from ArcoLinux — detected whether the system was running inside a VM and applied VM-specific tweaks at boot. Removing it was the right call: the service added boot time, and any VM-specific configuration should be handled by the VM guest additions packages (`open-vm-tools`, `virtualbox-guest-utils`) rather than a custom detection service.

### `build-the-iso.sh` simplified

Three outdated lines in the build script that referenced ArcoLinux-specific paths and logic were removed, simplifying the build flow.

---

## 2025-05-23 — Package List Expansion

The ISO package list received a major expansion, shifting from a minimal configuration to a more complete daily-driver environment:

### Applications added

- **`chromium`** — the open-source Chromium browser, complementing the existing Firefox install. Having both browsers available is useful for web development testing and for users who prefer Chromium's lower memory overhead compared to Chrome.
- **`gimp`** — the GNU Image Manipulation Program. Essential for any image editing work, from quick photo corrections to full compositing.
- **`inkscape`** — vector graphics editor. Pairs with GIMP for a complete open-source graphics workflow.
- **`meld`** — a visual diff and merge tool. Invaluable for comparing config files, reviewing patches, and resolving merge conflicts. Much more approachable than `diff` for users who prefer a GUI.
- **`nitrogen`** — a lightweight wallpaper manager for X11. Used by the chadwm environments to set the desktop background (XFCE4 handles this through its own settings manager).
- **`qbittorrent`** — a clean, Qt-based torrent client. Useful for downloading Arch-based ISO files, large open-source archives, and similar content.
- **`scrot`** — a command-line screenshot tool. Used in various keyboard shortcut bindings in the window manager configs.
- **`vlc`** — the VLC media player. Handles virtually every audio and video format without requiring additional codec packages.
- **`variety`** — a wallpaper changer that can download images from Flickr, NASA APOD, Reddit, and other sources on a schedule. Keeps the desktop visually fresh.
- **`simplescreenrecorder-qt6-git`** — a screen recorder with an intuitive GUI. The Qt6 build is preferred over the older Qt5 version for better HiDPI support and compatibility with modern display systems.

### Utilities added

- **`galculator`** — a scientific calculator with both standard and expression modes, GTK-based
- **`arandr`** — a graphical frontend for `xrandr` for managing monitor arrangements; essential for multi-monitor setups
- **`baobab`** — a disk usage visualizer (GNOME Disk Usage Analyzer). Makes it easy to identify what is consuming storage on a system being evaluated for installation
- **`gnome-screenshot`** — screenshot tool with timed capture and area selection

### Packages removed

- **`arc-gtk-theme`** — removed in favor of the `edu-arc-dawn-git` branded theme (already in the list)
- Several ArcoLinux font packages — these were ArcoLinux-branded font collections that served no purpose in a KIRO system

---

## 2025-04-29 — Versioning and Repository Infrastructure

### `change-version.sh` added

A dedicated script for bumping the ISO version across all files that embed it was added. Without this, version bumping requires manually editing `dev-rel`, `profiledef.sh`, `build-the-iso.sh`, and potentially other files — an error-prone process that inevitably leads to version mismatches. `change-version.sh` updates all of these in a single operation.

### `up.sh` added

The **`up.sh`** script was introduced as the daily maintenance helper. Running it refreshes the mirrorlist and calls `change-version.sh` to bump the date-based version string, preparing the working tree for a new build. This script is the single entry point for the daily rebuild cycle.

### `pacman.conf.kiro` added

An alternate `pacman.conf` variant was added for reference and comparison purposes. This gives a clear record of the intended final-state pacman configuration separate from the working `pacman.conf`, making it easier to diff what changed during troubleshooting.

### `linux-zen.preset` removed

Support for the Zen kernel was dropped. The Zen kernel is a performance-tuned variant, but maintaining a separate initramfs preset for it adds complexity. The CachyOS kernel (via Chaotic-AUR) better serves the performance tuning use case for the KIRO audience and does not require a separate preset in the ISO configuration.

### `pacman.conf` — Chaotic-AUR added

The **Chaotic-AUR** repository was added to the ISO's embedded `pacman.conf`. Chaotic-AUR is a binary repository that mirrors the most popular AUR packages as pre-built binaries, eliminating the need to compile from source. This is critical for the KIRO ISO because many of the tools in the package list (edu-* packages, window manager components, several AUR applications) are only available through Chaotic-AUR. Without it, the package list would be dramatically reduced or build times would become impractical.

---

## 2025-04-27 — Initial Commit

The KIRO ISO project was bootstrapped from an ArcoLinux base. This initial commit established the complete repository structure:

### ISO Configuration (`archiso/`)

The full `airootfs/` overlay was included — 93 files comprising the complete file system overlay that gets merged over the base Arch Linux system during ISO creation. This includes:

- All systemd service enablement symlinks for: SDDM (display manager), NetworkManager, Bluetooth, Avahi (mDNS), and CUPS (printing)
- Base configuration files for the shell, editor, and system
- The initial package list (`packages.x86_64`) — a comprehensive selection covering the full XFCE4 desktop, chadwm/ohmychadwm tiling window managers, development tools, multimedia applications, and system utilities

### Boot Configuration

- **GRUB** — EFI boot entries with standard, NVIDIA-nomodeset, and no-KMS options
- **Syslinux** — BIOS legacy boot configuration
- **systemd-boot** — EFI loader entries for modern UEFI systems

The three-bootloader setup ensures the ISO is bootable on any x86_64 system regardless of firmware type.

### Desktop Environments

Three desktop environments were configured from the start:

- **XFCE4** — the primary, full-featured desktop for users who want a traditional DE experience
- **chadwm** (later renamed `edu-chadwm`) — a customized build of dwm (suckless window manager) with a curated patch set for a practical tiling workflow
- **ohmychadwm** — a more opinionated chadwm configuration with additional visual polish

### Build System

**`installation-scripts/40-build-the-iso.sh`** (465 lines) — the main build automation script that orchestrates the ArchISO build process: validating the environment, installing build dependencies, calling `mkarchiso`, and packaging the output.

**`setup-git-v5.sh`** — the developer environment setup script (later renamed to `setup.sh`) that configures git, SSH keys, and other developer prerequisites.
