# Kiro ISO — June 2026 builds, what changed and why

Ten ISOs shipped in June (`.01 .02 .04 .05 .06 .07 .08 .09 .10 .11`). For each: why it was worth a new ISO,
what functionality it added, and the package moves behind it. Newest first.

## v26.06.11 — June 11 (current)
**Why a new ISO:** a **Budgie** ISO is now usable end to end. Budgie has been buildable since v26.06.09, but as a **Wayland** desktop it broke on the two steps that matter — booting in, and installing — and both are now fixed.
- **Budgie live ISO boots into the desktop:** a Budgie ISO built with the **Kiro ISO Builder** now autologins straight into Budgie instead of stopping at the SDDM login screen. Budgie's session file is named `budgie-desktop` (not `budgie` like every other edition), so the live ISO's autologin was silently dropping to the greeter; the builder now maps the Budgie edition to the right session name automatically.
- **The installer and the Calamares Tweak Tool work on Wayland:** on a Budgie live ISO (which runs the **labwc** Wayland compositor) the installer and the **Calamares Tweak Tool** previously did nothing — both are X11/Qt apps launched as root, and a minimal Wayland compositor doesn't let the root process reach the display. The launcher now detects exactly that situation and grants the root installer just-enough access to the display, then revokes it — so Calamares and the CTT both open. GNOME-Wayland and Plasma-Wayland already worked (they set up XWayland themselves); this covers the lean compositors, and any future Wayland edition (Hyprland, niri) is handled with no further change.
- **Validated end to end:** an encrypted **btrfs + LUKS2/argon2id** Budgie install unlocks at boot and comes up clean, alongside a plain default XFCE install (`kiro-audit` 0 / 0 / 0).
- **Packages:** + `xorg-xhost` (lets the installer grant itself display access on Wayland; tiny and harmless on X11).

## v26.06.10 — June 10
**Why a new ISO:** **GNOME** and **Budgie** editions you build no longer throw the yellow "could not apply theme" popup.
- **Theme handling fixed for GTK desktops:** Kiro ships XFCE-oriented Qt/GTK theme overrides (in `/etc/environment`) that fight any desktop which manages its own theming — the same breakage Plasma hit. The build now clears those overrides for **GNOME** and **Budgie** editions too, so they theme themselves cleanly instead of triggering the yellow theme-error popup. GNOME and Budgie keep `qt5ct` (only Plasma needs it stripped, to resolve a real conflict). The default **XFCE** ISO is completely untouched.

## v26.06.09 — June 9
**Why a new ISO:** the **Kiro ISO Builder** takes a big step up — build an ISO around *any* desktop, not just XFCE, and tick extra office and productivity apps onto it before you build — and **f2fs** lands as a real install-time filesystem choice.
- **Build an ISO around any desktop:** the **Kiro ISO Builder**'s Configure screen now lets you pick exactly which editions go on your ISO from everything the medium offers — full desktops **XFCE, Cinnamon, GNOME, Plasma, MATE** and **Budgie**, plus the window managers **awesome, bspwm, chadwm, i3, leftwm, ohmychadwm** and **qtile** — and choose which one the live ISO logs into first. XFCE is now just one edition among many instead of always being forced on, so you can roll a pure Cinnamon, GNOME or Plasma ISO with nothing you didn't ask for. The list is read straight from the package manifest, so the builder never carries a hardcoded edition list that can drift.
- **Add office & productivity apps to your build:** a new **Add apps** step — the wizard is now six (Pre-flight → Configure → Packages → Add apps → Build → Done) — lets you opt **in** to apps the base ISO deliberately leaves off: office suites (**LibreOffice, OnlyOffice, WPS Office**), email clients (**Thunderbird, Betterbird, Evolution, Geary, Claws Mail, KMail**), text editors, PDF tools, note-takers and scanning utilities, grouped by category with select-all and search. It's the mirror image of the Packages step — Packages strips defaults out, Add apps layers extras in — and both are driven by the same package manifest, so the builder stays in sync automatically.
- **f2fs in the Calamares Tweak Tool:** the **Calamares Tweak Tool** now lists **f2fs** in its filesystem picker (right after ext4), alongside ext4 / xfs / jfs / btrfs — a flash-friendly, log-structured filesystem well suited to SSD/NVMe installs. It mounts with the same `defaults,noatime` options as the other non-btrfs choices, so a plain f2fs root just works; until now it simply wasn't a selectable option.
- **f2fs on every medium — your own builds included:** the `f2fs-tools` formatter ships on the ISO, so Calamares can lay down an f2fs root cleanly during install — and any ISO you roll with the **Kiro ISO Builder** carries it too, no extra package picking. Choosing f2fs is the same one-click experience whether you install the official ISO or one you built.
- **Kiro links in the menu:** a new **Kiro** submenu in the application menu gathers four one-click shortcuts — **Website**, **Releases**, **Discussions** and **Source Code** — each opening the matching page in your browser. A lightweight menu addition (no welcome app), with each link carrying its own coloured Kiro "K".
- **Packages:** updates only — `kiro-iso-builder` (any-desktop selection + Add apps step), `kiro-calamares-tweak-tool` (f2fs option) and `kiro-dot-files` (Kiro menu links).

