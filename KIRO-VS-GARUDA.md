# KIRO VS GARUDA — Config Research

**Last checked:** 2026-05-28
**Next check:** 2026-08-28 (quarterly)

**Purpose:** Inspect Garuda Linux's system configuration to identify settings
or approaches that could improve Kiro's `edu-system-files`. Garuda is a
reference only — no changes are made to it.

**Method:** SSH into a Garuda Mokka VirtualBox live ISO, read its tuning
configs over the wire, compare against `~/EDU/edu-system-files/`, and record
findings here. Any improvement goes into `edu-system-files` on Kiro.

---

## Machine Details

| Detail           | Kiro (HQ)                            | Garuda (reference)                       |
|------------------|--------------------------------------|------------------------------------------|
| Distro           | Kiro (Arch-based)                    | Garuda Mokka (Arch-based)                |
| Kernel           | linux-cachyos (default) + linux-zen  | linux-zen 6.19.6-zen1-1-zen              |
| RAM              | 32 GB                                | 10 GB (VM)                               |
| Machine type     | Bare metal                           | VirtualBox VM, live ISO                  |
| SSH              | local                                | `ssh-into-garuda-vb.sh` host:2024→22     |
| edu-system-files | installed                            | n/a                                      |
| Desktop          | XFCE4 + ohmychadwm                   | KDE Plasma (Garuda Mokka)                |

---

## Surprise: Garuda's tuning footprint is small

The popular impression is that Garuda ships a thick stack of low-level tweaks.
The reality: nearly all of it lives in **one** package, `garuda-common-settings`,
and it's modest. Their entire sysctl is 7 lines of their own + 2 lines imported
from SteamOS. Everything else is short systemd drop-ins and a handful of
modprobe options.

That makes this comparison "what's *clever* in their narrow set" rather than
"what big toolkit do they have that we don't."

### Garuda's full tuning footprint (inventoried 2026-05-28)

**sysctl** (`/usr/lib/sysctl.d/`):
- `99-sysctl-garuda.conf` — `vm.swappiness=133`, `kernel.nmi_watchdog=0`, `kernel.unprivileged_userns_clone=1`, `kernel.printk = 3 3 3 3`, `kernel.sysrq=1`
- `20-net-timeout.conf` (SteamOS import) — `net.ipv4.tcp_fin_timeout = 5`
- `20-sched.conf` (SteamOS import) — `kernel.sched_cfs_bandwidth_slice_us = 3000`

**modprobe** (`/usr/lib/modprobe.d/`):
- `bluetooth-usb.conf` — `options btusb reset=1`
- `noime.conf` — `blacklist mei`, `blacklist mei_me`
- `nobeep.conf` — `blacklist pcspkr`

**systemd drop-ins** (`/usr/lib/systemd/`):
- `system.conf.d/limits.conf` — NOFILE=1048576, NPROC=1048576
- `system.conf.d/timeout.conf` — TimeoutStopSec=10s, TimeoutAbortSec=10s
- `user.conf.d/limits.conf` — NOFILE=1048576, NPROC=1048576
- `journald.conf.d/00-journal-size.conf` — SystemMaxUse=50M
- `oomd.conf.d/10-oomd-defaults.conf` — DefaultMemoryPressureDurationSec=20s
- `system/system.slice.d/10-oomd-per-slice-defaults.conf` — ManagedOOMMemoryPressure=kill, Limit=80%
- `user/slice.d/10-oomd-per-slice-defaults.conf` — same

**zram:** `zram-size=ram, compression-algorithm = zstd` (100% of RAM)

**limits:** `99-realtime-privileges.conf` for `@realtime` group (rtprio 98, memlock unlimited, nice -11)

**tmpfiles:** `disable-zswap.conf` — turns off kernel zswap so it doesn't double-compress against zram

**NetworkManager:** `unmanaged-lo.conf` — tells NM not to manage `lo`

---

## Comparison

