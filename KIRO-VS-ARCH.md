# Arch vs Kiro — Security & Permissions Comparison

**Date:** 2026-05-19  
**Method:** SSH into both live VirtualBox VMs; 10-phase data collection  
**Arch VM:** `127.0.0.1:2023` (virgin install)  
**Kiro VM:** `127.0.0.1:2022` (Kiro production ISO)

---

## Summary

Kiro is significantly more hardened than a vanilla Arch install at the kernel level (sysctl), but ships several post-install cleanup items that should be addressed before a system goes to a real user. No rogue SUID binaries, no world-writable surprises, but three concrete issues need attention.

---

## Phase 1 — Users, Groups & sudo

### System Users
Kiro ships many more system users due to its wider package set:

| Extra on Kiro | Purpose |
|---|---|
| `named` | BIND DNS (bind package) |
| `dnsmasq` | dnsmasq daemon |
| `_talkd` | Legacy talk daemon |
| `nbd` | Network block device |
| `nm-openconnect`, `nm-openvpn` | VPN daemons |
| `nvidia-persistenced` | NVIDIA persistence daemon |
| `openvpn` | OpenVPN |
| `partimag` | Partimage backup tool |
| `rpc`, `rpcuser` | NFS RPC |
| `saned` | SANE scanner daemon |
| `usbmux` | iOS USB multiplexer |

All are legitimate service accounts with `/usr/bin/nologin` shells. No unexpected login-capable accounts.

### User `erik` — Group Membership
Kiro adds `erik` to many groups that Arch does not:

```
sys, network, power, adm, wheel, uucp, optical, rfkill,
video, storage, audio, users, scanner, lp, vboxsf, i2c
```

This is intentional for a desktop distro — gives the user access to hardware without sudo. Expected and correct.

### sudo Configuration
| | Arch | Kiro |
|---|---|---|
| File | `/etc/sudoers.d/00_erik` | `/etc/sudoers.d/10-installer` |
| Rule | `erik ALL=(ALL) ALL` | `%wheel ALL=(ALL:ALL) ALL` |
| Style | Direct user grant | Group-based (better) |

**Kiro is better here.** Wheel-group sudo is the correct practice — adding a user to wheel grants sudo, removing from wheel revokes it, without editing sudoers.

---

## Phase 2 — SUID / SGID Binaries

### Extra SUID on Kiro (vs Arch)
All are expected given the installed packages:

| Binary | Reason |
|---|---|
| `/opt/brave-bin/chrome-sandbox` | Brave browser sandbox |
| `/opt/vivaldi/vivaldi-sandbox` | Vivaldi browser sandbox |
| `/usr/lib/signal-desktop/chrome-sandbox` | Signal sandbox |
| `/usr/bin/crontab` | cronie — users need SUID to manage crontabs |
| `/usr/bin/fusermount` | FUSE mounting |
| `/usr/bin/mount.cifs` | CIFS/Samba mounting |
| `/usr/bin/mount.ecryptfs_private` | eCryptfs home mounting |
| `/usr/bin/mount.nfs` | NFS mounting |
| `/usr/bin/ndisc6`, `rdisc6`, `rltraceroute6` | IPv6 tools (ndisc6 package) |
| `/usr/bin/slock` | Screen locker (needs SUID to lock TTY) |

### Extra SGID on Kiro
| Binary | Reason |
|---|---|
| `/usr/bin/mount.cifs` | (also SGID) |
| `/usr/bin/mount.ecryptfs_private` | (also SGID) |
| `/usr/bin/plocate` | plocate database needs group access |

**No unexpected SUID/SGID binaries.** All are explained by packages Kiro ships.

---

## Phase 3 — World-Writable Files

**No differences.** Both systems are clean — no unexpected world-writable files outside of `/proc`, `/sys`, `/dev`, `/run`.

---

## Phase 4 — SSH Configuration

### ⚠️  Issue: archiso SSH override not removed post-install

Kiro has `/etc/ssh/sshd_config.d/10-archiso.conf`:

```
PasswordAuthentication yes
PermitRootLogin yes
```

This file is placed by the archiso live environment to allow remote installation. It **should be deleted** after Calamares finishes — it enables root SSH login with password on installed systems.

Arch (as a normal install) does not have this file; its sshd defaults to `PermitRootLogin prohibit-password`.

