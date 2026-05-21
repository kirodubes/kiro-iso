# What Changed to the Kiro ISO

A rolling release log of what's actually different between Kiro ISO builds — kernel, audio stack, defaults, calamares, security baseline, tooling. Updated monthly (or per significant release). New entries go at the top.

Related docs:

- [LIQUORIX.md](./LIQUORIX.md) — why we ship the Liquorix kernel.
- [DISTRO_TESTING.md](./DISTRO_TESTING.md) — per-build manual test matrix.
- [KIRO-VS-PRISM.md](./KIRO-VS-PRISM.md) — security/config baseline comparison with Prism.

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
