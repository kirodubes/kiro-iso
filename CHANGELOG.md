# CHANGELOG

> Complete history of the KIRO ISO project — newest first. Each entry explains not just what changed, but why it was done and what benefit it brings. Daily rebuilds (version bump + mirrorlist refresh only) are grouped into a single line.

---

## 2026-06-06 — Declutter repo root: move docs into `docs/` + drop stray `BEST_PRACTICES.md`

**What Changed**
- Moved **15 documentation files** off the repo root (via `git mv`, so history is preserved) — 14 into a structured **`docs/`** tree, and the build guide beside the build scripts:
  - `build-scripts/` — `BYOI.md` (the Build-Your-Own-ISO guide lives next to `build.sh` / `build-the-iso.sh`)
  - `docs/` — `OVERVIEW.md`, `WHAT-CHANGED-TO-THE-ISO.md`, `PIPEWIRE-MIGRATION.md`
  - `docs/kernels/` — `KERNEL_CHOICE_FOR_KIRO.md`, `KERNEL_COMPARISON.md`, `ARCH-KERNELS-BUILD-CONFIG-SCORECARD.md`, `CHATGPT-KERNEL-STUDY.md`, `GEMINI-KERNEL-STUDY.md`, `comparison-usage-kernels.md`, `LIQUORIX.md`
  - `docs/comparisons/` — `KIRO-VS-ARCH.md`, `KIRO-VS-CACHYOS.md`, `KIRO-VS-GARUDA.md`, `KIRO-VS-PRISM.md`
- Removed **`BEST_PRACTICES.md`** — a 166 KB stray copy of the Kiro-HQ best-practices file that did not belong in this repo (the canonical copy lives in Kiro-HQ; nothing here linked to it).
- Fixed every internal markdown link affected by the move — `README.md` → `docs/BYOI.md`, the relative links inside `docs/OVERVIEW.md`, `docs/WHAT-CHANGED-TO-THE-ISO.md`, and `docs/kernels/LIQUORIX.md`, and the historical links in this CHANGELOG. A link-resolution pass confirmed **zero** broken targets introduced by the reorg.

**Why**
- The root had grown to **22 `.md` files** — mostly kernel-research studies and `KIRO-VS-*` comparisons — burying the actual entry points. The root now holds only the 6 files that belong there (`README`, `CHANGELOG`, `CLAUDE`, `LICENSE`, plus the tooling-bound `RELEASES.md` / `DISTRO_TESTING.md` / `BUILD_TIMES.md`) and the three scripts (`build.sh`, `setup.sh`, `up.sh`).
- Files that other tooling reads/writes at fixed paths were deliberately **left at root**: `RELEASES.md` (feeds the website "Release notes" button), `DISTRO_TESTING.md` (`/kiro-ready`, `/kiro-check`), and `BUILD_TIMES.md` (`record-install-time.sh`).
- No effect on the ISO — these are repo docs only; the build pipeline references none of them.

**Files Modified**
- 15 docs relocated under `docs/` (renames); `BEST_PRACTICES.md` deleted
- Link fixes: `README.md`, `CHANGELOG.md`, `docs/OVERVIEW.md`, `docs/WHAT-CHANGED-TO-THE-ISO.md`, `docs/kernels/LIQUORIX.md`

## 2026-06-06 — One-command build (`./build.sh`) + host-prep extracted to a sourced helper (mirrored from `-next`)

**What Changed**
- Added **`build.sh`** at the repo root as the single entry point for building the ISO — a thin, template-conformant wrapper that hands off to **`build-scripts/build-the-iso.sh`**, so the command is identical on every machine: **`./build.sh`**. A builder no longer needs to know the internal layout or `cd` into `build-scripts/`.
- Extracted the host-preparation helpers (**`ensure_package`**, **`setup_chaotic`**, and the new **`setup_cachyos`**) out of `build-the-iso.sh` into a new **`build-scripts/host-prep.sh`**, which `build-the-iso.sh` now **sources**. `host-prep.sh` is a function-only library (no `main()`) with a load-once guard, keeping all "make the host ready to build" logic in one place.
- Wired **`setup_cachyos`** into `main()` alongside `setup_chaotic`. It trusts the CachyOS signing key, enables the `[cachyos]` CDN77 geo-mirror in `/etc/pacman.conf` if absent, and installs `cachyos-keyring` + `cachyos-mirrorlist` — idempotently (already-configured hosts are detected and skipped).

**Why**
- The build pulls `linux-cachyos` (the default live kernel) from `[cachyos]`, and `prepopulate_keyring` runs `pacman-key --populate cachyos`; a host lacking the cachyos keyring/mirrorlist fails the build. Folding that prep into the sourced helper makes the build **self-contained on any Arch-based host** (Arch, Kiro, EndeavourOS, CachyOS, Garuda) with no manual setup.
- This mirrors the change proven on **`kiro-iso-next`** (which produced today's working v26.06.06 build). The two ISO build pipelines stay structurally identical so a fix in one ports cleanly to the other. **Note:** `build.sh` and `host-prep.sh` are intentionally byte-identical across both repos for now — a future unified `kiro-iso-builder` is the place to collapse this duplication into a single source of truth.

**Files Modified**
- `build.sh` (new)
- `build-scripts/host-prep.sh` (new)
- `build-scripts/build-the-iso.sh`

## 2026-06-06 — v26.06.06 — risk-tier `packages.x86_64` reorg from `-next` + drop paid app

**Release** — production ISO **`kiro-v26.06.06`** built and verified release-ready. Headline change: **`spotify` removed** — a paid streaming app has no place on the community ISO. `/kiro-ready` returned **GO** (5 repos clean+pushed, no P1 blockers, no iso↔iso-next drift, name-leakage 0 Tier-1/3) and a clean **full install** passed `kiro-audit` **134 / 0 / 0**, with the shipped `kiro-system-files 26.06-15` sysctl config verified byte-identical to source. See [DISTRO_TESTING.md](DISTRO_TESTING.md).

**What Changed**
- Reorganized **`archiso/packages.x86_64`** into the same **three risk tiers** now used on `kiro-iso-next` (FROZEN / KIRO CORE / USER-CHANGEABLE), grouped by function within each tier, with banner comments that make the "never remove" packages unmistakable and push the freely-editable apps to the end.
- Removed **`spotify`** — a paid streaming app has no place on the community ISO that ships to users.
- Pruned the trailing commented-out "uncomment-to-enable" optionals (`#flat-remix`, `#colloid-cursors-git`, `#dex`, `#ckb-next-git`, `#discord`, `#telegram-desktop`, `#tlp`) — personal-taste suggestions that belong in the arcolinux-nemesis post-install scripts.
- Kept production's plain package names (**`calamares`**, **`kiro-calamares-config`**, **`kiro-calamares-tweak-tool`**, **`plymouth-theme-kiro-logo`**) — no `-next`/`-nemesis` variants on production.

**Why**
- The list gave no signal telling a builder which packages are load-bearing vs safe to edit. Tiering makes the blast radius explicit. The structure was proven on `-next` first (build succeeded, files verified) before mirroring here, per the test-in-next-first rule.
- Built from the `-next` file with the four production name swaps, then a **token-set diff** confirmed the only deltas from the previously-validated production list were the intended ones: `spotify` removed (active) and the 7 commented optionals removed — **zero** other packages lost, added, or toggled. Build-script anchors (`nvidia-*`, `linux-cachyos`/`-headers`) stay at column 0.
- Result: **396 active** packages (was 397), 36 commented (was 43). Production and `-next` now differ by exactly the four by-design Calamares/Plymouth name pairs and nothing else.

**Files Modified**
- `archiso/packages.x86_64`

---

## 2026-05-31 — Three NVIDIA boot options: proprietary modern / proprietary auto-detect

**What Changed**
- The single NVIDIA boot entry split into two, across all three bootloaders (systemd-boot, GRUB, syslinux): **"NVIDIA proprietary, modern"** (`driver=nonfree`) keeps the baked `nvidia-open-dkms` with no chwd — the proven path for Turing / RTX-20-series+ cards; and a new **"NVIDIA proprietary, auto-detect"** (`driver=nonfreechwd`) that runs chwd to pick the right driver for any card. The open entry is unchanged (`driver=free`, "open source: AMD / Intel").

**Why**
- Modern-NVIDIA users get a chwd-free express lane to the baked driver (proven on real hardware), while the chwd path stays available for older cards. The driver-mode logic lives in [kiro-calamares-config](../kiro-calamares-config); this repo just adds/relabels the boot entries.

**Files Modified**
- `archiso/efiboot/loader/entries/02-nvidianouveau.conf` (relabel) + `02b-nvidiachwd.conf` (new)
- `archiso/grub/grub.cfg`, `archiso/syslinux/archiso_sys-linux.cfg`

## 2026-05-29 — Dark Calamares installer: ship KiroDark Kvantum theme (mirrored from beta)

**What Changed**

Promoted from `kiro-iso-next` after a confirmed install + reboot. The Calamares installer now renders dark (navy + sky-blue, matching the website). The ISO ships a custom **KiroDark** Kvantum theme for root, which the installer (run as root via pkexec) picks up via `-style kvantum`.

**Technical Details**

- New: `airootfs/root/.config/Kvantum/KiroDark/{KiroDark.kvconfig,KiroDark.svg}` + `kvantum.kvconfig` (`theme=KiroDark`). KiroDark = ArcDark remapped to Kiro's navy/sky-blue palette, fully opaque, white button text.
- `packages.x86_64`: added `kvantum` (qt6 style) explicitly — was only present as a dependency of `kvantum-qt5`; Calamares is Qt6 and needs the qt6 Kvantum style.
- Paired with `kiro-calamares-config` (dark branding) and the production `calamares` package launcher change (`-style kvantum`, wrapper removed). `kiro_final` strips the theme from the installed system.

**Files Modified**
- `archiso/airootfs/root/.config/Kvantum/KiroDark/KiroDark.kvconfig` (new)
- `archiso/airootfs/root/.config/Kvantum/KiroDark/KiroDark.svg` (new)
- `archiso/airootfs/root/.config/Kvantum/kvantum.kvconfig` (new)
- `archiso/packages.x86_64`

---

## 2026-05-29 — Sync committed skel `.bashrc` with the renamed kiro-* helpers

**What Changed**

Updated the committed **[archiso/airootfs/etc/skel/.bashrc](archiso/airootfs/etc/skel/.bashrc)** so its aliases point at the renamed `kiro-*` helper scripts instead of the old `edu-*` names (and dropped the dead `rvariety`/`rkmix`/`rconky` aliases, whose `edu-remove-*` scripts were removed, not renamed). This is purely a sync change — at build time `build-the-iso.sh` fetches the live `.bashrc-latest` from `erikdubois/edu-shells` into the build tree, so the *shipped* `.bashrc` always comes from edu-shells. The point of this edit is the **Phase 2c consistency check** (`files_are_identical` against the local edu-shells `.bashrc-latest`): without it, that check would print NOK once edu-shells is pushed with the renamed aliases. Real fix lives in (and must be pushed from) `edu-shells`.

**Technical Details**

- Renames (old → new): `edu-which-vga` → `kiro-which-vga`; `edu-fix-pacman-databases-and-keys` → `kiro-fix-pacman-keys` (7 alias variants); `edu-fix-pacman-conf` → `kiro-fix-pacman-conf`; `edu-fix-pacman-gpg-conf` → `kiro-fix-gpg-conf`; `edu-fix-archlinux-servers` → `kiro-fix-mirrors`; `edu-probe` → `kiro-probe`. File still parses clean (`bash -n`).

**Files Modified**

- [archiso/airootfs/etc/skel/.bashrc](archiso/airootfs/etc/skel/.bashrc)

---

## 2026-05-29 — Live ISO boot now shows the K splash too

**What Changed**

Completed the boot-splash story: the `kiro-logo` Plymouth splash now renders during the **live ISO boot**, not just on the installed system. Until now Plymouth was present and themed on the ISO but never drew at live boot, because the live environment was missing the two prerequisites Plymouth needs — the `plymouth` initramfs hook and the `splash` kernel parameter. Both were only added to the *installed* target (by the `kiro_plymouth` Calamares module + the bootloader module). This change adds them to the live boot path as well.

**Technical Details**

- **[archiso/airootfs/etc/mkinitcpio.conf](archiso/airootfs/etc/mkinitcpio.conf)** — inserted the `plymouth` hook right after `udev` in the live `HOOKS` line (same position the `kiro_plymouth` Calamares module uses on the target). `kms` is already present, so KMS is ready before Plymouth draws. `mkarchiso` rebuilds the live initramfs at build time, so no manual `mkinitcpio` run is needed.
- **`quiet splash`** added to the **KMS** boot entries across all three bootloaders. Plymouth needs *both* `quiet` and `splash` or it falls back to the text details theme:
  - systemd-boot (**[archiso/efiboot/loader/entries/](archiso/efiboot/loader/entries/)**): `01-archiso-linux`, `02-nvidianouveau`, `04-fallback-zen` (these already had `quiet loglevel=3`, so only `splash` was added).
  - GRUB (**[archiso/grub/grub.cfg](archiso/grub/grub.cfg)**) and syslinux (**[archiso/syslinux/archiso_sys-linux.cfg](archiso/syslinux/archiso_sys-linux.cfg)**): these had neither token, so `quiet splash` was appended to the matching free / NVIDIA / zen-fallback entries.
- **`03-nomodeset` is intentionally left untouched** in every bootloader. With `nomodeset` there is no KMS, so Plymouth cannot render graphically — leaving that entry bare keeps the safe-graphics fallback verbose and reliable.
- Theme selection is unchanged — `kiro-logo` is still set at `mkarchiso` time by the `plymouth-theme-kiro-logo` package's `.install`. This change only makes the live boot actually *display* it.

**Files Modified**

- [archiso/airootfs/etc/mkinitcpio.conf](archiso/airootfs/etc/mkinitcpio.conf)
- [archiso/efiboot/loader/entries/01-archiso-linux.conf](archiso/efiboot/loader/entries/01-archiso-linux.conf)
- [archiso/efiboot/loader/entries/02-nvidianouveau.conf](archiso/efiboot/loader/entries/02-nvidianouveau.conf)
- [archiso/efiboot/loader/entries/04-fallback-zen.conf](archiso/efiboot/loader/entries/04-fallback-zen.conf)
- [archiso/grub/grub.cfg](archiso/grub/grub.cfg)
- [archiso/syslinux/archiso_sys-linux.cfg](archiso/syslinux/archiso_sys-linux.cfg)

---

## 2026-05-29 — Kiro boot splash now ships on the ISO

**What Changed**

Added `plymouth-theme-kiro-logo` to [archiso/packages.x86_64](archiso/packages.x86_64) (new PLYMOUTH section). Its `depends=('plymouth')` pulls plymouth onto the ISO automatically, so installed systems get the animated "self-assembling K" boot splash out of the box. Mirrored into the `kiro-iso-next` tree.

**Technical Details**

- The package's `.install` runs `plymouth-set-default-theme kiro-logo` at `mkarchiso` time, writing `Theme=kiro-logo` into the airootfs `/etc/plymouth/plymouthd.conf`; `unpackfs` copies that to the target before the initramfs is built. No `-R` is used (correct — Calamares' `initcpio` job is the single source of truth for the target rebuild).
- The `plymouth` hook is added to the target's `mkinitcpio.conf` by the new `kiro_plymouth` Calamares module (see kiro-calamares-config CHANGELOG); the `splash` kernel param is auto-appended by the `bootloader` module when plymouth is present. Splash is kernel-agnostic — the single `mkinitcpio -P` builds it into every selected kernel's initramfs.