## v26.06.08 — June 8
**Why a new ISO:** GRUB installs can no longer be bricked by an update, and QEMU/KVM virtual machines get host↔guest clipboard out of the box.
- **GRUB installs now self-heal:** the new `kiro-bootloader-grub` package adds pacman hooks that automatically re-run `grub-install` and rebuild the boot menu whenever GRUB or a kernel updates — closing the long-standing Arch trap where a `grub` update left the on-disk bootloader out of sync and the machine refused to boot (`error: symbol 'grub_…' not found`). The boot disk is detected automatically, so it works whatever the disk is named (`sda`, `vda`, NVMe…). It ships only where GRUB is the bootloader — every legacy-BIOS install, plus any UEFI user who picks GRUB in the Calamares Tweak Tool — and is cleanly removed on systemd-boot installs.
- **Clipboard sharing in virtual machines:** `spice-vdagent` now ships, so copy/paste between your host and a Kiro guest works out of the box on QEMU/KVM with a SPICE display. It's kept only on QEMU/KVM installs and removed on bare metal, VirtualBox and VMware (where SPICE isn't used).
- **Tidier ISO builder:** the Kiro ISO Builder now cleans up its work folder after each build by default — no leftover root-owned folder to trip its pre-flight check.
- **Packages:** + `kiro-bootloader-grub`, + `spice-vdagent`.

## v26.06.07 — June 7
**Why a new ISO:** you can now build and customize **your own** Kiro ISO — the `kiro-iso-builder` GUI ships on the medium, backed by a beginner-friendly "Build Your Own ISO" guide — and installs are faster and more reliable worldwide thanks to geo-routed CDN mirrors.
- **Build your own ISO, from a GUI:** `kiro-iso-builder` (GTK4) is on the ISO — pick the kernel, choose the NVIDIA driver, and untick optional apps, then build a personalized Kiro ISO without hand-editing a single file. The new `build-scripts/BYOI.md` walks a first-timer through it end to end (one folder of settings → a bootable `.iso`).
- **Faster, more reliable installs everywhere:** the shipped mirrorlist drops from **605 worldwide servers to 4 geo-routed CDN mirrors** (plus a curated Chaotic-AUR list), so package downloads during install no longer crawl on a long tail of dead/slow mirrors — fast anywhere on earth with no per-location tuning.
- **Slim it down after install, too:** the shipped **Arch Linux Tweak Tool** gains a new **Streamline** page — remove the optional apps that came on the ISO, grouped by category, with save/import selection profiles.
- **Pro-audio ready:** `pipewire-jack` serves the JACK API through PipeWire (no separate daemon), so JACK applications work out of the box.
- **Packages:** + `kiro-iso-builder`, + `pipewire-jack`, + `7zip` (replaces deprecated `p7zip`); − `python-pylint`.

## v26.06.06 — June 6
**Why a new ISO:** drops a paid app and gives the package list a clear, tiered structure — so the ISO is easy to read, fork and rebuild (the groundwork for the upcoming "build your own ISO" guide).
- **No paid apps pre-installed:** **Spotify removed** — a paid streaming service doesn't belong pre-loaded on a community ISO.
- **Keybindings cheatsheet on board:** `kiro-keybindings` is now an explicit package on the list — the auto-detecting, searchable shortcut reference (Super+K) for the desktop and tiling managers.
- **Readable package list:** `packages.x86_64` is reorganized into risk tiers (never-remove core vs freely-editable apps), so anyone cloning the repo can see at a glance what's safe to change; seven commented-out "suggestion" entries were pruned to cut noise.
- **Packages:** − `spotify`; + `kiro-keybindings` (explicit).

## v26.06.05 — June 5
**Why a new ISO:** validated the full disk-encryption matrix — **LUKS2** ext4 / btrfs / xfs / jfs installs all unlock and pass `kiro-audit` clean (0 WARN / 0 FAIL) — and swaps in better default apps.
- **Better screen recording:** **OBS Studio** replaces SimpleScreenRecorder.
- **CPU scheduler control:** **scx-manager** added — switch sched-ext schedulers at runtime.
- **Apps ship as proper repo packages:** dropped the build-from-source `-git` suffix on `archlinux-tweak-tool-gtk4`, `archlinux-logout-gtk4`, `alacritty-tweak-tool`, and `ohmychadwm`.
- **Packages:** + `obs-studio`, + `scx-manager`; − `simplescreenrecorder-git`, − `lastpass`.

