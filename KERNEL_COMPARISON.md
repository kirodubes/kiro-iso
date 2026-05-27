# Linux Kernel Comparison — Arch stock vs. CachyOS vs. CachyOS-BORE vs. Liquorix

**Date:** 2026-05-26
**Scope:** A practical comparison of the four kernels most relevant to an
Arch-based desktop/gaming distro: the official Arch `linux` package, CachyOS's
`linux-cachyos`, the `linux-cachyos-bore` variant, and `linux-liquorix`.
**Author context:** Written for the Kiro distro, which currently ships
linux-liquorix.

---

## 1. Executive summary

All four kernels start from the same mainline Linux source. What separates them
is **what gets patched in, how it's compiled, and what it's tuned for**:

- **Arch `linux`** is the unmodified, conservatively-configured reference — the
  yardstick everything else is measured against.
- **CachyOS** kernels are the "performance maximalist" family: aggressive
  compiler optimisation (LTO + AutoFDO/Propeller), modern schedulers, and a
  large matrix of variants.
- **CachyOS-BORE** is one member of that family, tuned specifically for desktop
  interactivity and gaming feel.
- **Liquorix** is the "low-latency desktop" kernel: a single, opinionated,
  pre-tuned binary aimed at responsiveness and multimedia/gaming smoothness,
  with the easiest install story of the custom kernels.

**Overall scores (0–10):**

| Kernel               | Overall | One-line verdict                                              |
|----------------------|:-------:|--------------------------------------------------------------|
| Arch `linux`         |   8.0   | The dependable baseline; safe, official, well-supported.     |
| linux-cachyos        |   9.0   | Fastest all-rounder; best raw performance + flexibility.     |
| linux-cachyos-bore   |   8.8   | Best pure desktop/gaming responsiveness.                     |
| linux-liquorix       |   8.0   | Easiest low-latency desktop kernel; great feel, less tunable.|

> The custom kernels score higher on *performance* axes, but Arch stock remains
> the right default for anything where "boring and guaranteed to work" matters
> more than the last few percent.

---

## 2. Version snapshot (as of 2026-05-26)

| Kernel               | Current version    | Base                  | Default scheduler        |
|----------------------|--------------------|-----------------------|--------------------------|
| Arch `linux`         | 7.0.10.arch1-1     | mainline 7.0.x        | EEVDF (upstream)         |
| linux-cachyos        | ~7.0.8             | mainline 7.0.x        | BORE-EEVDF               |
| linux-cachyos-bore   | ~7.0.8             | mainline 7.0.x        | BORE                     |
| linux-liquorix       | 7.0-11 (24 May 26) | stable 7.0.10         | PDS (Project C)          |

All four are on the **Linux 7.0 series** right now, so kernel-feature parity is
high; the differences below are about configuration and patches, not version
lag. (Arch also ships `linux-lts`, `linux-zen`, and `linux-hardened` officially;
this paper focuses on the four requested.)

---

## 3. What each kernel actually is

### 3.1 Arch `linux` (stock)
The official Arch kernel, built close to Linus's tree with Arch's standard
config. Key traits:

- **Scheduler:** upstream **EEVDF** (Earliest Eligible Virtual Deadline First),
  no out-of-tree scheduler patches.
- **Tick / preemption:** 300 Hz tick, dynamic/voluntary preemption — a
  throughput-leaning default.
- **Build:** generic `x86-64` baseline, GCC, **no LTO/PGO**, so it runs on every
  supported CPU but leaves some performance on the table.
- **Distribution:** signed, in the official `core` repo, with `linux` +
  `linux-lts` fallback. This is its biggest practical advantage: it is the most
  tested kernel on Arch and the one upstream Arch guarantees.

### 3.2 linux-cachyos (default)
The flagship CachyOS kernel. A "throw the whole performance toolbox at it" build:

- **Scheduler:** **BORE-EEVDF** by default (BORE's burstiness heuristic layered
  on EEVDF), with **sched-ext (SCX)** support for swapping in BPF schedulers at
  runtime (scx_lavd, scx_rusty, etc.) without rebuilding.
- **Compiler optimisation:** **Clang Thin LTO + AutoFDO + Propeller** profiling
  — the headline differentiator. Profile-guided optimisation measurably improves
  hot-path code generation.
- **Arch tuning:** builds for `x86-64-v3`, `x86-64-v4`, and **AMD Zen4**;
  runtime-selectable preemption (full/lazy/voluntary/none); configurable tick
  (100 Hz … 1000 Hz).
- **Patches:** BBR3 TCP congestion control, AMD P-State + Preferred Core, BFQ/
  mq-deadline tuning, ZFS modules, plus gaming-hardware HID drivers (Steam Deck,
  ROG Ally, MSI Claw).

### 3.3 linux-cachyos-bore
Same CachyOS base and optimisation pipeline, but the scheduler is **pure BORE**
(Burst-Oriented Response Enhancer) rather than BORE-EEVDF. BORE rewards tasks
that yield the CPU often (interactive apps, game main threads) and penalises
CPU-hogs, which translates to a more "snappy" desktop under load. It is the
CachyOS family's recommendation for interactivity- and gaming-first desktops.

### 3.4 linux-liquorix
A long-running low-latency desktop kernel (the spiritual successor to the
Zen/liquorix lineage), shipped as **pre-compiled binaries** for Debian/Ubuntu
and Arch:

