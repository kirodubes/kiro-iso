# TODO

## In Progress

## Up Next

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
