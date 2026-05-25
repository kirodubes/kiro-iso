# What Changed to the Kiro ISO

A rolling release log of what's actually different between Kiro ISO builds — kernel, audio stack, defaults, calamares, security baseline, tooling. Updated monthly (or per significant release). New entries go at the top.

Related docs:

- [LIQUORIX.md](./LIQUORIX.md) — why we ship the Liquorix kernel.
- [DISTRO_TESTING.md](./DISTRO_TESTING.md) — per-build manual test matrix.
- [KIRO-VS-PRISM.md](./KIRO-VS-PRISM.md) — security/config baseline comparison with Prism.

---

## 2026-05 — covering 2026-05-22 → 2026-05-25

Headline: the ISO becomes visibly **Kiro** — ArcoLinux branding stripped end-to-end — and gains a **firewall enabled by default** plus **tuned power profiles**, alongside a round of ATT accuracy fixes and installer/hardware hardening.

### Headline diffs

| Area              | Previous ISO                                           | Current ISO                                                                                              |
|-------------------|--------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| Branding          | residual ArcoLinux logos, themes, boot splash, names   | Kiro throughout — Kiro logos, `Kiro Simplicity` SDDM theme, `Kiro-*` rofi themes, arco boot splash gone  |
| Firewall          | none                                                   | `firewalld` shipped + **enabled by default** (deny-incoming baseline), turned on via Calamares           |
| Power profiles    | unmanaged                                              | `tuned` + `tuned-ppd` shipped + enabled; default `throughput-performance` (PPD "performance")            |
| Partition default | Calamares default                                      | GPT default partition-table type                                                                        |
| ATT Dev page      | false "mismatch" / "hook required" alarms when healthy | checks verify real state; firewall + microcode + power-profile status surfaced                          |

### Branding — ArcoLinux → Kiro

The shipped tree no longer carries ArcoLinux brand assets:

- Boot splash `splash-arcolinux.png` removed (`kiro-iso` + `-next`); the active `splash.png` is unchanged.
- skel `.config/logos/arcolinux*` replaced by Kiro logos (`Logo-Kiro`); the ArcoLinux Plank theme removed and a Kiro Plank theme added (`edu-dot-files`).
- rofi `ArcoLinux-{Nord,Darkish}.rasi` renamed to `Kiro-*`, and the `* User: ArcoLinux` generator stamp swept to `Kiro` across all 74 theme files (`edu-rofi-themes`).
- SDDM theme display name is now **Kiro Simplicity** (theme-id kept `edu-simplicity` to match the folder + the `kiro-audit` check) (`edu-sddm-simplicity`).
- ATT's bundled `arcolinux*` images and `archlinux-logout`'s betterlockscreen arco images removed; the `arco-chadwm` skel folder renamed to `chadwm`.
- Kept by design (real identifiers, not branding): the `arcolinux-arc-*` theme packages, the i3/qtile theme names, and the upstream `arcolinux-nemesis` clone.

### Firewall — firewalld on by default

- `firewalld` ships on the ISO and is **enabled on the installed system** via the Calamares `services-systemd` module (production + `-next`).
- The default `public` zone is deny-incoming / allow-outgoing — secure out of the box, no config needed.
- ATT's **Network** page gained firewall controls: live status, an enable/disable toggle, and one-click **Allow network discovery (mDNS)** / **Allow Samba** (the default zone blocks both, which is what network discovery and file sharing need).
- `kiro-audit`, `kiro-verify` and `kiro-diag` now report whether firewalld is enabled/active.

### Power profiles — tuned + tuned-ppd

- `tuned` + `tuned-ppd` are shipped and enabled (live + Calamares). Default profile is `throughput-performance`, exposed over the power-profiles-daemon D-Bus interface as `performance` so the desktop power widget works.
- `ppd.conf` is seeded with `default=performance` to stop the active profile resetting on boot.

### ATT accuracy & UX

- **Dev page** false alarms fixed — every check now *verifies* real state instead of asserting it: distro detection reads "Arch-based (expected)" (Kiro is Arch-based, not a "mismatch"); the kernel-install row confirms the `pacman-hook-kernel-install` package is actually present; the microcode row confirms the installed ucode's `/boot` image exists (catching the archiso-strips-the-image bug) and no longer warns on the normal single-ucode case.
- **Performance** page: `makepkg.conf` tuning rewritten in pure Python, with explainer dialogs that say *why* a change is made, not just *what*.

### Installer & hardware fixes