**Action needed:** Add removal of `/etc/ssh/sshd_config.d/10-archiso.conf` to the Calamares post-install cleanup or `kiro_final`.

---

## Phase 5 — Listening Ports & Firewall

### Listening ports
| Port | Arch | Kiro |
|---|---|---|
| 22 (SSH) | yes | yes |
| 631 (CUPS) | yes | yes |
| 53 (DNS) | no | yes — `systemd-resolved` |
| 5355 (mDNS) | no | yes — `systemd-resolved` |

systemd-resolved's port 53 is bound to `127.0.0.54` and `127.0.0.53` only (loopback) — not exposed externally.

### Firewall
| | Arch | Kiro |
|---|---|---|
| nftables | not installed | not installed |
| iptables | not installed | installed, **no rules** (ACCEPT all) |

**Note:** Kiro has `iptables` loaded but with empty chains (`policy ACCEPT`). This means no firewall is active. For a desktop this is typical, but worth documenting. Arch has no firewall either — same exposure, but Kiro's empty iptables table could give a false sense of security if someone checks `iptables -L`.

---

## Phase 6 — Enabled Systemd Units

Extra services enabled on Kiro (not present on Arch):

| Unit | Purpose |
|---|---|
| `ananicy-cpp` | CPU/IO priority daemon for responsiveness |
| `avahi-daemon` | mDNS/DNS-SD (network discovery) |
| `pamac-cleancache.timer` | Periodic pacman cache pruning |
| `pci-latency` | PCI bus latency optimizer |
| `systemd-oomd` | Out-of-memory daemon (graceful OOM handling) |
| `systemd-resolved` | DNS resolver with caching |
| `vboxservice` | VirtualBox guest additions |

All are legitimate desktop services. `avahi-daemon` enables mDNS service discovery — acceptable for a desktop, slightly increases network exposure compared to a minimal server.

---

## Phase 7 — Key /etc Files

### /etc/nsswitch.conf
Kiro ships a custom `nsswitch.conf` from the arcolinux-nemesis repo, adding:
- `mdns_minimal` — mDNS hostname resolution
- `wins` — Windows name resolution (Samba/CIFS)

This is needed for the network tools Kiro bundles. Slightly wider name resolution surface than vanilla Arch.

### /etc/pam.d — Extra PAM configs on Kiro
Kiro has these PAM configs not present on Arch:

| File | Package | Risk |
|---|---|---|
| `crond` | cronie | Normal |
| `i3lock` | i3lock | Normal |
| `partimaged` | partimage | Normal |
| `screen` | screen | Normal |
| `rlogin` | inetutils | ⚠️ Legacy protocol |
| `rsh` | inetutils | ⚠️ Legacy protocol |

`rlogin` and `rsh` PAM configs are present because `inetutils` is installed. The services themselves are not enabled, but the PAM stack is configured for them. Not an active risk unless `rlogin`/`rsh` daemons are started.

### /etc/cups — Permission difference
| File | Arch | Kiro |
|---|---|---|
| `classes.conf` | `-rw-------` (root:cups) | `-rw-r--r--` (world-readable) |
| `printers.conf` | `-rw-------` (root:cups) | `-rw-r--r--` (world-readable) |

**⚠️ Issue:** CUPS config files (which contain printer names, device URIs, and potentially credentials) are world-readable on Kiro. Arch keeps them `root:cups` with `600`. This is a permission regression.

### /etc/sysctl.d — Kernel Hardening

Kiro ships `99-kiro-optimizations.conf` — a large, well-documented sysctl profile. Security-relevant comparison:

| Parameter | Arch default | Kiro |
|---|---|---|
| `fs.suid_dumpable` | `2` (world-readable core dumps) | `0` (disabled) ✓ |
| `kernel.kptr_restrict` | `0` (no restriction) | `2` (admin only) ✓ |
| `kernel.dmesg_restrict` | `0` | `1` ✓ |
| `kernel.perf_event_paranoid` | `2` | `3` ✓ |
| `kernel.yama.ptrace_scope` | `0` | `1` ✓ |
| `kernel.unprivileged_bpf_disabled` | `0` | `1` ✓ |
| `kernel.sysrq` | `16` (sync only) | `244` (REISUB only) ✓ |
| `net.ipv4.conf.all.send_redirects` | `1` | `0` ✓ |
| `net.ipv4.tcp_syncookies` | `1` | `1` — same |
| `fs.suid_dumpable` (core pattern) | default | `\|/bin/false` ✓ |
| `vm.overcommit_memory` | `0` | `1` ⚠️ |

