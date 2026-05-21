# KIRO VS CACHYOS — Config Research

**Last checked:** 2026-05-19
**Next check:** 2026-08-19 (quarterly)

**Purpose:** Inspect CachyOS's system configuration to identify settings or
approaches that could improve Kiro's `edu-system-files`. CachyOS is a
reference only — no changes are made to it.

**Method:** SSH into the CachyOS VirtualBox VM, read its `etc/` configs via
the `cachyos-settings` package, compare against `~/EDU/edu-system-files/`,
and record findings here. Any improvement goes into `edu-system-files` on Kiro.

---

## Machine Details

| Detail           | Kiro (HQ)                  | CachyOS (reference)                   |
|------------------|----------------------------|---------------------------------------|
| Distro           | Kiro (Arch-based)          | CachyOS                               |
| Kernel           | linux-lqx 7.0.9-lqx1-1-lqx | linux-cachyos 7.0.5-2-cachyos (BORE)  |
| RAM              | 32 GB                      | 10 GB (VM)                            |
| Machine type     | Bare metal                 | VirtualBox VM                         |
| SSH              | local                      | `ssh-into-cachyos-vb.sh` host:2023→22 |
| edu-system-files | installed                  | not installed / not our concern       |
| Desktop          | XFCE4 + ohmychadwm         | KDE Plasma 6.6.5                      |

Kiro uses **linux-lqx** (Liquorix), CachyOS uses **linux-cachyos** (BORE/EEVDF).
Different kernel families — scheduler tuning parameters are not directly comparable,
but sysctl, udev, and systemd settings are.

CachyOS ships all its tuning in one package: `cachyos-settings`. Key config files:
- `/usr/lib/sysctl.d/70-cachyos-settings.conf`
- `/usr/lib/udev/rules.d/60-ioschedulers.rules`, `20-audio-pm.rules`
- `/usr/lib/systemd/system.conf.d/00-timeout.conf`, `10-limits.conf`
- `/usr/lib/systemd/zram-generator.conf`

---

## Comparison

### Memory / ZRAM

| Setting                        | Kiro value                             | CachyOS value          | Verdict                                                 |
|--------------------------------|----------------------------------------|------------------------|---------------------------------------------------------|
| `vm.swappiness`                | 150                                    | 100                    | kiro more aggressive; 150 is the Arch-ZRAM standard     |
| `vm.vfs_cache_pressure`        | 50                                     | 50                     | same                                                    |
| `vm.dirty_bytes`               | 268435456 (256MB)                      | 268435456              | same                                                    |
| `vm.dirty_background_bytes`    | 67108864 (64MB)                        | 67108864               | same                                                    |
| `vm.dirty_writeback_centisecs` | 1500                                   | 1500                   | same                                                    |
| `vm.dirty_expire_centisecs`    | 1500                                   | not set                | kiro explicit                                           |
| `vm.page-cluster`              | 0                                      | 0                      | same — both optimal for ZRAM                            |
| `vm.watermark_scale_factor`    | 200                                    | not set                | kiro more aggressive reclaim trigger                    |
| `vm.min_free_kbytes`           | 262144 (256MB)                         | not set                | kiro reserves 256MB; review on 8GB systems              |
| `vm.overcommit_memory`         | 1                                      | not set                | kiro explicit (required for ZRAM)                       |
| `vm.max_map_count`             | 2147483642                             | 1048576 (arch)         | kiro much higher — needed for some dev tools/games      |
| ZRAM size                      | `min(ram / 2, 4096)` (≈15.6GB on 32GB) | `ram` (≈9.8GB on 10GB) | effectively similar — both ~RAM/2 or more; see Findings |
| ZRAM algorithm                 | zstd                                   | zstd                   | same                                                    |
| ZRAM priority                  | 100                                    | 100                    | same                                                    |

### I/O Scheduler

| Device type     | Kiro                                                     | CachyOS       | Verdict                                              |
|-----------------|----------------------------------------------------------|---------------|------------------------------------------------------|
| NVMe            | `none`                                                   | `kyber`       | different — `none` has less overhead; kyber adds QoS |
| SSD (sd/mmcblk) | `bfq` (live) → `mq-deadline` (fixed in edu-system-files) | `mq-deadline` | fix pending deployment                               |
| HDD             | `mq-deadline` (live) → `bfq` (fixed in edu-system-files) | `bfq`         | fix pending deployment                               |
| Virtual (vd)    | `none`                                                   | not set       | kiro explicit                                        |
| USB             | `mq-deadline`                                            | not set       | kiro explicit                                        |