## v26.06.04 — June 4
**Why a new ISO:** adds the Calamares tweaking tool to the installer toolset and moves the shell baseline onto the renamed repo.
- **Calamares Tweak Tool (CTT):** `kiro-calamares-tweak-tool` ships for use during install (stripped from the final installed system).
- **Shell source moved:** the build now fetches the skel `.bashrc` from `kirodubes/kiro-shells` instead of `erikdubois/edu-shells`.
- **Packages:** + `kiro-calamares-tweak-tool`.

## v26.06.02 — June 2
**Why a new ISO:** finishes the de-brand at the package level — the installed system now pulls **Kiro-named** packages instead of the old `edu-*` ones.
- **No behaviour change, new identity:** same configs and defaults, but every Kiro config package is renamed `edu-* → kiro-*` and pulled from the Kiro repos; legacy commented-out `edu-*` WM/theme entries cleaned out of the list.
- **Packages (16 renamed):** `kiro-system-files`, `kiro-shells`, `kiro-dot-files`, `kiro-rofi` + `kiro-rofi-themes`, `kiro-sddm-simplicity`, `kiro-powermenu`, `kiro-polybar`, `kiro-xfce`, `kiro-variety-config`, `kiro-arc-dawn`, `kiro-arc-kde`, and the five `kiro-neo-candy-*` themes.

## v26.06.01 — June 1 (baseline)
**Why a new ISO:** first June build — locks in the late-May kernel-agnostic overhaul as the new default.
- **Kernel-agnostic end to end:** default kernel is now **linux-cachyos**, with **linux-zen** selectable as a fallback right in the boot menu; a new `kiro_kernel` Calamares module installs every kernel the medium ships.
- **GPU just works:** `chwd` auto-detects the card at install, with three NVIDIA boot options (modern / auto-detect / open) so old and new cards both boot.
- **Polished install:** dark **KiroDark** installer matching the website, and the animated Kiro "K" splash now draws from the moment the live ISO boots.
- **Live-ISO ergonomics:** the desktop "Install kiro" launcher is pre-trusted (no "untrusted application" prompt), and `kiro-enable-ssh` actually works on the live medium.
- **Packages:** + `linux-cachyos` + `linux-zen`; drops `linux-lqx` and the third-party Liquorix repo.

<!--
=============================================================================
HOW THIS FILE IS GENERATED — re-run this each release (e.g. alongside
/kiro-website-release), then commit + push so the website button shows the
latest. The commit messages are just "update" (up.sh quick-push), so the
truth is in the diffs, not the log.

1. Map each shipped version to the commit that bumped it. The version is set
   in archiso/profiledef.sh at build time (Phase 2), so its history IS the
   list of builds:
       git log -p --since=<start-date> -- archiso/profiledef.sh | grep -E "^commit|iso_version="

2. For each consecutive pair of build commits, stat-diff the WHOLE tree but
   exclude the per-build noise (version string, mirrorlist, build metrics):
       git diff --stat <prev> <curr> -- . \
         ':(exclude)archiso/profiledef.sh' \
         ':(exclude)archiso/airootfs/etc/dev-rel' \
         ':(exclude)BUILD_TIMES.md'
   What's left points you at the files that actually changed — almost always
   archiso/packages.x86_64 and build-scripts/build-the-iso.sh.

3. Read the real line-level changes for those files:
       git diff <prev> <curr> -- archiso/packages.x86_64        # + / - packages
       git diff <prev> <curr> -- build-scripts/build-the-iso.sh # kernel knob, repo sources
   Cross-check DISTRO_TESTING.md for the "why we shipped it" (what was validated)
   and WHAT-CHANGED-TO-THE-ISO.md for the prose behind a feature wave.

4. Turn each diff into ONE block per version, answering three things from the
   END-USER's point of view (not the dev's):
       - Why a new ISO: the one reason it was worth shipping.
       - What functionality it added: what the user can now do / notice.
       - Packages: the + / - moves (but never ONLY packages).
   Hard-filter: keep what a user FEELS (drivers, kernel, installer, apps).
   Drop dev/build/brand-internal noise (template conformance, isoLabel fixes,
   version-sync checks) and validations-that-aren't-changes. A pure
   version-bump + mirrorlist build gets NO entry — let the filter collapse it.

5. Order newest FIRST (most recent build at the top, under the intro). Keep
   blocks short; a build with one real selling point gets one line.
=============================================================================
-->
