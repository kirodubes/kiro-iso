# KIRO VS PRISM — Config Research

**Last checked:** 2026-05-19
**Next check:** 2026-08-19 (quarterly)

**Purpose:** Inspect PrismLinux's system configuration to identify settings or
approaches that could improve Kiro's `edu-system-files`. PrismLinux is a
reference only — no changes are made to it.

**Method:** SSH into the Prism VirtualBox VM, read its `etc/` configs, compare
against `~/EDU/edu-system-files/`, and record findings here. Any improvement
goes into `edu-system-files` on Kiro.

---

## Machine Details

| Detail           | Kiro (HQ)                                    | Prism (reference)                   |
|------------------|----------------------------------------------|-------------------------------------|
| Distro           | Kiro (Arch-based)                            | PrismLinux                          |
| Kernel           | linux-lqx 7.0.9-lqx1-1-lqx                  | linux-lqx 7.0.7-lqx1-1-lqx         |
| Machine type     | Bare metal                                   | VirtualBox VM                       |
| SSH              | local                                        | `ssh-into-prism-vb.sh` host:2023→22 |
| edu-system-files | installed                                    | not installed / not our concern     |

Both run **linux-lqx** — same kernel family, different patch versions.
Sysctl and scheduler settings are directly comparable.

---

## Comparison

### Security

| Setting                            | Kiro value   | Prism value                                    | Verdict                              |
|------------------------------------|--------------|------------------------------------------------|--------------------------------------|
| `kernel.kptr_restrict`             | 2            | 2                                              | same                                 |
| `kernel.dmesg_restrict`            | 1            | 1                                              | same                                 |
| `kernel.yama.ptrace_scope`         | 1            | 1                                              | same                                 |
| `kernel.unprivileged_bpf_disabled` | 1            | 2                                              | prism stricter (2=blocks root too)   |
| `kernel.perf_event_paranoid`       | 3            | 2                                              | kiro stricter — keep 3               |
| `fs.suid_dumpable`                 | 0            | 2                                              | kiro stricter — keep 0               |
| `kernel.core_pattern`              | `/bin/false` | `\|/usr/lib/systemd/systemd-coredump ...`      | prism uses coredump, kiro disables   |
| `net.ipv4.tcp_syncookies`          | 1            | 1                                              | same                                 |
| `net.ipv6.conf.all.use_tempaddr`   | 2            | 0                                              | kiro better (privacy addresses)      |

### Speed

| Setting                           | Kiro value | Prism value | Verdict                                    |
|-----------------------------------|------------|-------------|--------------------------------------------|
| `vm.swappiness`                   | 100        | 150         | adopt 150 — standard for ZRAM-first setups |
| `vm.vfs_cache_pressure`           | 50         | 50          | same                                       |
| `vm.dirty_bytes`                  | 268435456  | 268435456   | same                                       |
| `net.ipv4.tcp_congestion_control` | bbr        | bbr         | same                                       |
| `net.core.default_qdisc`          | fq         | fq_codel    | different — fq better with BBR, keep       |
| `kernel.sched_autogroup_enabled`  | 0          | n/a         | key absent on 7.0.7-lqx                    |
| `kernel.sched_rt_runtime_us`      | 950000     | n/a         | key absent on 7.0.7-lqx                    |
| I/O scheduler (SSD/VBox disk)     | bfq        | bfq         | same                                       |

### Stability

| Setting                     | Kiro value | Prism value | Verdict                                      |
|-----------------------------|------------|-------------|----------------------------------------------|
| `kernel.panic`              | 10         | 0           | different — 10s auto-reboot better for Kiro  |
| `vm.panic_on_oom`           | 0          | 0           | same                                         |
| `vm.overcommit_memory`      | 1          | 0           | review — prism uses heuristic with ZRAM fine |
| `vm.min_free_kbytes`        | 262144     | 67584       | review — kiro reserves 4x more RAM           |
| `vm.watermark_scale_factor` | 200        | 125         | different — both tuned for ZRAM              |
| ZRAM algorithm              | zstd       | zstd        | same                                         |
| ZRAM size                   | min(RAM/2, 4GB) dynamic | 4GB fixed  | kiro more flexible               |
| Journal storage             | persistent | default (auto/volatile) | kiro better — survives crashes  |

---

## Findings

### Worth Adopting into Kiro

**`vm.swappiness = 150`** — Prism (and CachyOS, EndeavourOS) use 150 with ZRAM active.
With ZRAM as the primary swap, a higher swappiness keeps more anonymous memory
compressed in RAM rather than thrashing. Current Kiro value of 100 is conservative;
150 is the modern Arch-ZRAM standard. Low risk.

### Kiro is Stricter — Keep

- `kernel.perf_event_paranoid = 3` vs Prism's 2 — Kiro blocks perf for all non-root
- `fs.suid_dumpable = 0` vs Prism's 2 — Kiro disables SUID coredumps entirely
- `net.ipv6.conf.all.use_tempaddr = 2` vs Prism's 0 — Kiro uses IPv6 privacy addresses
- `kernel.panic = 10` vs Prism's 0 — Kiro auto-reboots on panic (better for unattended)
- Journal `Storage=persistent` vs Prism's default — Kiro logs survive reboots and crashes

### Review Further

- **`vm.overcommit_memory`**: Prism uses 0 (heuristic) with ZRAM, which works fine.
  Kiro uses 1 (always allow) because the ZRAM comment in the sysctl.d config says it
  requires it. Worth verifying if 0 is actually safe with our ZRAM config.
- **`vm.min_free_kbytes = 262144`**: Kiro reserves 256MB minimum free. Prism's kernel
  auto-set 67584 (~66MB). Our value may be over-reserved on 8GB systems.

---

## Improvements Applied to Kiro

| Setting        | Old Kiro value | New value | Source |
|----------------|----------------|-----------|--------|
| `vm.swappiness` | 100           | 150       | Prism  |