### Networking

| Setting                           | Kiro value | CachyOS value           | Verdict                                  |
|-----------------------------------|------------|-------------------------|------------------------------------------|
| `net.ipv4.tcp_congestion_control` | bbr        | cubic (default)         | kiro better for desktop/WiFi             |
| `net.core.default_qdisc`          | fq         | fq_codel (arch default) | kiro better with BBR                     |
| `net.core.netdev_max_backlog`     | 5000       | 4096                    | kiro slightly higher                     |
| `net.ipv4.tcp_fastopen`           | 3          | not set                 | kiro enables (client + server)           |
| `net.ipv6.conf.all.use_tempaddr`  | 2          | not set (0)             | kiro better (IPv6 privacy addresses)     |
| `net.ipv4.tcp_keepalive_time`     | 600        | 120 (arch default)      | different — arch 120s is more aggressive |

### Security

| Setting                            | Kiro value   | CachyOS value       | Verdict                               |
|------------------------------------|--------------|---------------------|---------------------------------------|
| `kernel.sysrq`                     | 244          | 16 (arch default)   | kiro: REISUB only; cachyos: SYNC only |
| `kernel.kptr_restrict`             | 2            | 2                   | same                                  |
| `kernel.dmesg_restrict`            | 1            | not set (0)         | kiro stricter                         |
| `kernel.yama.ptrace_scope`         | 1            | not set (0)         | kiro stricter                         |
| `kernel.unprivileged_bpf_disabled` | 1            | not set             | kiro stricter                         |
| `kernel.perf_event_paranoid`       | 3            | not set (2 default) | kiro stricter                         |
| `fs.suid_dumpable`                 | 0            | not set (0 default) | same in practice                      |
| `kernel.core_pattern`              | `/bin/false` | not set (systemd)   | kiro disables coredumps entirely      |
| `kernel.unprivileged_userns_clone` | 1            | 1                   | same                                  |
| `kernel.nmi_watchdog`              | 0            | 0                   | same                                  |
| `kernel.printk`                    | 3 3 3 3      | 3 3 3 3             | same                                  |

### Scheduler / CPU

| Setting                          | Kiro value                 | CachyOS value | Verdict                                |
|----------------------------------|----------------------------|---------------|----------------------------------------|
| `kernel.sched_autogroup_enabled` | not supported (lqx kernel) | not set (1)   | lqx kernel does not expose this sysctl |
| `kernel.sched_rt_runtime_us`     | not supported (lqx kernel) | not set       | lqx kernel does not expose this sysctl |
| `kernel.panic`                   | 10                         | not set (0)   | kiro auto-reboots on panic             |

### Systemd

| Setting                  | Kiro value          | CachyOS value  | Verdict                                          |
|--------------------------|---------------------|----------------|--------------------------------------------------|
| `DefaultTimeoutStartSec` | 30s                 | 15s            | cachyos more aggressive — may kill slow services |
| `DefaultTimeoutStopSec`  | 15s                 | 10s            | cachyos more aggressive                          |
| `DefaultLimitNOFILE`     | 1048576 (soft/hard) | 2048:2097152   | different split; kiro is simpler                 |
| Journal `Storage`        | persistent          | not set (auto) | kiro better — logs survive crashes               |
| Journal `SystemMaxUse`   | 100M                | 50M            | kiro keeps more logs                             |

### Audio

| Item                          | Kiro                         | CachyOS                             | Verdict                                          |
|-------------------------------|------------------------------|-------------------------------------|--------------------------------------------------|
| Audio stack                   | PipeWire + PulseAudio compat | PipeWire + PulseAudio compat        | same                                             |
| `@audio - rtprio`             | 99 (`99-kiro.conf`)          | 99 (`20-audio.conf`)                | same                                             |
| snd_hda_intel power save (AC) | not set                      | disabled on AC, enabled on battery  | cachyos better — prevents audio cracks           |
| Audio PM udev rule            | `68-sound-power.rules`       | `20-audio-pm.rules` (battery-aware) | cachyos rule is more sophisticated; see Findings |

