# Distro Testing Log

Results of boot and install testing for kiro-iso-next builds. Newest first.

---

## 2026-05-18 — v26.05.18.01 — VirtualBox (UEFI, Intel, NAT)

**Environment:** VirtualBox 7.x, UEFI firmware, Intel CPU (amd-ucode correctly absent), NAT networking with SSH port forwarding 2222→22

**Boot:** PASS — UEFI boot via systemd-boot, linux-lqx 7.0.9-lqx1-1-lqx kernel loaded

**Install:** Calamares install completed. Post-install audit via `audit.sh`:

| Check | Result |
|---|---|
| Kernel (linux-lqx running) | PASS |
| Boot files (vmlinuz-linux-lqx, initramfs) | PASS |
| Microcode (intel-ucode, no amd-ucode) | PASS |
| mkinitcpio (no archiso hook, has microcode/kms) | PASS |
| linux-lqx.preset exists, linux.preset removed | PASS |
| PipeWire stack complete, pulseaudio absent | PASS |
| calamares + mkinitcpio-archiso removed | PASS |
| kiro-calamares-config-next removed | **FAIL** |
| Calamares live-only artifacts cleaned up | PASS |
| /root permissions 700, sudoers.d 750, polkit 750 | PASS |
| EDITOR=nano, Bluetooth AutoEnable=true | PASS |
| makepkg.conf optimized (MAKEFLAGS, PKGEXT, !debug) | PASS |
| Pacman repos (nemesis_repo, chaotic-aur, multilib) | PASS |
| ohmychadwm + XFCE desktop entries | PASS |
| SDDM edu-simplicity theme | PASS |
| User groups (wheel, audio, video, storage…) | PASS |
| Services (NetworkManager, sddm, bluetooth) | PASS |
| shadow/gshadow 400 permissions | PASS |
| NVIDIA (correctly absent, no GPU) | PASS |
| systemd-boot installed | PASS |
| Package integrity (pacman -Qk) | PASS |

**Score:** 63 PASS, 1 WARN (/etc/calamares dir leftover — caused by FAIL below), 1 FAIL

**Known issue:** `kiro-calamares-config-next` not removed post-install — `kiro_final` removal step fails silently (pacman lock race suspected). Package is manually removable. Does not affect system functionality.

**BIOS/syslinux boot path:** Not tested (VirtualBox uses UEFI). See TODO.md.
