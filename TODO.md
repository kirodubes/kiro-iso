# TODO

## In Progress

## Up Next

- **Test the chwd nvidia-open DKMS patch end-to-end on a modern NVIDIA GPU** — _added 2026-05-29._ The patch (chwd 1.21.0-4, `[nvidia-open-dkms]` profile → `nvidia-open-dkms` + per-kernel `-headers` instead of prebuilt `${kernel}-nvidia-open`) is confirmed *present and correct* on worf, but worf's GT 620M routes to nouveau so the profile never fired. Need a box with a modern NVIDIA card that chwd selects `nvidia-open-dkms` for, then verify on the installed system: `nvidia-open-dkms` + the right `-headers` installed, DKMS status `installed` (not just `added`), `nvidia-smi` works, and **no** `linux-cachyos-nvidia-open`.
- **Decide whether to drop `nvidia_driver=390xx` (and 470xx) — they can't build on the 7.0 kernel** — _added 2026-05-29._ `nvidia-390xx-dkms 390.157` fails to compile (`'screen_info' undeclared`, removed from modern kernels), so any card routed to the 390xx path gets a driverless system; nouveau is the correct driver for those Fermi cards (chwd already routes them there). Verify `nvidia-470xx-dkms` against the 7.0 kernel; if it also fails, remove both options from [build-scripts/build-the-iso.sh](build-scripts/build-the-iso.sh) `inject_nvidia_packages()` and consider dropping/deprioritizing the matching chwd profiles so they never select a non-buildable driver.

## Backlog

## Done

- **Choose a different kernel to build the ISO** — _added 2026-05-27; done 2026-05-28._ Switched the ISO default from `linux-lqx` to **`linux-cachyos linux-zen`** (cachyos = live-boot + default after install; zen = secondary, both installed). Single-line change in [build-scripts/build-the-iso.sh](build-scripts/build-the-iso.sh) line 101 — `apply_kernel()` (line 514+) auto-rewrites packages.x86_64, the live mkinitcpio presets, and all boot loader entries (efiboot, grub.cfg, loopback.cfg, syslinux) from this single source-of-truth variable at build time. `CANONICAL_KERNEL=linux-lqx` left untouched (it's the *source token* the sed-templating substitutes FROM, matching the literal paths in the archiso tree). Calamares side needs nothing — `kiro_kernel` is already kernel-agnostic.
- **Fix tuned-ppd clobbering airootfs active_profile** — root cause was tuned-ppd's `Controller.initialize()` reading the recommended profile from tuned (which returned `balanced` due to `virt-what` missing + generic fallback) BEFORE consulting `ppd.conf`'s `default=`. The misleading "default=" override in `ppd.conf` never actually fired. Fixed by pre-seeding `/etc/tuned/ppd_base_profile = performance` in the airootfs — that file is step 1 of the short-circuit chain and short-circuits the whole problem. Misleading comment in `ppd.conf` rewritten to document the real selection order. Verified on installed Kiro VM (2026-05-22).
- **Fix wrong microcode left installed after Calamares install** — `kiro_ucode` now removes the non-matching ucode package after installing the correct one. Verified working.
- **Fix grub.cfg and loopback.cfg kernel paths for linux-lqx** — all paths updated to `vmlinuz-linux-lqx` / `initramfs-linux-lqx.img`. Verified working.
- **linux.preset cleanup in installed system** — `kiro_final` now removes the archiso-only `linux.preset` artifact from the installed target. Verified working.
- **PipeWire as default audio stack** — replaced `pulseaudio`, `pulseaudio-alsa`, `pulseaudio-bluetooth` with `pipewire`, `pipewire-alsa`, `pipewire-audio`, `pipewire-pulse`, `wireplumber`, `gst-plugin-pipewire`, `pamixer`. Verified working.
- **Test BIOS/syslinux boot path** — syslinux configs updated for linux-lqx. BIOS boot verified working.
- **Test NVIDIA mode on real hardware** — `driver=nonfree` boot + DKMS compile against `linux-lqx-headers` verified working on real NVIDIA GPU.