### Notable CachyOS Services/Tools

| Package / Service        | CachyOS | Kiro | Notes                                                              |
|--------------------------|---------|------|--------------------------------------------------------------------|
| `ananicy-cpp`            | active  | no   | Auto-adjusts process nice/ionice — improves desktop responsiveness |
| `preload`                | active  | no   | Adaptive readahead — marginal benefit on SSD/NVMe                  |
| `power-profiles-daemon`  | enabled | no   | Power profiles (balanced/performance/power-saver)                  |
| `chwd`                   | yes     | no   | Hardware detection (like mhwd from Manjaro)                        |
| `cachyos-kernel-manager` | yes     | no   | GUI kernel switcher                                                |
| `ananicy-cpp`            | yes     | no   | Worth evaluating for Kiro                                          |

---

## Findings

### IO Scheduler Assignment is Reversed

CachyOS assigns:
- **SSD** → `mq-deadline` (correct: low-overhead, deadline-aware, tuned for flash)
- **HDD** → `bfq` (correct: seek-optimised, fair queuing for rotational)

Kiro currently assigns the **opposite**: SSD→`bfq`, HDD→`mq-deadline`.

`bfq` on SSDs adds unnecessary CPU overhead for seek optimisation that SSDs don't need.
`mq-deadline` on HDDs skips the fair-queuing that prevents starvation on rotational media.
**CachyOS has it right.** The Kiro rules in `60-io-scheduler.rules` need to be corrected.

### ZRAM Config Bug: `4096M` Suffix Not Valid

Kiro's zram-generator.conf had `zram-size = min(ram / 2, 4096M)`. The `M` suffix is not
valid in zram-generator expressions (documented default is `min(ram / 2, 4096)` with the
constant in MiB). With `4096M`, the cap is parsed as a very large number and the min()
always returns `ram / 2`. On Kiro HQ (32GB RAM) this produces 15.6GB ZRAM — unintended.

**Fixed in edu-system-files:** changed to `min(ram / 2, 4096)` — correct 4GB cap.
Deploy with the next edu-system-files package rebuild.

CachyOS uses `zram-size = ram` (full RAM = ~9.8GB on a 10GB VM), which is more aggressive
but valid since ZRAM compresses data and never uses its full nominal size in physical RAM.

### snd_hda_intel Battery-Aware Power Management

CachyOS's `20-audio-pm.rules` is sophisticated: it disables Intel HDA power-saving on AC
power (prevents audio cracks/pops) and re-enables it when on battery. Our `68-sound-power.rules`
does not implement this AC/battery distinction. Should be adopted for laptop users.

### `ananicy-cpp` — Process Priority Management

CachyOS ships and enables `ananicy-cpp`, which reads rules from `/etc/ananicy.d/` and
automatically adjusts `nice`, `ionice`, and scheduling policy for known processes
(browsers, audio daemons, build tools). This improves perceived desktop responsiveness
without touching sysctl. Low risk, significant upside for interactive workloads.
Worth adding to Kiro's package list.

### Kiro Security Posture is Strictly Better

CachyOS ships almost no security hardening beyond the Arch defaults. Kiro adds:
`dmesg_restrict`, `ptrace_scope`, `unprivileged_bpf_disabled`, `perf_event_paranoid=3`,
`core_pattern=/bin/false`, `suid_dumpable=0`, IPv6 privacy addresses, BBR+fq networking.
None of these need changing — document them as intentional Kiro hardening.

---

## Improvements to Apply to Kiro

| Item                    | Current Kiro      | Change to             | Source  |
|-------------------------|-------------------|-----------------------|---------|
| IO scheduler: SSD       | bfq               | mq-deadline           | CachyOS |
| IO scheduler: HDD       | mq-deadline       | bfq                   | CachyOS |
| snd_hda_intel udev rule | static off        | battery-aware AC/DC   | CachyOS |
| ZRAM size (evaluate)    | min(ram/2, 4096M) | `ram` (test on metal) | CachyOS |
| `ananicy-cpp` package   | not included      | add to package list   | CachyOS |