| Area | Garuda | Kiro (edu-system-files) | Verdict |
|---|---|---|---|
| `vm.swappiness` | 133 | 150 | Ours fine — closer to modern Arch ZRAM convention |
| `kernel.sysrq` | 1 (full) | 244 (REISUB only) | Ours more secure |
| `tcp_fin_timeout` | 5 (SteamOS) | 20 | Ours fine, theirs is gaming-tuned |
| `kernel.sched_cfs_bandwidth_slice_us` | 3000 (SteamOS) | not set | **Consider** |
| `nmi_watchdog`, `unprivileged_userns_clone`, `printk` | same | same | Already aligned |
| ZRAM size | `ram` (100%) | `min(ram/2, 4096)` | Ours conservative; theirs bold |
| `disable-zswap` tmpfile | yes | no | **Adopt** |
| `blacklist mei + mei_me` (Intel ME) | yes | no | **Adopt** |
| `btusb reset=1` | yes | no | **Adopt** |
| NetworkManager `unmanaged-lo` | yes | no | **Adopt** |
| `systemd-oomd` enabled + tuned | yes (80% pressure, 20s) | no (only sysctl prep) | **Adopt — biggest gap** |
| `DefaultLimitNPROC` | 1048576 | 30000 | Ours saner; theirs unbounded fork-bomb risk |
| `journald SystemMaxUse` | 50M | 100M | Ours better for debugging |
| Power daemon | power-profiles-daemon | tuned-ppd | Different paths, both fine |
| Audio realtime group | `@realtime` rtprio 98 | `@audio` rtprio 99 | Naming convention; both work |
| `nobeep` / `disable-evbug` | both | both | Already aligned |

---

## Adopted (implemented 2026-05-28)

All 5 items below verified **kernel-agnostic** (see "Kernel-agnostic rule" section
below) before adoption.

### 1. systemd-oomd enabled + tuned (the biggest gap)

Files added in `edu-system-files`:
- `etc/systemd/oomd.conf.d/10-kiro-oomd.conf` — `DefaultMemoryPressureDurationSec=20s`
- `etc/systemd/system/system.slice.d/10-kiro-oomd-per-slice.conf` — `ManagedOOMMemoryPressure=kill, ManagedOOMMemoryPressureLimit=80%`
- `etc/systemd/user/slice.d/10-kiro-oomd-per-slice.conf` — same

Service enabled via Calamares in both `kiro-calamares-config` and
`kiro-calamares-config-next` (`services-systemd.conf`, `mandatory: false`).

**Why:** the kernel OOM killer only fires when memory is already exhausted; by
that point the desktop has been swapping itself unresponsive for seconds.
systemd-oomd watches PSI memory pressure and intervenes *earlier*, killing the
worst offender slice. Real win on 4-8 GiB systems under browser/IDE load.

**Tradeoff:** oomd can kill a misbehaving GUI app before the user notices. Most
distros now accept that trade; we agree.

### 2. Intel ME blacklist (`mei`, `mei_me`)

File added: `etc/modprobe.d/blacklist-intel-me.conf`.

**Why:** Intel Management Engine is an always-on co-processor with network
access and a long CVE history (SA-00086 / CVE-2017-5705 / etc.). Blacklisting
the kernel-side drivers does NOT disable ME itself (only BIOS or `me_cleaner`
does), but removes the userspace attack surface. Whonix, Tails, Garuda all do
this.

**Tradeoff:** breaks vPro / AMT remote management — irrelevant for desktop
users.

### 3. `options btusb reset=1`

File added: `etc/modprobe.d/bluetooth-usb.conf`.

**Why:** fixes the common "Bluetooth works on cold boot, dead after
suspend/resume" pattern that plagues Intel AX200/AX201/AX210 and
Realtek RTL8822 combo cards.

**Tradeoff:** none practical.

### 4. Disable kernel zswap (defensive)

File added: `etc/tmpfiles.d/disable-zswap.conf`.

**Why:** with zram-generator providing swap, leaving zswap on means
double-compression (zswap on cache, then zstd again as it hits zram).
Wasted CPU, no extra capacity.

**Tradeoff:** none — zswap is redundant when zram is the primary swap.

### 5. NetworkManager `unmanaged-lo`

File added: `etc/NetworkManager/conf.d/unmanaged-lo.conf`.