- Calamares: GPT set as the default partition-table type; `pacman -Sy` gated on the `hasInternet` flag and run before later chroot pacman calls; bare-metal detection fixed and orphan VM service symlinks unlinked on bare metal.
- udev (`edu-system-files`): stopped ethtool errors on consumer Intel e1000e NICs; fixed a net-rename race on Intel NICs; removed a dead HDD `fifo_batch` rule; moved the `systemd-logind` drop-in out of `multi-user.target.wants`.
- `edu-dot-files`: removed a GTK bookmarks file with hardcoded `/home/erik` paths; `up.sh` now refreshes the `usr/local/share/kiro/` reference configs from the `kiro-iso` airootfs on every run.

### Validated on real hardware

The firewalld enablement and the ATT changes (Network-page firewall controls + the Dev-page distro / kernel-hook / microcode fixes) were rebuilt and tested on the test box this cycle. Kernel/power-profile and installer fixes are tracked in [DISTRO_TESTING.md](./DISTRO_TESTING.md).

### Sources

- [kiro-iso](https://github.com/erikdubois/kiro-iso) / [kiro-iso-next](https://github.com/erikdubois/kiro-iso-next) — commits since `2026-05-22` (tuned wiring, de-brand, splash removal).
- [kiro-calamares-config](https://github.com/erikdubois/kiro-calamares-config) / `-next` — firewalld + tuned `services-systemd` enablement; GPT/pacman/bare-metal installer fixes.
- [edu-system-files](https://github.com/erikdubois/edu-system-files) — firewalld audit-script checks; udev/e1000e/logind fixes.
- `edu-rofi-themes`, `edu-sddm-simplicity`, `edu-dot-files`, `archlinux-tweak-tool-gtk4`, `archlinux-logout-gtk4`, `ohmychadwm` — de-brand + ATT Network/Dev/Performance changes.

---

## 2026-05 — covering 2026-05-17 → 2026-05-21

Headline: kernel swap, audio-stack swap, brand-new diagnostic toolchain, security-baseline hardening, installer tightening. The biggest single-release change set since the move to Kiro.

### Headline diffs

| Area              | Previous ISO                     | Current ISO                                                                                                                           |
|-------------------|----------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| Kernel            | `linux` (stock Arch)             | `linux-lqx` (Liquorix — desktop-tuned, BFQ-friendly)                                                                                  |
| Audio (live+inst) | `pulseaudio` + `pulseaudio-alsa` | `pipewire` + `wireplumber` + `pipewire-pulse`                                                                                         |
| Volume keys (WM)  | `amixer`                         | `pamixer`                                                                                                                             |
| Diagnostic tools  | none                             | `kiro-audit`, `kiro-verify`, `kiro-diag`, `kiro-lint`, `kiro-enable-ssh` (each with `--help` / `--version` / `--dry-run` + man pages) |
| Live-ISO SSH      | `PermitRootLogin yes` (archiso)  | archiso override removed                                                                                                              |
| CUPS config perms | world-readable                   | `0600` enforced via `tmpfiles.d`                                                                                                      |
| Version scheme    | `vYY.MM.DD.01`                   | `vYY.MM.DD`                                                                                                                           |

### Kernel & boot

- Default kernel is now **`linux-lqx`** (Liquorix). See [LIQUORIX.md](./LIQUORIX.md) for the rationale: BFQ, MuQSS, desktop responsiveness, gaming/audio latency, eight cited studies.
- Calamares: `kiro-calamares-config/unpackfs2.conf` installs `linux-lqx`. The production config was promoted from `-next` on 2026-05-19.
- `kiro-calamares-config-next` got mkinitcpio HOOKS fixed — replaces archiso hooks and adds the `resume` hook so suspend-to-swap works.
- GRUB / syslinux / loopback configs updated to `vmlinuz-linux-lqx` + `initramfs-linux-lqx.img` across both production and `-next`.
- NVIDIA `driver=nonfree` boot + DKMS compile against `linux-lqx-headers` verified on real hardware.

### PipeWire audio stack

- Live ISO and installed system both ship `pipewire` + `wireplumber` + `pipewire-pulse` instead of PulseAudio.
- Migration rationale in [PIPEWIRE-MIGRATION.md](../kiro-iso-next/PIPEWIRE-MIGRATION.md) (lives in `kiro-iso-next`).
- ohmychadwm volume keys switched from `amixer` to `pamixer` to match.
- `linux-lqx` follow-up: removed `stateful_codec` from `snd_hda_intel` options — that parameter doesn't exist in the lqx kernel.

### Diagnostic toolchain (new, shipped in `edu-system-files`)

Five new commands installed by default. All share a common flag set (`--help`, `--version`, `--dry-run`) and ship man pages.

| Tool              | What it does                                                                                                                                                                                                                           |
|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `kiro-diag`       | Structured system inventory: ISO release/codename/build, bootloader, CPU governor, kernel cmdline, packages, uptime, virt, locale, disk usage, swap, audio, bluetooth, temps, GPU (Intel detection), WM (ohmychadwm), paru/yay status. |
| `kiro-audit`      | Health checker — sysctl security, ZRAM, failed units, boot/update info, MAKEFLAGS, package integrity. `--fix` mode auto-remediates known failures. `--version` reads from the owning pacman package.                                   |
| `kiro-verify`     | Post-install configuration checker — presence of deployed config files, IO scheduler expectations for SSDs.                                                                                                                            |
| `kiro-lint`       | Static config analyser.                                                                                                                                                                                                                |
| `kiro-enable-ssh` | One-shot SSH enabler with man page.                                                                                                                                                                                                    |

In-tree `audit.sh` scripts in both `kiro-iso` and `kiro-iso-next` were removed once `kiro-audit` superseded them.

### Security hardening

- **Live-ISO SSH lockdown** — archiso's `PermitRootLogin yes` override removed.
- **CUPS permissions** — new `tmpfiles.d` rule enforces `0600` on CUPS config files.
- **sysctl tightening** — `kernel.unprivileged_userns_clone = 1` set explicitly; `vm.swappiness` bumped 100 → 150 to lean harder on ZRAM.
- **Boot-log noise** — three boot-log errors silenced after `dmesg` + `journalctl` audit.
- **IO scheduler** — BFQ set explicitly in udev rules; `ReadEtcHosts=no` set; `kiro-verify` updated to expect BFQ on SSDs.
- **PAM** — `system-auth` shipped with `audit=0` on `pam_faillock.so` lines; pam_faillock errors suppressed on kernels without audit support; the conflicting `etc/pam.d/system-auth` from earlier builds removed (pambase ownership conflict).
- **udev** — `ENV{DEVTYPE}` instead of bare `DEVTYPE` in the input-optimisation rule; backwards `DEVTYPE` audit logic fixed.
- **HID autosuspend** — chmod +x added, dmesg-nopasswd sudoers entry added, then the whole `udev-hid-autosuspend` callout removed because systemd 254+ blocks `/usr/local/bin/` callouts from udev.
- **Comparison baseline** — [KIRO-VS-PRISM.md](./KIRO-VS-PRISM.md) added: side-by-side Kiro vs Prism security-config comparison so each decision is defensible.

### Installer & build polish

- `kiro-calamares-config` ships Liquorix in production (promoted from `-next`).
- `kiro-calamares-config-next` mkinitcpio HOOKS fixed; `resume` hook added for suspend-to-swap.
- All ISO build scripts standardized to the project template.
- `edu-chadwm` dropped (obsolete — `ohmychadwm` is the live tree).
- `'next'` added to `isoLabel` in `kiro-iso-next` so checksums match `mkarchiso` output.
- Version scheme cleanup: `.01` suffix dropped; format is now `vYY.MM.DD`.
- Duplicate `memory-accounting.conf` removed from `airootfs` overlay (cascade from the HQ collision sweep).

### Validated on real hardware

NVIDIA boot + DKMS, BIOS/syslinux boot path, suspend-to-swap, headset reconnect (PipeWire), microcode cleanup post-install, PipeWire as default audio stack — all signed off in [DISTRO_TESTING.md](./DISTRO_TESTING.md).

### Sources

- [kiro-iso](https://github.com/erikdubois/kiro-iso) — commits since `2026-05-17`.
- [kiro-iso-next](https://github.com/erikdubois/kiro-iso-next) — commits since `2026-05-17`.
- [edu-system-files](https://github.com/erikdubois/edu-system-files) — commits since `2026-05-17`.
- [kiro-calamares-config](https://github.com/erikdubois/kiro-calamares-config) — `436684d` (Liquorix promotion).
- [kiro-calamares-config-next](https://github.com/erikdubois/kiro-calamares-config-next) — `d7af659` (mkinitcpio HOOKS + resume).

---

<!--
NEXT-MONTH TEMPLATE — copy/paste above this comment and fill in.

## YYYY-MM — covering YYYY-MM-DD → YYYY-MM-DD

Headline: <one-sentence elevator pitch>.

### Headline diffs

| Area | Previous ISO | Current ISO |
|------|--------------|-------------|
|      |              |             |

### <Section per theme — Kernel, Packages, Defaults, Calamares, Security, etc.>

### Validated on real hardware

### Sources

- repo — commit-range / link
-->