- **Scheduler:** **PDS** (from Alfred Chen's Project C), tuned for interactivity.
- **Responsiveness:** **1000 Hz** tick, **hard kernel preemption** (the most
  aggressive preemption short of full RT), Preemptible RCU.
- **I/O:** **Kyber** (multiqueue) + **BFQ** (single-queue) for responsive disk
  behaviour under load.
- **Network/VM:** **TCP BBR2**, background-reclaim hugepages, "Zen Interactive"
  block/VM/freq-scaling tuning.
- **Build:** a single opinionated config, generic build (**no LTO/PGO**, no
  per-microarch variants). Install is famously simple (one repo/curl script).

---

## 4. Scoring by dimension (0–10)

Scores are a qualitative synthesis of each kernel's design intent, the
documented feature sets, and the general pattern of public benchmarks (Phoronix
and CachyOS/OpenBenchmarking results consistently show optimised kernels leading
on throughput, and latency-tuned kernels leading on responsiveness). They are
**not** from a single controlled same-hardware run of all four — see the caveat
in §6.

| Dimension                          | Arch `linux` | cachyos | cachyos-bore | liquorix |
|------------------------------------|:------------:|:-------:|:------------:|:--------:|
| Raw throughput / compute           |      7       |    9    |      8       |    7     |
| Desktop responsiveness / latency   |      6       |    9    |     10       |    9     |
| Gaming performance / frame-time    |      6       |    9    |     10       |    8     |
| Stability / reliability            |     10       |    8    |      8       |    8     |
| Ease of install & maintenance      |     10       |    8    |      8       |    9     |
| Configurability / flexibility      |      5       |   10    |      7       |    5     |
| Modern hardware & feature support  |      8       |   10    |     10       |    7     |
| **Overall (rounded)**              |   **8.0**    | **9.0** |   **8.8**    | **8.0**  |

### Why these numbers

- **Throughput:** CachyOS leads because LTO + AutoFDO + `x86-64-v3/v4` builds
  genuinely improve hot-path performance. Arch and Liquorix use generic GCC
  builds; Liquorix also trades some throughput for latency (short timeslice,
  aggressive preemption), which is by design.
- **Responsiveness / gaming:** the BORE/PDS + 1000 Hz + aggressive-preemption
  kernels feel smoother under load. `cachyos-bore` and Liquorix are purpose-built
  for this; pure BORE edges ahead on frame-time consistency. Arch's 300 Hz,
  throughput-leaning default is the weakest here (still perfectly usable).
- **Stability:** Arch stock is the reference — most tested, signed, with an LTS
  fallback. The custom kernels track the newest mainline aggressively and carry
  out-of-tree patches, so they see slightly more churn (rare, but real).
- **Ease of maintenance:** Arch wins (official repo, signed, fallback). Liquorix
  is close behind (binary install, no compile). CachyOS needs its repo or an AUR
  build and isn't signed in Arch's chain — fine, but a deliberate step.
- **Configurability:** CachyOS is in a class of its own — a full variant matrix
  (lts, rt-bore, hardened, server, deckify, bmq, eevdf, rc) plus runtime
  sched-ext. Liquorix and Arch are "one config, take it or leave it."
- **Modern hardware:** CachyOS bundles the most gaming/handheld HID drivers,
  P-State, and BBR3. Arch is current upstream. Liquorix is solid but more
  generic and BBR2-era.

---

## 5. Picking a kernel — guidance

- **You want guaranteed-correct and official** → **Arch `linux`** (keep
  `linux-lts` installed as fallback regardless of what else you run).
- **You want the fastest all-round kernel and don't mind a repo/AUR step** →
  **linux-cachyos**.
- **You want the snappiest desktop/gaming feel above all** → **linux-cachyos-bore**
  (or Liquorix if you prefer a simpler install).
- **You want a low-latency desktop kernel with a one-command install and no
  tuning fuss** → **linux-liquorix**.

For a **distro that ships to other people** (Kiro's case), the trade-off is
between *performance reputation* (CachyOS family) and *install simplicity +
predictable behaviour* (Liquorix). Liquorix's pre-built binary and single config
make it low-maintenance for a shipped ISO; CachyOS gives more headline
performance but pulls in a repo and a larger surface to support. Either is a
defensible default; Arch stock remains the safe fallback to offer alongside.

---

## 6. Methodology & caveats

- **Versions** are accurate as of 2026-05-26; all four are rolling and will move.
- **Scores are qualitative.** No public 2026 benchmark runs all four kernels on
  identical hardware with identical configs. Real numbers depend heavily on CPU
  (Zen4 benefits most from CachyOS's `-v4`/Zen4 builds), workload, and whether
  you enable the optional knobs. Treat the table as informed guidance, not lab
  data.
- **Run your own test** if it matters: install two kernels, boot each, and
  compare with your actual workload (game frame-time graphs, `hackbench`,
  compile times). Subjective "feel" under load is exactly what BORE/PDS optimise
  and is hard to capture in a single number.

---

## 7. Sources

- [Arch Linux — `linux` package](https://archlinux.org/packages/core/x86_64/linux/)
- [Arch Linux — Kernel (ArchWiki)](https://wiki.archlinux.org/title/Kernel)
- [Arch Linux May 2026 ISO / Linux 7.0 (TechPowerUp)](https://www.techpowerup.com/348714/arch-linux-may-iso-debuts-linux-7-0-support-and-improved-installer)
- [CachyOS Kernel (wiki)](https://wiki.cachyos.org/features/kernel/)
- [CachyOS/linux-cachyos (GitHub)](https://github.com/CachyOS/linux-cachyos)
- [AUR — linux-cachyos](https://aur.archlinux.org/packages/linux-cachyos)
- [sched-ext tutorial (CachyOS wiki)](https://wiki.cachyos.org/configuration/sched-ext/)
- [Liquorix Kernel — official site](https://liquorix.net/)
- [Liquorix 7.0-11 release](https://www.linuxcompatible.org/story/liquorix-linux-kernel-7011-released/)
- [Linux 6.18 LTS vs. Liquorix on Threadripper (Phoronix)](https://www.phoronix.com/review/linux-618-liquorix)