**Why:** silences a recurring boot-time warning where NM complains about the
loopback interface it shouldn't be managing.

**Tradeoff:** none.

### Verification hook

A new `check_garuda_imports()` was added to `kiro-audit` covering all 5 items
plus the systemd-oomd service state. PASS / FAIL / WARN scored alongside the
rest. `--fix` mode offered for the "service not enabled" failure case.

---

## Considered but not adopted

- **`kernel.sched_cfs_bandwidth_slice_us = 3000`** (SteamOS import) — would
  tighten the CFS bandwidth slice from 5 ms to 3 ms. Could help interactive
  feel. Skipped pending evidence it actually helps on our default kernels
  (linux-cachyos / linux-zen). Both already have aggressive scheduler defaults;
  this knob is most useful on stock `linux`.
- **Bolder ZRAM (100% of RAM)** — Garuda's choice is fine for desktops with 8+
  GiB. Our cap at `min(RAM/2, 4096)` is conservative but safe on 4 GiB
  hardware. Worth revisiting if/when 4 GiB becomes irrelevant.

---

## Rejected (we already have it, or theirs is weaker)

| Item | Reason |
|---|---|
| `kernel.sysrq=1` | Ours = 244 is REISUB-only — more secure |
| `vm.swappiness=133` | Ours = 150 is the modern Arch ZRAM number |
| `tcp_fin_timeout=5` | SteamOS-specific; ours = 20 is conservative |
| `DefaultLimitNPROC=1048576` | Ours = 30000; theirs invites fork-bomb risk for no real-app benefit |
| `journald SystemMaxUse=50M` | Ours = 100M; more headroom for triage |
| `nobeep`, `disable-evbug` | We already have both |

---

## Kernel-agnostic rule (formalised this round)

Every system tweak Kiro ships — sysctl, udev, modprobe, systemd drop-in,
tmpfile, NetworkManager conf, audit check — **must work on any kernel a Kiro
user might run.** Kiro currently ships `linux-cachyos` (default boot) +
`linux-zen` (fallback), but users freely swap to `linux-hardened`, `linux-lts`,
custom kernels.

All 5 imports above were verified against this rule:

| # | Item | Why it's kernel-agnostic |
|---|---|---|
| 1 | systemd-oomd | Userspace daemon; needs only cgroups v2 + PSI (both in every modern kernel) |
| 2 | `blacklist mei mei_me` | Module blacklist; applies whatever kernel is booted |
| 3 | `options btusb reset=1` | Module option; same |
| 4 | Disable zswap tmpfile | `/sys/module/zswap/parameters/enabled` exists in every mainline kernel since 3.11 (2013) |
| 5 | NetworkManager `unmanaged-lo` | Pure NM userspace config |

Documented in `~/EDU/edu-system-files/CLAUDE.md` under "Kernel-agnostic rule".

---

## Health pass on the live ISO (`/syscheck` subset)

Brief because a live ISO has no persistent journal (most `journalctl` reads
return `-- No entries --`):

- **Failed units:** `snapper-cleanup.service` only — expected on a live ISO
  (nothing to clean). Benign.
- **journald `Storage`** unset → effectively volatile. Live-ISO design choice.
- **`kernel.dmesg_restrict = 1`** active (matches our 99-kiro-optimizations).
- **systemd-oomd:** enabled + active, working as advertised.
- **ZRAM:** active, 9.8 GiB zstd, matches their `zram-size=ram` config (this
  VM has 10 GiB).
- **CPU governor:** unreadable in VirtualBox guest.
- **Power:** PPD active, tuned inactive.

Nothing concerning — Garuda Mokka boots clean.

---

## Cross-references

- Configs implemented: `~/EDU/edu-system-files/etc/{systemd,modprobe.d,tmpfiles.d,NetworkManager}/` (see CHANGELOG.md 2026-05-28)
- Audit check: `~/EDU/edu-system-files/usr/local/bin/kiro-audit` (`check_garuda_imports`)
- Calamares enable: `kiro-calamares-config[-next]/etc/calamares/modules/services-systemd.conf`
- SSH helper: `~/.bin/ssh-into-garuda-vb.sh`