**Files Modified**
- `archiso/packages.x86_64`

## 2026-05-29 — chwd NVIDIA testing on worf + nvidia-390xx is dead on the 7.0 kernel

Test install on **worf** (`erik-p7624`, an Optimus laptop: Intel HD 2nd-gen + NVIDIA **GF108M / GeForce GT 620M**, PCI `10de:0de9`), booted with the **non-free** GRUB option (`driver=nonfree`). Three things came out of it.

### chwd behaved correctly — and our DKMS patch shipped

The Calamares log confirms chwd ran (`Kernel parameter 'driver' = nonfree` → `chwd --autoconfigure`) and made the right calls per device: `intel` for the iGPU and **`nouveau` for the GT 620M**. chwd's device database classifies that Fermi card as a nouveau card, *not* a 390xx card, so it never tried to install a proprietary NVIDIA driver — it pulled `nouveau-fw` + mesa/opencl and finished cleanly. The installed system runs on Intel `i915` + Xorg `modesetting`; the display is healthy.

The installed box carries **`chwd 1.21.0-4`** (our patched build) and its `/var/lib/chwd/db/pci/graphic_drivers/profiles.toml` shows the **patched** `[nvidia-open-dkms]` block — `echo "nvidia-open-dkms"` + per-kernel `-headers`, with the old `${kernel}-nvidia-open` prebuilt logic gone. So the chwd DKMS patch built correctly and reached the ISO. `linux-cachyos-nvidia-open` is not installed.

**Caveat — still untested end-to-end:** worf does *not* exercise the patch, because its card went to nouveau, so the `nvidia-open-dkms` profile never fired. Confirming the patch *in action* (installs `nvidia-open-dkms` + headers, never `linux-cachyos-nvidia-open`) needs a **modern NVIDIA GPU** that chwd routes to that profile.

### nvidia-390xx (390.157) cannot build on Kiro's 7.0 kernel

Manually installing `nvidia-390xx-dkms 390.157` on worf left DKMS at `added` (never built); `nvidia-smi` then reports "couldn't communicate with the NVIDIA driver". A forced `dkms build` fails with:

```
nvidia/os-interface.c:1136: error: 'screen_info' undeclared
```

`screen_info` was removed from modern kernels; the EOL 390 branch still references it. **The legacy 390 driver is therefore non-viable on Kiro's kernel** — for Fermi-class cards like the GT 620M, **nouveau is the only working driver**, which is exactly what chwd picks. (worf was left as-is; no cleanup applied.)

**Implication:** the `nvidia_driver=390xx` option in **[build-scripts/build-the-iso.sh](build-scripts/build-the-iso.sh)** and chwd's `nvidia-dkms-390xx` profile are effectively dead on the 7.0 kernel — any card routed there would get a driverless system (now non-fatal at install, but still no proprietary driver). `nvidia-dkms-470xx` is likely the same and needs verifying. See TODO.

## 2026-05-28 — Hardware-aware install via **chwd** (synced from `kiro-iso-next`)

Mirror of the same-date `kiro-iso-next` change. The chwd Calamares integration validated in `kiro-iso-next` + `kiro-calamares-config-next` is now ready for production: this commit syncs the four package additions to `archiso/packages.x86_64` so the live ISO carries everything `kiro-calamares-config`'s new `chwd` Calamares module needs at install time + leaves on the target for post-install rerun via `sudo chwd -a`.

### What Changed

Four edits to **[archiso/packages.x86_64](archiso/packages.x86_64)**:

- **Enabled `b43-fwcutter`** (was commented) — Broadcom B43/B43legacy firmware extractor for older Broadcom Wi-Fi chipsets.
- **Enabled `broadcom-wl-dkms`** (was commented) — Broadcom proprietary `wl` kernel module via DKMS. chwd's `broadcom-wl` profile (priority 1) expects this to be available.
- **Added `chwd`** — CachyOS's Hardware Detection Tool (Rust, GPL-3.0). Pulled from `nemesis_repo` where it ships with our patched profiles.toml fixing the upstream `[virtualbox]` / `[vmware]` vendor_id swap.
- **Added `hwdetect`** — console hardware-detect helper, complements `hwinfo` / `inxi` / `hw-probe`.

### Why

Same rationale as the `kiro-iso-next` entry: chwd picks the right NVIDIA / AMD / Intel / Broadcom / hybrid-PRIME variant at install time based on detected hardware. Removes the need for per-build `nvidia_driver=open|580xx|390xx` selection in `build-the-iso.sh` once chwd is fully trusted (retirement TODO already filed in kiro-iso-next).

### Pairs With

- [kiro-calamares-config](../kiro-calamares-config/) — committed the chwd Calamares module + settings.conf sequence entry in the same session.
- [edu-pkgbuild-3party/chwd](../../EDU-PKG-BUILD/edu-pkgbuild-3party/chwd/) — patched chwd PKGBUILD in nemesis_repo (vbox/vmware vendor_id fix).

**Files Modified**

- **[archiso/packages.x86_64](archiso/packages.x86_64)** — uncommented `b43-fwcutter` (line 5), uncommented `broadcom-wl-dkms` (line 11), added `chwd` (line 523), added `hwdetect` (line 529).

---

## 2026-05-28 — Live-boot fallback kernel: `linux-zen` entries added to UEFI / BIOS-syslinux / GRUB menus

### What changed