**Kiro is substantially more hardened at the kernel level than vanilla Arch.**

One note: `vm.overcommit_memory = 1` (always allow memory overcommit) is safe only when ZRAM is active. The config file comments acknowledge this. If ZRAM is missing, OOM behaviour can become unpredictable.

---

## Phase 8 — Package Delta

Kiro ships ~350+ packages not in a virgin Arch install. Security-relevant additions:

**Network / VPN surface (wider attack surface):**
- `bind`, `dnsmasq`, `nfs-utils`, `nbd`
- `networkmanager-openconnect/openvpn/pptp/vpnc`
- `openvpn`, `openconnect`, `vpnc`, `ppp`, `xl2tpd`
- `inetutils` (brings rlogin/rsh/rcp binaries)

**Browsers (SUID sandboxes):**
- `brave-bin`, `vivaldi`, `signal-desktop`

**Dev/build tools:**
- `base-devel`, `gcc`, `make` — standard for an Arch desktop

**AUR helpers:**
- `paru-git`, `yay-git` — expected

**Backup/recovery:**
- `partimage`, `partclone`, `clonezilla`, `ddrescue`, `testdisk`

None of these are unexpected given Kiro's purpose as a full desktop distro with installer tooling.

---

## Phase 9 — /etc Directory Permissions

No structural permission issues beyond the CUPS files noted in Phase 7. All directories under `/etc` have standard `root:root 755` or tighter permissions. Kiro has a much larger `/etc` tree due to the wider package set, but no anomalous ownership or world-writable paths were found.

---

## Phase 10 — Home Directory

### /home/erik
| | Arch | Kiro |
|---|---|---|
| `.bashrc` size | 172 bytes (minimal) | 13775 bytes (full custom) |
| `.zshrc` | absent | 17310 bytes |
| `.bin/` | absent | present — 40+ user scripts |
| `.fehbg` | absent | present, **executable** (`-rwxr-xr-x`) |
| `.screenrc` | absent | present |
| `.config/` entries | 4 dirs | 26 dirs (full desktop config) |
| `.ssh/` | present (empty agent dir) | absent |
| `.gnupg/` | present | absent |

The populated `.bin/` and dotfiles are Kiro's user experience — expected. `.fehbg` is world-readable and executable; it only sets the wallpaper so this is not a risk, but world-execute on a dotfile is mildly unusual.

### /root (root home)
| | Arch | Kiro |
|---|---|---|
| Size | ~5 files (minimal) | ~15 files + `.bin/`, `.config/` |
| `.bashrc` | 172 bytes | 13775 bytes (same as user) |
| `.bin/` | absent | present (same scripts as user) |
| `.fehbg` | absent | present, executable |
| `.config/` | absent | 23 directories |

Kiro populates root's home the same way as the user's home. This means root has a full shell environment out of the box. Not a security vulnerability but worth noting — `/root/.bin/` contains scripts with execute permissions.

---

## Action Items

| Priority | Item | Status | Phase |
|---|---|---|---|
| **High** | Remove `/etc/ssh/sshd_config.d/10-archiso.conf` (`PermitRootLogin yes`) | ✓ Done 2026-05-19 | 4 |
| **Medium** | Fix CUPS config permissions via tmpfiles.d | ✓ Done 2026-05-19 | 9 |
| **Low** | `inetutils` rlogin/rsh — no daemons running, kept for `ifconfig` | ✓ Accepted | 7 |
| **Low** | `virtualbox-guest-utils` / `vboxservice` — no-op on real hardware, modules won't load on `linux-lqx` without DKMS | ✓ Kept intentionally (testing convenience) | 6 |
| **Info** | `vm.overcommit_memory = 1` requires ZRAM — confirmed active via `zram-generator` + `edu-system-files-git` config (`zstd`, `min(ram/2, 4GB)`, priority 100) | ✓ Safe | 7 |
| **Info** | `iptables` installed but empty rules — no firewall by design | ✓ Accepted | 5 |