A 4th entry, **"fallback kernel linux-zen"**, was added to each live boot menu so a user whose hardware refuses `linux-cachyos` can pick `linux-zen` at the boot screen — not just post-install. Three additions:

- **UEFI:** new file [archiso/efiboot/loader/entries/04-fallback-zen.conf](archiso/efiboot/loader/entries/04-fallback-zen.conf) (sort-key 04, mirrors 01-archiso-linux.conf's open-source / KMS-on driver combo with `vmlinuz-linux-zen`)
- **BIOS/syslinux:** new `LABEL arch_fallback_zen` block appended to [archiso/syslinux/archiso_sys-linux.cfg](archiso/syslinux/archiso_sys-linux.cfg), wrapped in `# >>> KIRO_ZEN_FALLBACK_BEGIN/END <<<` markers
- **GRUB:** new `menuentry` with id `'kirofallback'` inserted into [archiso/grub/grub.cfg](archiso/grub/grub.cfg), same marker pair

The PXE syslinux config and the GRUB loopback.cfg were left alone — niche boot paths where a user can edit the kernel parameter at the GRUB/syslinux prompt if they need to.

A small **strip-step** was added to `apply_kernel()` in [build-scripts/build-the-iso.sh](build-scripts/build-the-iso.sh): if the user sets `kernel=` to something that excludes `linux-zen`, the new UEFI file is deleted and the marker-wrapped blocks are sed-deleted from syslinux/grub before `mkarchiso` runs. Keeps the build robust to non-default `kernel=` settings without leaving broken boot entries pointing at an uninstalled kernel.

### Why

A fallback kernel only serves its purpose if it's reachable from the live-ISO boot menu. Having `linux-zen` installed in the squashfs but with no boot entry means a user whose hardware refuses cachyos can't even reach Calamares to install — making the "fallback" useless in exactly the scenario that matters.

The design is informed by CachyOS's own live ISO ([CachyOS/CachyOS-Live-ISO](https://github.com/CachyOS/CachyOS-Live-ISO/blob/master/archiso/grub/grub.cfg)), which ships their main kernel + an LTS fallback in the same boot menu for the same reason. We kept Kiro's three existing entries (open-source / NVIDIA / nomodeset) intact and added zen as a 4th, rather than collapsing the kernel-fallback and graphics-fallback axes into one entry as CachyOS does — Erik's call, to keep both axes orthogonal so a user can pick "kernel-only fallback" without losing modeset.

### Files

- [archiso/efiboot/loader/entries/04-fallback-zen.conf](archiso/efiboot/loader/entries/04-fallback-zen.conf) (new)
- [archiso/syslinux/archiso_sys-linux.cfg](archiso/syslinux/archiso_sys-linux.cfg)
- [archiso/grub/grub.cfg](archiso/grub/grub.cfg)
- [build-scripts/build-the-iso.sh](build-scripts/build-the-iso.sh)

---

## 2026-05-28 — Default kernel: `linux-lqx` → `linux-cachyos`

### What changed

The ISO's canonical kernel was switched from `linux-lqx` (Liquorix) to `linux-cachyos`. Both [build-the-iso.sh](build-scripts/build-the-iso.sh) (lines 369-370) and every load-bearing archiso template were updated:

- **Builder:** `KERNEL_CANDIDATES` dropped `linux-lqx`; `CANONICAL_KERNEL` set to `linux-cachyos`. The cachyos family (`-bore`, `-lts`, `-rc`) continues to be discovered dynamically from the enabled repos at picker time — no static list change needed.
- **Package list:** `archiso/packages.x86_64` lines 52 and 134 now install `linux-cachyos` + `linux-cachyos-headers`.
- **Boot configs (templates):** 9 files mass-rewritten from `linux-lqx` → `linux-cachyos` — `archiso/efiboot/loader/entries/{01-archiso-linux,02-nvidianouveau,03-nomodeset}.conf`, `archiso/syslinux/archiso_{sys,pxe}-linux.cfg`, `archiso/grub/{grub,loopback}.cfg`, `archiso/airootfs/etc/mkinitcpio.d/{linux.preset,kiro}`.

### Why

Why now: latest test ISO showed the picker pre-selecting `linux-lqx` (the canonical), and the builder's auto-rewrite logic at `apply_kernel()` (line 526) only fires when the user's pick differs from the canonical — so the default build path was emitting `linux-lqx`-based boot entries unchanged. With cachyos chosen as the new community default (responsiveness + active upstream + healthier security track than lqx), the canonical needs to match that decision so the default flow produces a cachyos ISO without depending on the user picking it explicitly.

The build-time default `kernel=` is now `"linux-cachyos linux-zen"` — both kernels are installed in the live ISO by default. `linux-zen` is the chosen fallback for users whose hardware doesn't accept cachyos; see the separate entry below for the live-boot-menu wiring that exposes it at boot time.

LIQUORIX.md is retained as a historical record of the prior kernel era; a header note flags it as superseded.

### Files

- [build-scripts/build-the-iso.sh](build-scripts/build-the-iso.sh)
- [archiso/packages.x86_64](archiso/packages.x86_64)
- [archiso/efiboot/loader/entries/01-archiso-linux.conf](archiso/efiboot/loader/entries/01-archiso-linux.conf)
- [archiso/efiboot/loader/entries/02-nvidianouveau.conf](archiso/efiboot/loader/entries/02-nvidianouveau.conf)
- [archiso/efiboot/loader/entries/03-nomodeset.conf](archiso/efiboot/loader/entries/03-nomodeset.conf)
- [archiso/syslinux/archiso_sys-linux.cfg](archiso/syslinux/archiso_sys-linux.cfg)
- [archiso/syslinux/archiso_pxe-linux.cfg](archiso/syslinux/archiso_pxe-linux.cfg)
- [archiso/grub/grub.cfg](archiso/grub/grub.cfg)
- [archiso/grub/loopback.cfg](archiso/grub/loopback.cfg)
- [archiso/airootfs/etc/mkinitcpio.d/linux.preset](archiso/airootfs/etc/mkinitcpio.d/linux.preset)
- [archiso/airootfs/etc/mkinitcpio.d/kiro](archiso/airootfs/etc/mkinitcpio.d/kiro)
- [LIQUORIX.md](docs/kernels/LIQUORIX.md) (historical-note banner)

---

## 2026-05-28 — squashfs compression L6 → L3 (faster unpackfs phase)

### What changed

One-line change in [archiso/profiledef.sh](archiso/profiledef.sh) (line 19): the squashfs build options swapped `-Xcompression-level 6` for `-Xcompression-level 3`. The old L6 line is preserved as a commented fallback right above the new line, so reverting is one-line.

### Why

`unpackfs` (the squashfs extract during Calamares install) is the dominant cost on slow disks — easily ~2 min of the install. zstd decompression speed scales inversely with compression level; dropping L6 → L3 typically yields 2-3× faster extraction at the cost of ~5-10% ISO size growth. For a once-downloaded-many-times-installed artifact that trade is worthwhile.

### Benefit observed

ISO size: 5.9 GB → **6.1 GB** (+200 MB, ~3.4% growth — on the low end of the predicted 5-10%). Unpackfs phase on the VirtualBox test install measured at **2 min 13 s** (total install 3 min 4 s). Direct head-to-head against the prior L6 baseline on the same VM has not been run yet; the size impact is confirmed at the cost predicted, and the option is in place for further benchmarking.

### Files

- [archiso/profiledef.sh](archiso/profiledef.sh)

---

## 2026-05-28 — KIRO-VS-GARUDA.md analysis added

### What changed

New comparison document [`KIRO-VS-GARUDA.md`](docs/comparisons/KIRO-VS-GARUDA.md), joining the `KIRO-VS-ARCH` / `KIRO-VS-CACHYOS` / `KIRO-VS-PRISM` series. SSH-based inspection of Garuda Mokka's tuning footprint, scored against `edu-system-files`.

### Why

Reference distros are checked quarterly so good ideas don't drift past us. This round produced 5 adoptions (implemented same day in `edu-system-files`): systemd-oomd enablement + tuning, Intel ME blacklist (mei/mei_me), `btusb reset=1`, kernel-zswap disable tmpfile, NetworkManager `unmanaged-lo`. Also formalised the **kernel-agnostic rule** (every system tweak must work on any kernel a user might run) and recorded it in the analysis doc + `edu-system-files/CLAUDE.md`.

### Files

- [KIRO-VS-GARUDA.md](docs/comparisons/KIRO-VS-GARUDA.md) (new)

---

## 2026-05-28 — default kernel switched: linux-lqx → linux-cachyos + linux-zen

### What changed

The ISO's default kernel is now **`linux-cachyos`** (live-boot + post-install default), with **`linux-zen`** shipped as a secondary installed kernel the user can boot from the boot loader menu. Liquorix (`linux-lqx`) is no longer the default.

### Why

Two clear choices, both from repos Kiro already trusts: `linux-zen` lives in Arch `[extra]` (zero third-party trust burden), `linux-cachyos` comes via `chaotic-aur` which is already in the ISO's pacman.conf. Killing lqx removes the third-party `liquorix.net` repo / AUR-build complexity and the special-case docs around it. The narrative tightens too: *"fastest desktop → cachyos, conservative stock-Arch → zen"* sells itself in a way *"what's Liquorix?"* never did. Both kernels have been independently tested across many combinations.

### How — single-line change

The build is fully templated. One line in [build-scripts/build-the-iso.sh](build-scripts/build-the-iso.sh) (line 101):

```bash
kernel="linux-cachyos linux-zen"   # was: "linux-lqx"
```

`apply_kernel()` (line 514+) rewrites at build time:
- `packages.x86_64` — strips the canonical kernel + headers, adds every selected kernel + its headers
- live mkinitcpio presets in `airootfs/etc/mkinitcpio.d/`
- all boot loader entries (`efiboot/loader/entries/`, `grub/grub.cfg`, `grub/loopback.cfg`, `syslinux/*.cfg`)

`CANONICAL_KERNEL=linux-lqx` (line 370) is **untouched** — it's the *source token* the sed-templating substitutes FROM, matching the literal kernel name in the archiso tree as-shipped. Changing it would break the substitution.

### Calamares side: nothing needed

`kiro_kernel` (in `kiro-calamares-config`) is already kernel-agnostic — it detects whichever kernel(s) the live medium ships and installs them into the target, with the live-boot kernel becoming the post-install default. So this build-script change propagates all the way through to the installed system without touching Calamares.

### Files modified

- `build-scripts/build-the-iso.sh` (line 101)
- `TODO.md` (closed the "Choose a different kernel" item)
- `CHANGELOG.md` (this entry)

### Follow-ups (separate passes, not on this commit)

- Retire `LIQUORIX.md` / fold `KERNEL_CHOICE_FOR_KIRO.md` into a decision-archive note — the new default makes them historical.
- `KIRO-VS-CACHYOS.md` — invert the comparison: Kiro now ships CachyOS's kernel; the doc should be reframed as *"what Kiro adds on top of the CachyOS kernel choice"*.
- Mirror this kernel default into `kiro-iso-next` once we're happy with the June-1 build.
- `WHAT-CHANGED-TO-THE-ISO.md` entry will be appended in the standard next-release pass.

---

## 2026-05-28 — launcher trust moved out of airootfs; kernel selector hardening

### Launcher trust: out of airootfs, into the calamares package

Yesterday's "pre-trust the Install kiro launcher" fix — an airootfs autostart `.desktop` running `/usr/local/bin/kiro-trust-desktop-launchers` — **did not survive a real build**. The airootfs overlay shipped the helper as `644` even though git records it `100755`, so the autostart's `Exec=<script>` couldn't execute it and the "Untrusted application launcher" prompt came right back. The exec bit is simply not reliable through the airootfs overlay.

So the helper is **removed from this repo's airootfs** (`archiso/airootfs/usr/local/bin/kiro-trust-desktop-launchers` deleted), and trust is now delivered by the **`calamares` package** as a **systemd _user_ service** (`kiro-trust-launchers.service`, installed to `~liveuser/.config/systemd/user/` with a shipped `WantedBy` enable symlink). Two deliberate design points:

- **`ExecStart=/bin/bash /usr/local/bin/kiro-trust-desktop-launchers`** — running the script through `bash` makes the exec bit irrelevant, so the lost-`+x` class of bug can't recur.
- **User service, `default.target`** — the trust action is `gio set metadata::trusted` on liveuser's desktop files, which is per-user via the session bus (a root system service writes to the wrong place). The unit targets **`default.target`** because XFCE on Kiro does **not** activate `graphical-session.target` (verified live: the service was `enabled` but stayed `inactive (dead)`).

The trigger and helper thus leave kiro-iso's airootfs entirely; the calamares package owns the mechanism. (See the calamares PKGBUILD for the unit + symlink.)

### Kernel selector: strict validation + no needless repo scan

Refinements to `select_kernels()` in the build script:

- **Strict `picker=` validation** — an invalid value (e.g. a typo'd `diag`) now fails loudly with `Invalid picker='diag'. Valid options: auto | gum | dialog` instead of silently falling back to gum.
- **Kernel-name validation** — a mistyped `kernel="…"` is caught up front with `Unknown kernel '<name>'` plus the list of valid names, rather than failing deep inside `mkarchiso`.
- **No needless repo scan** — `detect_available_kernels` (which probes ~25 packages) no longer runs on every build. A fixed kernel like `linux-lqx` now does just two local-DB lookups to confirm the package + `-headers` exist; the full enumeration runs only for `kernel="ask"` (build the menu) or on a typo (suggest valid names).
- **`auto` now prefers `dialog`** — `picker="auto"` resolves to dialog (Kiro's branded picker) if present, else gum; `picker="gum"` still forces the truecolor UI.

**Files Modified**

- **[build-scripts/build-the-iso.sh](./build-scripts/build-the-iso.sh)** — picker + kernel validation, `detect_available_kernels` moved out of the fixed-kernel path, `auto` dispatch flipped to dialog-first.
- **archiso/airootfs/usr/local/bin/kiro-trust-desktop-launchers** — removed (trust now ships via the calamares package).

## 2026-05-27 — kernel selector: `picker=` toggle + broader dynamic discovery

Two refinements to the `kernel="ask"` selector:

**1. `picker=` config var** (`auto` | `gum` | `dialog`). `auto` (default) uses gum if installed, else dialog; set it explicitly to force one — `dialog` to test that path or run on a host without gum, `gum` to insist on the truecolor UI. Previously the choice was implicit (`command -v gum`).

**2. Broader, fully-dynamic kernel discovery.** The selector now offers every kernel in the **first four families** the enabled repos provide, discovered dynamically (no stale hardcoded list): the mainstream set plus all **CachyOS**, **XanMod**, and **pinned-LTS** flavors. Static candidates are now just the stable mainstream names (`linux`, `-lts`, `-zen`, `-hardened`, `-rt`, `-rt-lts`, `-lqx`, `-mainline`); the multi-flavor families are matched dynamically via `^(linux-cachyos|linux-xanmod|linux-lts[0-9])`.

**What we deliberately leave out, and why.** The repos also ship CPU-microarch builds (`linux-x64v2/v3/v4`, `linux-znver2…5`) and niche kernels (`linux-cjktty`, `-nitrous`, `-tachyon`, `-vfio`). These are **excluded by design**: low demand, and the microarch ones are **dangerous on a general ISO — they silently fail to boot on the wrong CPU level** (e.g. `x64v4` needs AVX-512, `znver5` needs Zen 5). Anyone who explicitly wants one can still set `kernel="linux-znver4"` directly.

| Bucket        | Kernels                                                                     | Offered?                      |
|---------------|-----------------------------------------------------------------------------|-------------------------------|
| Mainstream    | `linux`, `-lts`, `-zen`, `-hardened`, `-rt`, `-rt-lts`, `-lqx`, `-mainline` | ✅                             |
| CachyOS       | `linux-cachyos`, `-bore`, `-lts`, `-rc`                                     | ✅                             |
| XanMod        | `linux-xanmod-lts`, `-rt`, `-x64v2`, `-x64v3`, `-edge-x64v3`                | ✅                             |
| LTS pins      | `linux-lts515`, `-lts61`, `-lts66`, `-lts612`                               | ✅                             |
| CPU-microarch | `linux-x64v2/v3/v4`, `linux-znver2…5`                                       | ❌ won't boot on the wrong CPU |
| Niche         | `linux-cjktty`, `-nitrous`, `-tachyon`, `-vfio(-lts)`                       | ❌ low demand                  |

**Files Modified**

- **[build-scripts/build-the-iso.sh](./build-scripts/build-the-iso.sh)** — `picker=` config var; `KERNEL_CANDIDATES` trimmed to mainstream + `linux-mainline`; dynamic grep widened to CachyOS/XanMod/LTS-pins; picker-aware dispatch in `select_kernels`.

## 2026-05-27 — kernel selector: gum picker (truecolor Arc Dark) with dialog fallback

`select_kernels()` now prefers **`gum`** for the `kernel="ask"` picker, falling back to **`dialog`** when gum isn't installed. gum renders **truecolor**, so it hits the exact Arc Dark palette the dialog theme could only approximate through the terminal's 16 colors: blue accent `#5294e2`, text `#d3dae3`, muted header `#8b9bb4`. Refactored into `_select_kernels_gum` (`gum choose --no-limit`, with a second `gum choose` for the live-boot kernel when several are picked) and `_select_kernels_dialog` (the existing checklist/radiolist, unchanged). The parent runs `detect_available_kernels` once, then dispatches on `command -v gum`. gum is host-only and not in the ISO — fine, since the selector runs host-side at build time; the `dialog` path keeps a bare build host working.

**Files Modified**

- **[build-scripts/build-the-iso.sh](./build-scripts/build-the-iso.sh)** — split `select_kernels` into gum + dialog backends.

## 2026-05-27 — live ISO: pre-trust the "Install kiro" launcher

Clicking the **Install kiro** desktop launcher on the live ISO popped XFCE/Thunar's **"Untrusted application launcher"** dialog (_"…is in an insecure location and not marked as secure"_) before Calamares would start — an avoidable speed bump on first contact with the installer. Thunar 4.20 refuses to launch a `.desktop` unless it carries the GIO trust metadata, and `cal-kiro.desktop` (shipped by the calamares package, already `chmod 755`) had none.

Added a tiny live-session autostart — **[/usr/local/bin/kiro-trust-desktop-launchers](./archiso/airootfs/usr/local/bin/kiro-trust-desktop-launchers)**, launched by **[~/.config/autostart/trust-desktop-launchers.desktop](./archiso/airootfs/home/liveuser/.config/autostart/trust-desktop-launchers.desktop)** (liveuser only) — that sets both `metadata::trusted=true` and the XFCE-specific `metadata::xfce-exe-checksum` on every `~/Desktop/*.desktop` at login. The checksum is computed **at runtime** so it always matches the current file (a value baked at build time would break the moment the launcher changes). Confirmed on the live VM (Thunar 4.20.8): with the flags set the launcher opens straight into Calamares, no prompt. **Live-session scope only** — not shipped to `/etc/skel`, so installed systems are unaffected. Mirrored to `kiro-iso-next`.

**Files Modified**

- **[archiso/airootfs/usr/local/bin/kiro-trust-desktop-launchers](./archiso/airootfs/usr/local/bin/kiro-trust-desktop-launchers)** (new)
- **[archiso/airootfs/home/liveuser/.config/autostart/trust-desktop-launchers.desktop](./archiso/airootfs/home/liveuser/.config/autostart/trust-desktop-launchers.desktop)** (new)

## 2026-05-27 — kernel-agnostic ISO: build-time kernel selector

[build-the-iso.sh](./build-scripts/build-the-iso.sh) no longer hardcodes `linux-lqx`. A new **`kernel=`** config knob (default `linux-lqx`; set to `ask` for an interactive **`dialog`** menu, or a space-separated list for several kernels) lets the ISO be built with **any kernel(s)** the enabled repos offer. This pairs with the new **`kiro_kernel`** Calamares module in `kiro-calamares-config`, which installs whatever kernel(s) the ISO ships — together the whole pipeline (live ISO + installed system) becomes kernel-agnostic from a single selection point, with **zero edits to the config**.

**How it works.** `select_kernels()` detects installable kernels by probing a candidate list (`linux`, `-lts`, `-zen`, `-hardened`, `-rt`, `-rt-lts`, `-lqx`, `-cachyos`) plus **every `linux-cachyos*` flavor discovered dynamically** — CachyOS kernels topped our benchmark study, so all flavors are exposed and discovered at build time rather than hardcoded into a list that goes stale. Only kernels with a matching `-headers` are offered (the DKMS NVIDIA drivers need them). When several are picked, a second `dialog` chooses which one the **live ISO boots** (the "primary"). `apply_kernel()` then rewrites the **build-tree** copies (never the repo source): all selected kernels + `-headers` into [packages.x86_64](./archiso/packages.x86_64), and the primary kernel name into the boot entries (`efiboot`/`syslinux`/`grub`) and the live presets (`kiro`, `linux.preset`). The repo keeps `linux-lqx` as its canonical default, mirroring the existing `inject_nvidia_packages()` pattern. The picker is host-only (terminal-native `dialog`, so it works over SSH/tty) and themed via a bundled **[kiro.dialogrc](./build-scripts/kiro.dialogrc)** (dark background, blue accents).

**Validated on the `-next` track first** — built ISOs with CachyOS (single) and `linux-lts` + `linux-zen` (multi), installed and booted both, confirming `kiro_kernel` lays down every kernel's image, initramfs, and intact headers — then mirrored here for production.

**Files Modified**

- **[build-scripts/build-the-iso.sh](./build-scripts/build-the-iso.sh)** — `kernel=` config var; `detect_available_kernels()`, `select_kernels()`, `apply_kernel()`; wired into `main()` + `show_overview`.
- **[build-scripts/kiro.dialogrc](./build-scripts/kiro.dialogrc)** — new dark dialog theme for the picker.

## 2026-05-27 — build: pre-flight version-sync check

[build-the-iso.sh](./build-scripts/build-the-iso.sh) now runs a **`verify_version_sync()`** guard immediately after `apply_version_bump()` (logged as **Phase 2b**), before any of the expensive build phases. It extracts the version string from all four authoritative sources — `ISO_RELEASE=` in **dev-rel**, `iso_version=` and `iso_label=` in **profiledef.sh**, and `kiroVersion=` in **build-the-iso.sh** itself — and asserts they all equal the in-memory `${kiroVersion}` that drives the build (with `iso_label` checked as `${iso_name}-${version}`). Any mismatch prints the offending file/value list and **hard-aborts with `exit 1`** before `mkarchiso` runs.

**Why:** the version lives in three files that must stay in lockstep (documented in CLAUDE.md). When `bump_version="yes"` the bump re-stamps all of them, so they can't drift — but on a `bump_version="no"` same-day rebuild, a hand-edited or half-reverted version string survives silently and only surfaces as a confusing failure (or a mislabelled ISO) deep into the build. Failing fast at Phase 2b turns a ~20-minute wasted build into an instant, explicit error. The check is cheap enough to run unconditionally, so it also doubles as a self-test that `apply_version_bump()`'s `sed` rewrites actually landed.

Also added compact colored status helpers (**`status_ok`** → green `[ OK ]`, **`status_nok`** → red `[ NOK ]`) and wired them into **`remove_buildfolder()`**: a green `[ OK ]` prints before the "Deleting build folder" banner when the folder is present, and a red `[ NOK ]` (replacing the previous blue info banner) when there is nothing to delete.

Added a reusable **`files_are_identical()`** helper — a byte-for-byte exact-copy check (`cmp -s`) between two paths that guards both paths first and reports green `[ OK ]` / red `[ NOK ]`. Returns 0/non-zero for use in an `if`. Wired into `main()` as **Phase 2c**, comparing the committed skel `.bashrc` against the local **`~/EDU/edu-shells`** clone (`.bashrc-latest`); the call is followed by `|| true` so a `[ NOK ]` (drift, or no local clone) is purely informational and never aborts the build.

## 2026-05-27 — kernel docs: validation summary, comparison reconciliation, scheduler fix

Docs-only day, all centred on the kernel story. No build artifacts affected, no rebuild needed.

### LIQUORIX.md — validation summary consolidated

[LIQUORIX.md](./docs/kernels/LIQUORIX.md) is now the single kernel reference. Added a **"Validation — what we tested on real hardware"** section that consolidates the kernel-specific findings previously scattered across [DISTRO_TESTING.md](./DISTRO_TESTING.md), TODO.md, and WHAT-CHANGED-TO-THE-ISO.md. The new section carries a per-build table (the four `linux-lqx` validation builds spanning `7.0.9` → `7.0.10`) plus a checklist of what each kernel-relevant test confirmed: UEFI/systemd-boot and BIOS/syslinux boot paths, `mkarchiso` boot-image generation (`vmlinuz-linux-lqx` + `linux-lqx.preset`, stock `linux.preset` removed), `nvidia-open-dkms` DKMS compile against `linux-lqx-headers` with `driver=nonfree` boot on real NVIDIA hardware, S3 suspend / S4 hibernate-resume on bare metal, and kernel boot-phase timings. The kernel content itself was already fully promoted to production and byte-identical to the beta track; what was missing was a single place to *read* the kernel story end-to-end, evidence beside the argument.

### KERNEL_COMPARISON.md added + reconciled with LIQUORIX.md

A new four-way kernel comparison ([KERNEL_COMPARISON.md](./docs/kernels/KERNEL_COMPARISON.md) — Arch `linux` vs `linux-cachyos` vs `linux-cachyos-bore` vs Liquorix) was added and cross-checked against LIQUORIX.md. Two corrections came out of that:

- **Package identity.** The comparison described Kiro's kernel as the upstream `linux-liquorix` Debian/Ubuntu binary (repo/curl install). Kiro actually ships **`linux-lqx`** — the Chaotic-AUR build of the same patchset. Renamed `linux-liquorix` → `linux-lqx` throughout and rewrote the install-story prose to reflect the Chaotic-AUR prebuilt-binary path.
- **Stock scheduler.** The comparison correctly lists Arch stock as **EEVDF** (the mainline scheduler since 6.6); LIQUORIX.md still said **CFS**. Fixed CFS → EEVDF in LIQUORIX.md (TL;DR, scheduler study, and performance verdict) and softened the "throughput-biased" framing to "fairness-oriented."

Also added a **"A note on names"** section at the bottom of LIQUORIX.md disambiguating `linux-lqx` (Kiro's kernel) vs upstream `linux-liquorix` (Debian/Ubuntu binaries) vs `linux-kiro-lqx` (Erik's personal native-CPU build).

### DISTRO_TESTING.md — privacy scrub

Removed a personal hostname and an embedded username from the testing log (replaced with the standard `the test box` / `<user>` placeholders) per the privacy rule for published files. Test data and hardware-class details unchanged.

## 2026-05-26 — cups: airootfs trimmed to socket-only

The live ISO airootfs enabled CUPS three different ways: **`sockets.target.wants/cups.socket`**, **`printer.target.wants/cups.service`**, and **`multi-user.target.wants/cups.path`**. The service and path symlinks were redundant — socket activation alone is enough, since `cupsd` is started on demand the moment a client opens the print socket (e.g. opening printer settings or sending a job). Removed **`printer.target.wants/cups.service`** and **`multi-user.target.wants/cups.path`** (and the now-empty `printer.target.wants/` directory), leaving only **`cups.socket`** in the overlay.

**Why this matters.** These airootfs symlinks only affect the *live* session — they are not carried into the installed system, where service enablement is driven entirely by Calamares. Printing was therefore off after a fresh install + reboot. The matching fix lives in **`kiro-calamares-config`**, which now explicitly enables **`cups.socket`** (socket activation only) on the installed system. Keeping the live ISO consistent with that — socket-only everywhere — avoids confusion about why CUPS appears enabled three ways live but absent post-install.

**Files modified.**
- `archiso/airootfs/etc/systemd/system/printer.target.wants/cups.service` (removed)
- `archiso/airootfs/etc/systemd/system/multi-user.target.wants/cups.path` (removed)

## 2026-05-26 — README: community framing, dropped "personal"

The README overview opened with "KIRO is a **personal** Arch Linux ISO builder" — leftover single-user framing from Kiro's early phase that contradicts the public, community-facing positioning. Reworded to lead with Kiro's identity as a **community Arch-based Linux distribution**, with this repo described as its ISO builder. Codified the rule in [Kiro-HQ/ASSISTANT.md](../../Insync/Kiro/Kiro-HQ/ASSISTANT.md) ("never call the shipped distro personal"). README only — no build artifacts affected, no rebuild needed.

## 2026-05-24 — `v26.05.24`: build/version merge, de-branding sweep, hibernate validation

A multi-theme day. Newest commits first within the day.

### Build workflow — version bump merged into the build, `change-version.sh` retired

**What changed.** The two-step release dance (`bash change-version.sh` then `bash build-the-iso.sh`) collapsed into one command. **`change-version.sh` was deleted** (128 lines) and its logic re-homed inside [build-scripts/build-the-iso.sh](./build-scripts/build-the-iso.sh) as a new `apply_version_bump()` function that runs as **Phase 2**, after the root/btrfs/chaotic preflight but before package checks. The bump is gated by a new `bump_version="yes"` flag in the config block — set it to `no` for a same-day rebuild of the currently-pinned version.

**Technical details.** `apply_version_bump()` derives `newversion="v$(date +%y.%m.%d)"` and `sed`-rewrites the three canonical version fields in place: `ISO_RELEASE=` in **dev-rel**, `kiroVersion='…'` in **build-the-iso.sh**, and both `iso_label=`/`iso_version=` in **profiledef.sh**. The `kiroVersion` substitution is anchored to `^` so it only touches the config-block assignment and never the `sed` line itself. Crucially, it then re-derives the in-memory `kiroVersion` and `isoLabel` so the *current* build uses the freshly bumped string — no stale-version mismatch between the bump and the `mkarchiso` run. A summary block echoes the three resulting lines for at-a-glance verification.

**Why.** The split was a footgun: forgetting `change-version.sh`, or running it twice, produced version drift across the three files (the exact failure mode the `## isoLabel Must Match` note in CLAUDE.md guards against). Folding it into the build as a flagged phase makes the single documented command (`cd build-scripts && bash build-the-iso.sh`) authoritative and keeps all version mutation in one place. [CLAUDE.md](./CLAUDE.md) build-workflow section was rewritten to match.

### De-branding sweep — ArcoLinux / arconet → Kiro

**What changed.** A pass to scrub residual ArcoLinux ancestry from user-visible boot and shell surfaces:

- **Boot menus** — `arconet` / `arcolinux` titles replaced with `kiro` across [archiso/efiboot/loader/entries/](./archiso/efiboot/loader/entries/) (01/02/03), [archiso/grub/grub.cfg](./archiso/grub/grub.cfg), and the syslinux configs ([archiso_head.cfg](./archiso/syslinux/archiso_head.cfg), [archiso_pxe-linux.cfg](./archiso/syslinux/archiso_pxe-linux.cfg), [archiso_sys-linux.cfg](./archiso/syslinux/archiso_sys-linux.cfg)). Menu labels and help text now read "Boot kiro …" / "install kiro …".
- **GRUB distributor** — `GRUB_DISTRIBUTOR` in **archiso/airootfs/etc/default/grub** changed from `"ArcoLinux Kiro"` to `"Kiro"`.
- **Hostname** — **archiso/airootfs/etc/hostname** changed from `arconet` to `kiro`.
- **SDDM** — `Current=` in **kde_settings.conf** moved from `arcolinux-simplicity` to `edu-simplicity`.
- **skel `.bashrc`** — three dead Arco-era aliases removed: `rmlogoutlock` (pointed at `/tmp/arcologout.lock`), `install-grub-efi` (hard-coded `--bootloader-id=ArcoLinux`), and `npicom` (pointed at the non-existent `~/.config/arco-chadwm/picom/picom.conf`).

**Why.** The branding note in CLAUDE.md flags this migration as ongoing; these were the last `arco*` strings a user would actually *see* (boot screen, hostname, login theme) or trip over (broken aliases). Cosmetic, but it's the difference between a polished distro and an obvious fork.

### Live-ISO skel `.bashrc` now sourced from `edu-shells`

**What changed.** [up.sh](./up.sh) gained an `update_skel_bashrc()` step in `main()` (after `git_pull`, before `clean_pycache`) that copies `~/EDU/edu-shells/etc/skel/.bashrc-latest` over [archiso/airootfs/etc/skel/.bashrc](./archiso/airootfs/etc/skel/.bashrc). It warns and skips gracefully if the source file is absent, so the quick-push flow never breaks on a machine without the `edu-shells` checkout.

**Why.** Keeps the live-ISO skel shell config in lockstep with the canonical `edu-shells` source instead of letting the in-tree copy drift by hand-editing. See [[skel-bashrc-only]] — skel still ships only `.bashrc` (the live env is bash; the user's real shell is chosen later via ATT).

### `tuned` — `ppd_base_profile` removed

**What changed.** The `archiso/airootfs/etc/tuned/ppd_base_profile` file (added 2026-05-22 as the clobber fix) was deleted. `active_profile`, `profile_mode`, and `ppd.conf` remain.

**Caveat.** `ppd.conf` still carries the comment "Step 1 wins in practice, so `default=` only matters if `ppd_base_profile` [is wiped]" — which no longer holds now that the file is gone. With step 1 of the short-circuit chain removed, profile selection falls through to tuned's `recommend` (→ `balanced` on bare metal) before `default=performance` can fire, re-exposing the exact reset documented on 2026-05-22. **Flagged for verification** — confirm on a fresh install whether `active_profile` survives, and either restore the seed or rewrite the stale `ppd.conf` comment.

### DISTRO_TESTING — Picard bare-metal hibernate validation

**What changed.** New [DISTRO_TESTING.md](./DISTRO_TESTING.md) entry for `v26.05.24` on **Picard** (bare-metal ASUS STRIX Z270H, i7-7700K, Intel I219-V, UEFI/systemd-boot, `linux-lqx 7.0.10`). Boot PASS at 17.8s; install via Calamares with a **dedicated swap partition** (new `kiro-calamares-config-next` feature); `kiro-audit` **92 PASS / 0 WARN / 0 FAIL**. Hibernate→resume (S4) and suspend (S3) both PASS on bare metal — `resume` hook present and correctly ordered, `resume=UUID=` matches swap, swap ≥ RAM. Documented that hibernate **cannot** be validated under VirtualBox (`vmwgfx` aborts the freeze with "Can't hibernate while 3D resources are active" when VMSVGA 3D is on — a VM-GPU limitation, not a distro bug). One cosmetic finding: two boot-time `ethtool` errors from `62-network-optimization.rules` wrongly applying server-NIC knobs to the I219-V `e1000e` — fixed in `edu-system-files` `36b4f77`, pending package + ISO rebuild.

### Files modified

- [build-scripts/build-the-iso.sh](./build-scripts/build-the-iso.sh) (Phase 2 `apply_version_bump()`, `bump_version` flag, version → `v26.05.24`)
- `change-version.sh` (**deleted**)
- [CLAUDE.md](./CLAUDE.md) (build-workflow rewrite)
- `archiso/airootfs/etc/dev-rel`, [archiso/profiledef.sh](./archiso/profiledef.sh) (version → `v26.05.24`)
- `archiso/efiboot/loader/entries/{01,02,03}-*.conf`, [archiso/grub/grub.cfg](./archiso/grub/grub.cfg), `archiso/syslinux/*.cfg` (boot-menu de-branding)
- `archiso/airootfs/etc/default/grub`, `archiso/airootfs/etc/hostname`, `archiso/airootfs/etc/sddm.conf.d/kde_settings.conf` (de-branding)
- [archiso/airootfs/etc/skel/.bashrc](./archiso/airootfs/etc/skel/.bashrc) (dead Arco aliases removed)
- [up.sh](./up.sh) (`update_skel_bashrc()` step)
- `archiso/airootfs/etc/tuned/ppd_base_profile` (**deleted**)
- [DISTRO_TESTING.md](./DISTRO_TESTING.md) (Picard `v26.05.24` entry)

## 2026-05-23 — New Kiro logo on README

**What changed.** [README.md](./README.md) now shows the new Kiro logo, and `images/kiro.jpg` was re-exported far smaller (≈197 KB → ≈37 KB). **Why.** Updated branding asset plus a lighter repo — the old JPG was ~5× the size for no visual benefit at README display dimensions.

**Files modified.** [README.md](./README.md), `images/kiro.jpg`.

## 2026-05-22 — `tuned-ppd` clobber fix: pre-seed `ppd_base_profile`

**What changed.** Discovered that the earlier "default to `throughput-performance`" work (same day, below) didn't actually survive first boot — installed Kiro VMs were landing on `active_profile = balanced` regardless. Root cause traced through `tuned.ppd.controller.Controller.initialize()`:

```python
self._base_profile = self._load_base_profile() \
                  or self._get_recommend_profile() \
                  or self._config.default_profile
```

Short-circuit chain. `_load_base_profile()` reads `/etc/tuned/ppd_base_profile` (empty on first boot → None). `_get_recommend_profile()` asks `tuned.service` via D-Bus for its recommendation — tuned's `recommend.d` runs `virt-what` (binary not installed → error logged 4×), then falls back to its generic recommendation of `balanced`. That maps via `ppd.conf` `[profiles]` to PPD `balanced` → step 2 returns `"balanced"` → step 3 (`default=performance` in `ppd.conf`) **never fires**. The "Without this override, the airootfs-seeded active_profile is silently clobbered" comment in `ppd.conf` was correct about the symptom but wrong about the mechanism — the `default=` line itself was load-bearing for nothing.

**The fix — one new file.** Added `archiso/airootfs/etc/tuned/ppd_base_profile` containing `performance\n`. That makes step 1 of the short-circuit chain succeed, returning `"performance"`, which tuned-ppd then maps via `ppd.conf` `[profiles]` back to tuned's `throughput-performance` — exactly the airootfs-seeded `active_profile`. No more clobber.

The `tuned` package does NOT list `ppd_base_profile` in its pacman `Backup` array (only `active_profile`, `profile_mode`, etc. are), so on a `pacman -S tuned` reinstall the file would be silently overwritten with the empty package version — but Calamares does not reinstall `tuned` (only `pacman -Sy` + `systemctl enable`), so the pre-seeded file rides the airootfs squashfs unpack into the installed target intact. Verified on a fresh Kiro VM install (2026-05-22): tuned-ppd starts, reads `ppd_base_profile = performance`, maps to `throughput-performance`, writes it back to `active_profile`. Same profile, no more reset.

**Comment in `ppd.conf` rewritten.** The misleading "default=performance overrides upstream balanced" explanation replaced with an accurate description of the three-step short-circuit chain and which step actually wins. The `default=` line itself is kept as belt-and-braces — it fires only if `ppd_base_profile` is later wiped.

**Not the cause (but worth noting).** `virt-what` not being installed *produces* the four `tuned.utils.commands` errors in `/var/log/tuned/tuned.log`, but installing it wouldn't have fixed the underlying bug — on bare-metal desktops tuned still recommends `balanced` (no virt detected), short-circuiting before `default=`. The `ppd_base_profile` approach is the universal fix.

**Why this matters.** Without this, Kiro's "Performance Tuned" positioning was a lie at boot — DE power widgets showed "Balanced", CPU governor stayed on `schedutil` default, dirty page ratios used the conservative balanced profile. Now the installed system actually inherits the performance-oriented tuning the rest of the stack (Liquorix, BFQ, ananicy-cpp) is built around.

**Files modified.**
- `archiso/airootfs/etc/tuned/ppd_base_profile` (new — single line, `performance\n`)
- `archiso/airootfs/etc/tuned/ppd.conf` (comment rewritten; `default=` line unchanged)

## 2026-05-22 — `tuned` finished: add `tuned-ppd`, enable services, default to `throughput-performance`

**What changed.** The `tuned` package had been sitting in [archiso/packages.x86_64](./archiso/packages.x86_64) installed-but-dormant — no service enabled, no PPD bridge, no profile selected. Finished the job:

- **`tuned-ppd` added** to [archiso/packages.x86_64](./archiso/packages.x86_64) (line 530) — provides the `power-profiles-daemon`-compatible D-Bus interface so XFCE / KDE / GNOME power widgets can drive `tuned` without users dropping to `tuned-adm` in a terminal.
- **`tuned.service` and `tuned-ppd.service` enabled on the live ISO** via symlinks in `archiso/airootfs/etc/systemd/system/multi-user.target.wants/`.
- **Default profile pinned to `throughput-performance`** via `archiso/airootfs/etc/tuned/active_profile` + `profile_mode=manual`. This is the tuned profile that maps to PPD's `performance` mode — DE power widgets will display "Performance" as the active profile on first boot. Chosen over `balanced` / `desktop` because Kiro is explicitly a performance-oriented distro (Liquorix kernel, ohmychadwm, BFQ scheduler, ananicy-cpp); the default should match that positioning rather than hedge.

**Why.** Mid-task audit caught the half-baked state — `tuned` was listed but not wired up, contradicting the README's "Performance Tuned" claim. Without `tuned-ppd`, no DE power widget could see profiles; without a service symlink, the daemon never ran. The CHANGELOG history shows `tuned` was added → removed → re-added over time without a clean finish; this commit closes that loop.

**Follow-up (not in this repo).** The installed system enables services via Calamares, not this overlay. `kiro-calamares-config` and/or `kiro_final` need a matching `systemctl enable tuned.service tuned-ppd.service` so the post-install system inherits the same setup — flagged for the next session.

**Files modified.**
- [archiso/packages.x86_64](./archiso/packages.x86_64)
- `archiso/airootfs/etc/tuned/active_profile` (new)
- `archiso/airootfs/etc/tuned/profile_mode` (new)
- `archiso/airootfs/etc/systemd/system/multi-user.target.wants/tuned.service` (new symlink)
- `archiso/airootfs/etc/systemd/system/multi-user.target.wants/tuned-ppd.service` (new symlink)

## 2026-05-21 — Add WHAT-CHANGED-TO-THE-ISO.md (rolling release log)

**What changed.** New top-level doc [WHAT-CHANGED-TO-THE-ISO.md](./docs/WHAT-CHANGED-TO-THE-ISO.md) added — a rolling, user-facing release log that explains what's actually different between Kiro ISO builds (kernel, audio stack, defaults, calamares, security baseline, tooling). Updated monthly or per significant release; new entries land at the top. First entry covers the 2026-05-17 → 2026-05-21 release window: Liquorix kernel default, PipeWire migration, new `kiro-*` diagnostic toolchain in `edu-system-files`, security hardening pass (live-ISO SSH lockdown, CUPS 0600, sysctl tightening, PAM, udev, BFQ), installer mkinitcpio HOOKS fix + resume hook, version-scheme cleanup, edu-chadwm drop.

**Why.** Users browsing the repo had no single place to see "what's new in this release" — the CHANGELOG is implementation-focused and not pitched at end users, and the per-feature docs (LIQUORIX.md, PIPEWIRE-MIGRATION.md, KIRO-VS-PRISM.md) each cover one thing in depth. The new doc is the elevator-pitch level, with links down into the deep dives. Designed to be the script source for monthly video walkthroughs as well.

**Files modified.**
- [WHAT-CHANGED-TO-THE-ISO.md](./docs/WHAT-CHANGED-TO-THE-ISO.md) (new)

## 2026-05-21 — User-facing LIQUORIX.md rewrite

**What changed.** [LIQUORIX.md](./docs/kernels/LIQUORIX.md) rewritten from a pre-decision "should we switch?" study into a user-facing "why we ship Liquorix" doc. New structure: TL;DR comparison table; what-you'll-feel summary; eight study sections (scheduler, HZ, preemption, memory/IO, security parity, modules, DKMS, update cadence); performance verdict; honest trade-offs (Chaotic-AUR supply chain, no LTS variant); five-file change-set table for forkers; looking-ahead notes (NVIDIA hygiene, LTS fallback, rEFInd, `linux-kiro-lqx` separation).

**Why.** The doc was written before the kernel switch landed. By the time `linux-lqx` was actually shipping in `archiso/packages.x86_64`, `efiboot/loader/entries/*.conf`, `syslinux/*.cfg`, and `kiro-calamares-config/.../unpackfs2.conf`, the doc still asked an already-answered question. Reframing it to "we shipped this, here's the reasoning" makes it useful to readers (potential Kiro users, forkers, anyone evaluating distros) instead of just to past-Erik.

**Files modified.**
- [LIQUORIX.md](./docs/kernels/LIQUORIX.md)

## 2026-05-19 — Deep source-vs-VM verification + duplicate config cleanup

### Source-to-VM integrity check

A full deep comparison was run between the airootfs overlay (kiro-iso), the edu-system-files package overlay, and the actual installed state on the Kiro VirtualBox VM (v26.05.19). Every file in both overlays was traced to its destination on the installed system and verified.

**kiro-audit result: 93 PASS / 0 WARN / 0 FAIL** — the cleanest audit result to date. All checks from the morning security session are confirmed active on the running system.

**Clarification — `10-archiso.conf` is intentional in source.** The file `archiso/airootfs/etc/ssh/sshd_config.d/10-archiso.conf` must remain in the source tree because archiso only creates a directory on the live ISO if at least one file lands in it. Removing the file causes `sshd_config.d/` to be absent, which produces errors. The live ISO needs the override for remote access during the install session; `kiro_final` removes the file from the installed system. Confirmed absent on the VM post-install.

**`do-not-suspend.conf` confirmed intentional.** `archiso/airootfs/etc/systemd/logind.conf.d/do-not-suspend.conf` (disables suspend/hibernate/lid-close) survives to the installed system. This is correct behaviour for a desktop distro — no laptop lid-close events apply.

### Fix — Remove duplicate `memory-accounting.conf` from airootfs

`archiso/airootfs/etc/systemd/system.conf.d/memory-accounting.conf` was a leftover from before `edu-system-files` took over memory accounting configuration. The edu-system-files package already ships `90-memory-accounting.conf` with `DefaultMemoryAccounting=true`. The airootfs copy duplicated this and also set `DefaultSwapAccounting=true`, which is deprecated in modern systemd and produced a warning in the journal on every boot:

```
Unknown key 'DefaultSwapAccounting' in section [Manager], ignoring.
```

The airootfs file was deleted. The edu-system-files package version is now the sole source of truth.

### Claude Code commands added

Two new Claude Code slash commands were created in `~/.claude/commands/` to formalize the release and verification workflows:

- **`/kiro-ready`** — GO/NO-GO release check: verifies git state of all 5 source repos (kiro-iso, kiro-iso-next, kiro-calamares-config, kiro-calamares-config-next, edu-system-files), reads TODO.md for blockers, reads DISTRO_TESTING.md for the last test result, SSHes into the Kiro VirtualBox to run kiro-audit, and checks ISO build recency. Renders a verdict table.
- **`/kiro-check`** — Deep source-vs-VM comparison: checks every security-sensitive file, detects live-environment survivors, finds journal warnings from deprecated config, verifies sysctl values, udev rules, script inventory, and catches git re-add accidents (files deleted and silently re-added by `up.sh`).

**Files Modified:** `archiso/airootfs/etc/systemd/system.conf.d/memory-accounting.conf` (deleted), `~/.claude/commands/kiro-ready.md` (new), `~/.claude/commands/kiro-check.md` (new)

---

## 2026-05-19 — Security audit: Arch vs Kiro comparison + fixes

### SSH tooling for VirtualBox VMs

Two new scripts were written in `~/DATA/arcolinux-nemesis/scripts/`:

- **`ssh-into-kiro-vb.sh`** — fully automated SSH setup for the Kiro VirtualBox VM. The script detects VM state and uses `VBoxManage modifyvm --natpf1` (VM off) or `VBoxManage controlvm natpf1` (VM running) to set up NAT port forwarding idempotently, clears stale `known_hosts` entries, checks for `sshpass`, and connects. On first-attempt failure it prints a guest-setup guide (openssh + sshd + user creation) and retries. Port `2022`.
- **`ssh-into-arch-vb.sh`** — identical structure for a virgin Arch VM used as a comparison baseline. Port `2023`.

Both follow the standard bash template (colors, log functions, error trap, main). A grep bug in the original script was fixed: `rule_exists()` was matching `"ssh-kiro"` (name + closing quote) but VBoxManage's machinereadable format is `"ssh-kiro,tcp,...` (name + comma), causing false "rule missing" errors even when the rule was present.

### Security comparison: Arch vs Kiro

A full 10-phase security and permissions audit was run across both live VMs via SSH. Results written to **`ARCH-VS-KIRO-SECURITY.md`**. Phases covered: users/groups/sudo, SUID/SGID binaries, world-writable files, SSH config, listening ports and firewall, enabled systemd units, key `/etc` files and sysctl, package delta, `/etc` directory permissions, and home/root directories.

**Key finding — Kiro is substantially more hardened than vanilla Arch at the kernel level.** The `99-kiro-optimizations.conf` sysctl profile tightens `kptr_restrict`, `dmesg_restrict`, `ptrace_scope`, `unprivileged_bpf_disabled`, `perf_event_paranoid`, `suid_dumpable`, `sysrq`, and `send_redirects` — all set to safer values than Arch defaults. No unexpected SUID binaries, no world-writable surprises.

Three issues were identified and resolved:

### Fix 1 — Remove archiso SSH override (`PermitRootLogin yes`)

`archiso/airootfs/etc/ssh/sshd_config.d/10-archiso.conf` was shipping with the ISO and surviving into installed systems. It explicitly set `PermitRootLogin yes` and `PasswordAuthentication yes` — intended for the archiso build environment, not for user machines. Neither Kiro's live environment nor its install workflow requires root SSH with password. The file was deleted; OpenSSH's safe default (`prohibit-password`) now applies everywhere. Password login for the user account is unaffected (default sshd behaviour allows it).

### Fix 2 — CUPS config file permissions

`/etc/cups/classes.conf` and `/etc/cups/printers.conf` were world-readable (`644`) on Kiro, compared to `600 root:cups` on a vanilla Arch install. These files can contain printer device URIs and credentials. A `tmpfiles.d` rule was added at `archiso/airootfs/etc/tmpfiles.d/cups-permissions.conf` using the `z` directive to enforce `600 root:cups` on both files at every boot via `systemd-tmpfiles-setup.service`.

### kiro-audit expanded (edu-system-files-git)

`audit.sh` was removed from both `kiro-iso` and `kiro-iso-next` — it was a stale copy superseded by `kiro-audit` in `edu-system-files-git` (which ships to every installed Kiro system at `/usr/local/bin/kiro-audit`). The edu-system-files version was already 40 lines ahead with `--help`, `--version`, and a root check.

`kiro-audit` was then expanded significantly with checks that reflect this session's security work and general system health:

- **`check_sysctl_security()`** — verifies all 8 hardening values from `99-kiro-optimizations.conf` are live on the running system: `kptr_restrict`, `dmesg_restrict`, `ptrace_scope`, `unprivileged_bpf_disabled`, `perf_event_paranoid`, `suid_dumpable`, `send_redirects`, `tcp_syncookies`. Catches any regression where the sysctl file exists but values aren't applied.
- **`check_zram()`** — verifies `zram-generator` is installed, config is present, `/dev/zram0` is active as swap, and compression is `zstd`.
- **`check_failed_units()`** — fails if any systemd units are in failed state.
- **`check_boot_and_updates()`** — INFO-only: prints boot time (`systemd-analyze`) and pending update count. No PASS/FAIL threshold.
- **`check_permissions()` expanded** — now also checks that `10-archiso.conf` SSH override is absent, `tmpfiles.d/cups-permissions.conf` is present, and CUPS config files are `600` if they exist.
- **MAKEFLAGS CPU check** — replaced the basic `-j exists` check with a `nproc` comparison: PASS if MAKEFLAGS `-j` matches actual CPU count, WARN if fewer, FAIL if missing.

The audit was run on the test box (real metal, `<ip>:<port>`) and produced 79 PASS / 0 WARN / 4 FAIL — the 4 FAILs are all expected pre-fix issues from the test box's older ISO install (archiso SSH override, missing tmpfiles.d, CUPS permissions). All new checks behaved correctly on real hardware.

### Real metal SSH script

`ssh-into-testbox.sh` added to `~/DATA/arcolinux-nemesis/scripts/`. Simpler than the VirtualBox scripts — no NAT forwarding needed, just a reachability ping check before connecting with `sshpass`. Host `<ip>`, port `<port>`, user `<user>`.

### Security fixes synced to kiro-iso-next

All three security fixes (SSH override removal, CUPS tmpfiles.d, ARCH-VS-KIRO-SECURITY.md) were applied to `kiro-iso-next` as well — both production and beta repos are now in sync.

### Fix 3 — rlogin/rsh (inetutils) — accepted as-is

`inetutils` ships `rlogin`/`rsh` PAM configs as a side effect of providing `ifconfig`, which Kiro needs. No systemd units for those legacy daemons are enabled; no daemon is running. Risk is theoretical only — accepted.

**Files Modified:** `archiso/airootfs/etc/ssh/sshd_config.d/10-archiso.conf` (deleted), `archiso/airootfs/etc/tmpfiles.d/cups-permissions.conf` (new), `ARCH-VS-KIRO-SECURITY.md` (new)

---

## 2026-05-18 — TODO housekeeping

Short session. No code changed — this was a pure status-tracking pass after earlier build and boot testing.

**BIOS/syslinux boot path verified.** The syslinux configs had been updated for `linux-lqx` in a previous session but only UEFI (GRUB + systemd-boot in VirtualBox) had been confirmed working. BIOS boot was tested and confirmed good. Moved from Backlog to Done.

**PipeWire status confirmed.** The PipeWire stack was marked "Needs build + audio test" — now confirmed verified working.

**Remaining open item:** NVIDIA `driver=nonfree` boot + DKMS compile against `linux-lqx-headers` on real NVIDIA hardware. Only remaining Backlog item.

**Files Modified:** `TODO.md`

---

## 2026-05-18 — `v26.05.18.01`

### ISO audit: VirtualBox installed-system verification + audit.sh

**Build script fix — `isoLabel` missing `next`.** The checksum phase at the end of `build-the-iso.sh` was constructing `isoLabel="kiro-${kiroVersion}-x86_64.iso"` but `mkarchiso` produces filenames from `iso_name` in `profiledef.sh`, which is `kiro-next`. The mismatch caused sha1sum/sha256sum/md5sum to fail with "No such file or directory" on every build. Fixed to `isoLabel="kiro-next-${kiroVersion}-x86_64.iso"`.

**`audit.sh` — installed system health checker.** A comprehensive `audit.sh` script was written and committed to the repo root (also synced to `edu-system-files/usr/local/bin/`). It SSHes into or runs locally on an installed Kiro system and checks 63+ conditions across: kernel (`linux-lqx`), microcode (correct vendor, wrong one removed), mkinitcpio hooks (no archiso hook, microcode/kms present), audio stack (PipeWire complete, pulseaudio absent), all 4 Calamares module results (`kiro_before`, `kiro_final`, `kiro_remove_nvidia`, `kiro_ucode`), pacman repos, desktop session files, SDDM theme, user groups, systemd services, key file permissions, NVIDIA handling, bootloader, and `pacman -Qk` package integrity. Results are grouped as PASS / WARN / FAIL with a summary count. Designed to be extended month-by-month.

**VirtualBox audit findings (v26.05.18.01, UEFI, Intel VirtualBox):**
- 63 PASS — all core functionality verified working
- 1 WARN — `/etc/calamares/` config dir left on system (explained by the FAIL below)
- 1 FAIL — `kiro-calamares-config-next` still installed; `kiro_final`'s final removal step ran `pacman -R --noconfirm kiro-calamares-config-next` inside a `try/except` that swallows the failure — the package has no dependencies and is manually removable, but the silent failure means it wasn't cleaned up at install time
- Firmware warnings during build (`softing_cs`, `lantiq_gswip`, `adf7242`) are benign — ultra-niche hardware with no firmware in any Arch package; harmless and unfixable without blacklisting modules
- `pacman -Qk` exceptions: `ohmychadwm-git` (makepkg cleans build artifacts), `bind`/`cups`/`nfs-utils` (config files created only when services are first used) — all whitelisted in audit.sh

**Files Modified:** `build-scripts/build-the-iso.sh`, `audit.sh` (new)

---

### edu-chadwm dropped; README accuracy overhaul

**`edu-chadwm` removed going forward.** The package `edu-chadwm-git` was already commented out in `archiso/packages.x86_64`, but references to it persisted in `build-scripts/build-the-iso.sh` (the `desktop` label variable), `CLAUDE.md`, and `README.md`. All forward-facing references have been cleaned up. CHANGELOG historical entries were left intact — they accurately describe what the ISO shipped at the time.

**README rewritten for accuracy.** A full audit revealed several stale or incorrect entries:

- `enable-oomd.sh` and `disable-oomd.sh` were referenced in the project tree and Key Scripts section but do not exist in the repo — removed
- `personal_repo/` was listed as a root-level directory — it does not exist; the relevant comment is in `archiso/pacman.conf` — removed
- `packages.bootstrap` was listed with the wrong name; the actual file is `bootstrap_packages` — corrected
- `setup.sh`, `change-version.sh`, `up.sh`, and `CHANGELOG.md` were missing from the project tree — added
- The Building KIRO section omitted the required first step (`change-version.sh`) and made no mention of the NVIDIA driver selection knob — both added
- "Based on the ArcoLinux project" in the Overview — ArcoLinux branding reference removed
- The stale "Recent Changes" section (listing Calamares migrations from months ago) replaced with a link to `CHANGELOG.md`
- ArcoLinux tutorial link removed from Resources
- `✅` emoji bullets and the `🖖` sign-off removed throughout

**Files Modified:** `build-scripts/build-the-iso.sh`, `CLAUDE.md`, `README.md`

---

### Build script standardization — full template conformance pass

All four build scripts were audited against the project standard template (modelled on `up.sh`) and brought into full conformance. This was a correctness and maintainability pass, not cosmetic cleanup — several of the changes fix real failure modes that were silently swallowed before.

#### `build-scripts/build-the-iso.sh`

The most significant rewrite. The old script had `set -e` only, meaning unset variable references and failed pipe segments would silently continue and corrupt the build in hard-to-diagnose ways. It also had no error trap, so a failing phase gave no indication of *where* it failed.

The new version adds `set -euo pipefail` and the standard `on_error` trap that prints the failing line number and command. Beyond that:

- **`SCRIPT_DIR` / `REPO_DIR`** replace the hand-rolled `installed_dir="$(dirname)/.."` pattern. All file paths are now anchored to the script's location, so the build works correctly regardless of which directory you call it from.
- **`check_not_root()`** hard-aborts if run as root. The old version only printed a warning and continued — a user who missed the message would proceed to build as root, which `mkarchiso` handles poorly.
- **`wget` failure guard** — the old code fetched `.bashrc` from edu-shells with no failure check. If the download failed (network blip, GitHub down), the build would continue with whatever stale content was in skel. Now a failed download aborts with a clear error.
- **Safe skel cleanup** — `rm -rf skel/.*` was replaced with `find -mindepth 1 -delete`. The `.*` glob can expand to include `.` or `..` on some systems, which would be catastrophic.
- **Config block at the top** — `nvidia_driver`, `clean_pacman_cache`, and `remove_build_folder` are now gathered at the top of the file before any functions. Previously these knobs were scattered through 490 lines; now they're the first thing you see when you open the file.
- **Named phase functions** — each build phase is now a function (`prepare_build_tree`, `prepopulate_keyring`, `inject_nvidia_packages`, etc.) called from `main()`. This makes the high-level flow immediately readable and allows individual phases to be tested in isolation.
- **Removed dead code** — `archisoRequiredVersion="archiso 84-1"` was declared but never checked anywhere in the script. Removed.
- **TTY-safe colors** — raw `tput setaf` calls had no `[[ -t 1 ]]` guard. If the script was ever piped or redirected, the escape codes would corrupt the output. The new colors block falls back to empty strings when stdout is not a terminal.
- **Startup `sleep` calls removed** — there were `sleep 2` and `sleep 3` calls at startup that served no purpose. The BTRFS countdown (10 seconds with CTRL+C prompt) was intentionally kept — that one gives the user a real chance to abort.
- **Phase numbering fixed** — the old script had phases 1, 2, 3, 4, 4b, 5, 7, 8, 9 (Phase 6 missing entirely, 4b awkward). Phases are now sequential 1–9.

#### `change-version.sh`

Added `set -euo pipefail`, the standard header, `SCRIPT_DIR`, TTY-safe colors, log functions, and `on_error` trap. Previously, if any `sed` call silently failed (e.g. a regex didn't match because a file format changed), the version bump would partially update some files and leave others stale — and the script would exit 0. Now any failure aborts immediately and reports the line. All paths anchored to `SCRIPT_DIR` so the script works from any working directory. Dead commented-out debug lines removed. Logic wrapped in `bump_version()` inside `main()`.

#### `build-scripts/get-pacman-repos-keys-and-mirrors.sh`

**Critical fix:** the `pacman.conf` copy used `new_conf="pacman.conf"` — a bare filename resolved against `$PWD`. If `build-the-iso.sh` called this script (which it does, via `bash "$SCRIPT_DIR/get-pacman-repos-keys-and-mirrors.sh"`), the working directory at call time is the repo root, not `build-scripts/`. The copy would fail or source the wrong file. Fixed to `"${SCRIPT_DIR}/pacman.conf"`. Also brought into full template conformance with standard header, colors, log functions, and `on_error` trap.

#### `build-scripts/install-yay-or-paru.sh`

The yay and paru install branches were identical except for the package name and URL — a straight copy-paste. Collapsed into a single `install_aur_helper name url` function. Added `/tmp` cleanup after `makepkg` (the original left the tarball and source directory behind). Full template conformance.

#### `archiso/airootfs/etc/dev-rel`

`ISO_CODENAME` was still set to `arconet - kiro` — a leftover ArcoLinux branding reference. Changed to `kiro`.

---

**Files Modified:** `build-scripts/build-the-iso.sh`, `build-scripts/get-pacman-repos-keys-and-mirrors.sh`, `build-scripts/install-yay-or-paru.sh`, `change-version.sh`, `archiso/airootfs/etc/dev-rel`, `TODO.md` (created stub)

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
