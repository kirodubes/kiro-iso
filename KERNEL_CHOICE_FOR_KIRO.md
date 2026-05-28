# Kernel Choice for Kiro

**Date:** 2026-05-28
**Question asked:** "I want a stable, fast, secure kernel — which one and why?"
**Clarification:** "fast" = desktop responsiveness, not raw throughput.
**Shipped verdict:** **dual-kernel — `linux-cachyos` (live + post-install default) + `linux-zen` (secondary, also installed)**

The ISO ships **both** kernels installed. `linux-cachyos` is the kernel the
live ISO boots and the one selected as default after install; `linux-zen` is
the secondary boot-menu choice — present as a safety net if cachyos misbehaves
on a given user's hardware.

Configured in [build-scripts/build-the-iso.sh](build-scripts/build-the-iso.sh)
line 101:

```bash
kernel="linux-cachyos linux-zen"   # First = the kernel the live ISO boots.
```

This document records the recommendation and the reasoning, sourced from the
existing in-repo analysis:

- [KERNEL_COMPARISON.md](KERNEL_COMPARISON.md) — Arch vs CachyOS vs BORE vs Liquorix
- [ARCH-KERNELS-BUILD-CONFIG-SCORECARD.md](ARCH-KERNELS-BUILD-CONFIG-SCORECARD.md) — 8-kernel PKGBUILD + config scorecard
- [comparison-usage-kernels.md](comparison-usage-kernels.md) — what other Arch-based distros ship

---

## TL;DR — why dual-kernel

No single kernel scores top on *all* of stable, responsive, and secure.
Shipping two complementary kernels covers the trade-off:

| Role         | Kernel           | Strength                                       | Trade-off                          |
|--------------|------------------|------------------------------------------------|------------------------------------|
| **Primary**  | `linux-cachyos`  | Speed 10, Resp 9, HW 9 — the most aggressive  | Stability 6 (newest patches, more churn) |
| **Secondary**| `linux-zen`      | Stability 8, Security 8, Resp 8 — balanced    | Resp 8 vs cachyos's 9              |

If cachyos misbehaves on a user's hardware (rare, but real for any
performance-optimized kernel), rebooting into zen from the grub menu gives a
safer baseline with almost the same desktop snappiness. Users effectively get
**Speed 10 by default, Stability 8 on demand**.

| Kernel                  | Stable | Responsive | Secure |
|-------------------------|:------:|:----------:|:------:|
| **linux-cachyos** *(primary)* |   6    |   **9**    |   7    |
| **linux-zen** *(secondary)*   | **8**  |     8      | **8**  |
| linux                   |   9    |     7      |   8    |
| linux-cachyos-bore      |   7    |     9      |   7    |
| linux-lqx *(previous)*  |   5    |     9      | **3**  |
| linux-lts               |  10    |     5      |   8    |
| linux-hardened          |   7    |     6      |  10    |

Scores from [ARCH-KERNELS-BUILD-CONFIG-SCORECARD.md](ARCH-KERNELS-BUILD-CONFIG-SCORECARD.md).

---

## Full six-axis scorecard — shipped kernels first

The two shipped kernels at the top, then the rest of the field for context.

| Kernel                 | Speed  | Stability | Security | Responsiveness | Power | HW/Features | Role in Kiro                              |
|------------------------|:------:|:---------:|:--------:|:--------------:|:-----:|:-----------:|-------------------------------------------|
| **linux-cachyos** ✓    | **10** |     6     |    7     |       9        |   5   |      9      | **Primary — live + post-install default** |
| **linux-zen** ✓        |   7    |     8     |    8     |       8        |   6   |      6      | **Secondary — grub fallback**             |
| linux-cachyos-bore     |   8    |     7     |    7     |       9        |   5   |      9      | Considered; cachyos chosen instead        |
| linux-lqx *(previous)* |   8    |     5     |  **3**   |       9        |   5   |      9      | Dropped — 3/10 security disqualifying     |
| linux                  |   6    |     9     |    8     |       7        |   6   |      6      | Stock baseline; zen captures this + more  |
| linux-xanmod           |   8    |     7     |    7     |       7        | **8** |      8      | Not chosen — no axis beats this pair      |
| linux-hardened         |   4    |     7     |  **10**  |       6        |   6   |      5      | Considered for security; speed too low    |
| linux-lts              |   5    |   **10**  |    8     |       5        |   7   |      5      | Not shipped — desktop philosophy wrong    |

### cachyos + zen together — coverage map

What this dual-kernel choice covers, vs what any *single* kernel would:

| Axis             | Best single-kernel pick | Kiro's pair  | Coverage |
|------------------|-------------------------|--------------|----------|
| Speed            | cachyos (10)            | cachyos = 10 | full     |
| Responsiveness   | cachyos/lqx (9)         | cachyos = 9  | full     |
| HW/Features      | cachyos/lqx (9)         | cachyos = 9  | full     |
| Stability *(boot fallback)* | lts (10)     | zen = 8 from grub | 80% — within one reboot |
| Security *(boot fallback)*  | hardened (10)| zen = 8 from grub | 80% — within one reboot |

User experience: max performance by default, near-baseline stability and
security a grub-menu pick away. No need to ship `linux-lts` separately as a
third safety kernel — zen covers both the "feel" and "safety" roles.

---

## Why `linux-cachyos` as the primary

The original analysis flagged three concerns with cachyos for a shipped ISO.
The dual-kernel approach + cachyos's own design address all three:

1. **Native-CPU non-portability** — the CachyOS upstream repo (`cachyos-v3`,
   `cachyos-v4`, `cachyos-znver4`) ships pre-built per-µarch packages. Kiro
   pulls from Chaotic-AUR's `linux-cachyos` which is already built `generic`
   for portability. No `_processor_opt` pin needed.
2. **Extra repo to maintain** — Chaotic-AUR is already in Kiro for `linux-lqx`,
   `chaotic-keyring`, and others. cachyos is a zero-additional-repo cost.
3. **Stability 6/10** — mitigated by shipping `linux-zen` alongside. Any
   cachyos regression that affects boot or graphics is one grub-menu pick
   away from a stable kernel.

### What you actually get with cachyos as the default

- **BORE scheduler** — burst-oriented response enhancer; rewards interactive
  tasks (game main threads, UI), penalises CPU-hogs. Better frame-time
  consistency than EEVDF or PDS.
- **Clang + ThinLTO + AutoFDO/Propeller** — profile-guided optimisation
  measurably improves hot-path code generation. The Speed 10 lives here.
- **1000 Hz tick, full preemption, full tickless** — same desktop-latency
  knobs zen ships, applied on top of BORE.
- **BBR3 TCP, AMD P-State + Preferred Core, ADIOS I/O scheduler** — modern
  network/storage tuning out of the box.
- **Built-in waydroid/anbox (`ANDROID_BINDER_IPC`)** — no extra kernel
  module needed if a user wants Android compatibility later.

### linux-cachyos vs linux-cachyos-bore — why cachyos, not bore

Within the cachyos family, two variants exist. Kiro ships `linux-cachyos`
(the Clang/ThinLTO build) rather than `linux-cachyos-bore` (the GCC build).
Both run the BORE scheduler with identical tick/preempt/hardening/drivers;
they diverge only on toolchain.

#### Build differences

| Attribute            | linux-cachyos                       | linux-cachyos-bore         |
|----------------------|-------------------------------------|----------------------------|
| **Compiler**         | Clang / LLVM                        | GCC                        |
| **LTO**              | ThinLTO                             | none                       |
| **Scheduler**        | BORE (via `_cpusched=cachyos`)      | BORE (via `_cpusched=bore`)|
| **Scheduler source** | CachyOS "sauce" + BORE              | Plain BORE                 |
| **CPU target**       | native (build host)                 | native (build host)        |
| **Tick rate**        | 1000 Hz                             | 1000 Hz                    |
| **Preemption**       | Full                                | Full                       |
| **Tickless**         | Full (`NO_HZ_FULL`)                 | Full (`NO_HZ_FULL`)        |
| **Optimization**     | O3                                  | O3                         |
| **CACHY config**     | y                                   | y                          |
| **Package suffix**   | `linux-cachyos`                     | `linux-cachyos-bore`       |

Per the in-repo scorecard:
*"linux-cachyos = the Clang/ThinLTO build, linux-cachyos-bore = the plain
GCC build — same scheduler, different toolchain."*

#### Score deltas

| Axis           | linux-cachyos | linux-cachyos-bore | Δ  | Why                                                  |
|----------------|:-------------:|:------------------:|:--:|------------------------------------------------------|
| Speed          |    **10**     |         8          | -2 | bore loses Clang+ThinLTO's PGO-style wins            |
| Stability      |       6       |       **7**        | +1 | GCC build is more conservative; less novel toolchain |
| Security       |       7       |         7          |  0 | identical hardening posture                          |
| Responsiveness |       9       |         9          |  0 | same scheduler + tick + preempt                      |
| Power          |       5       |         5          |  0 | same perf-leaning defaults                           |
| HW/Features    |       9       |         9          |  0 | identical driver/feature surface                     |

Only **Speed** and **Stability** differ — they trade against each other.
Because zen already covers the "stable fallback" role, Kiro takes the +2
Speed of full cachyos rather than the +1 Stability of bore. The
stability-by-fallback comes from zen, not from picking a lesser cachyos.

---

## Why `linux-zen` as the secondary

### Stability (8/10)
- Config is **byte-identical to stock `linux`** except 8 keys (per the
  scorecard's baseline diff). Stock-level reliability inherited.
- Lives in the **official Arch `extra` repo** — signed, with `linux-lts`
  available as further fallback.
- No out-of-tree scheduler swap, no de-hardening, no Debian-derived config
  layer. Just stock + the zen patchset.

### Responsiveness (8/10)
The zen kernel ships every desktop-latency knob the "feel" kernels rely on:

- **1000 Hz** tick (same as cachyos)
- **Full dynamic preemption** (same as cachyos)
- **`ZEN_INTERACTIVE=y`** — the zen patchset's desktop-interactivity tunable
- **O3** build

The gap from zen (8) → cachyos (9) is scheduler personality (EEVDF+zen vs
BORE). Real, but subtle — and the user gets cachyos by default, with zen as
a near-equally-snappy fallback. Best of both.

### Security (8/10)
Inherits the **full Arch hardening baseline**:

- KASLR on
- FORTIFY_SOURCE on
- lockdown LSM on
- SLAB freelist hardened
- Module signing intact
- landlock + integrity LSMs present

This is why **zen** is the secondary, not lqx (which scores 3/10) or bore
(7/10) — zen brings the highest-security fallback among the responsiveness
kernels.

---

## Why not the other candidates?

| Kernel | Why not for Kiro's primary or secondary slot |
|--------|----------------------------------------------|
| `linux` | Safe (Stability 9 / Security 8) but only 7/10 responsive. Zen captures the same security + 1 more point of responsiveness. |
| `linux-lqx` *(previous)* | 3/10 security — KASLR/FORTIFY/lockdown/module-sig all off. Disqualifying for a distro that installs on strangers' hardware. |
| `linux-cachyos-bore` | Same scheduler as cachyos but GCC/no-LTO. Trades 2 Speed for 1 Stability — and we already have stability covered by zen. Pick the higher-Speed sibling. |
| `linux-lts` | 5/10 responsive (300 Hz + voluntary preempt) — wrong philosophy for a desktop distro. Could be a *third* fallback but zen at 8/8/8 already covers it. |
| `linux-hardened` | 6/10 responsive, 4/10 speed — hardening overhead disqualifies it as a daily-driver default. Available from official repo if a user installs it post-install. |
| `linux-xanmod` | Solid laptop kernel (8/10 power) but no axis where it strictly beats either cachyos or zen for our criteria. |

---

## When this answer would change

- **If maximum stability/security were primary** (server-leaning install) →
  swap primary to `linux` or `linux-lts`, keep zen as fallback.
- **If avoiding the Clang/ThinLTO toolchain became important** (regression
  appears in cachyos that bore doesn't share) → swap primary from
  `linux-cachyos` to `linux-cachyos-bore`. Single-line change at
  build-the-iso.sh:101.
- **If Chaotic-AUR became unreliable** → fall back to `linux-zen` as
  primary (it's in Arch `extra`, always available).

For Kiro's current desktop-distro-with-safety-net model, the
`linux-cachyos linux-zen` pair is the right pick.

---

## What was shipped

Implementation lives in [build-scripts/build-the-iso.sh](build-scripts/build-the-iso.sh):

- **Line 101** — `kernel="linux-cachyos linux-zen"`. Single source of truth.
- **Lines 514+** — `apply_kernel()`. Reads the `kernel=` variable, rewrites
  `packages.x86_64`, the live mkinitcpio presets, and every bootloader entry
  (`efiboot`, `grub.cfg`, `loopback.cfg`, `syslinux`) at build time.
- **Line 370** — `CANONICAL_KERNEL="linux-lqx"`. Left untouched — this is
  the source *token* the sed-templating substitutes FROM, matching the
  literal paths still in the archiso tree. Not the shipped kernel.
- **Calamares** — needs no change. The `kiro_kernel` module is already
  kernel-agnostic.
- **Logged in** [TODO.md](TODO.md) Done section, 2026-05-28.

---

## Who else ships these kernels as default? (web survey, 2026-05-28)

A web survey of all 26 Arch-based distros on Kiro's supported-distros list,
plus a widened net to non-Arch distros, was done to position Kiro's choice
against the field.

### Kernel defaults across Kiro's 26 supported Arch-based distros

| Distro              | Default kernel        | Source                          |
|---------------------|-----------------------|---------------------------------|
| Arch                | `linux`               | ArchWiki                        |
| ArchBang            | `linux`               | comparison-usage-kernels.md     |
| Archcraft           | `linux`               | in-repo doc                     |
| Archman             | `linux` (7.0.10)      | DistroWatch package table       |
| Artix               | `linux`               | systemd-free init               |
| BigLinux            | `linux` (7.0.3)       | DistroWatch package table       |
| BlendOS             | `linux`               | in-repo doc                     |
| Bluestar            | `linux`               | in-repo doc                     |
| **CachyOS**         | **`linux-cachyos`**   | CachyOS wiki (custom in-house)  |
| Calam-arch          | `linux` (7.0.3)       | DistroWatch                     |
| Crystal Linux       | `linux`               | in-repo doc                     |
| EndeavourOS         | `linux`               | in-repo doc                     |
| **Garuda**          | **`linux-zen`**       | Wikipedia + Garuda forum        |
| Liya                | `linux` (~6.11)       | Notebookcheck release note      |
| Mabox               | **`linux-lts`**       | Mabox 26.01 release notes       |
| Manjaro             | own `linux` (7.0)     | Manjaro 26.1 notes              |
| Nyarch              | `linux` (7.0.10)      | DistroWatch package table       |
| ParchLinux          | `linux`               | in-repo doc                     |
| **PrismLinux**      | **`linux-lqx`**       | FOSS Force review + Notebookcheck |
| RebornOS            | `linux`               | RebornOS wiki                   |
| Axyl                | unknown (likely `linux`) | Original discontinued; community fork |
| BerserkerArch       | unknown (likely `linux`) | Site says "Powered by Arch", no kernel claim |
| LinuxHub Prime      | unknown               | No public DistroWatch entry     |
| Omarchy (DHH)       | unknown (inherits Arch's `linux`) | "Dotfiles in a trench coat" — no kernel swap |
| StormOS             | installer choice (lts/hardened/zen) | Net-installer offers all three |

### Tally across 26 distros

- **`linux-cachyos` as default: 1** — CachyOS itself (the eponymous distro).
- **`linux-zen` as default: 1** — Garuda. *(Athena OS too, but not on Kiro's list.)*
- **`linux-lqx` as default: 1** — PrismLinux *(same as Kiro's previous kernel)*.
- **LTS as default: 1** — Mabox.
- **Standard `linux`: ~17** — the overwhelming majority.
- **Dual-kernel (performance + safety) as default: 0** — **Kiro is alone here.**

### Where Kiro now sits

No other Arch distro on the list ships **both** `linux-cachyos` and
`linux-zen` by default. The closest equivalents:

- **CachyOS** ships its own `linux-cachyos` (same primary) but no zen
  fallback.
- **Garuda** ships `linux-zen` (same secondary) but no cachyos primary.

Kiro's positioning becomes:

> *"CachyOS's performance kernel as the default, with Garuda's zen kernel as
> the one-reboot safety net — XFCE4 + ohmychadwm on top, with an Arch-baseline
> security posture preserved in the fallback."*

That's a genuinely unique position in the Arch field — not a clone of either
project, and not a "we ship stock `linux` like everyone else" default.

### Widened net — where can you even *get* these kernels natively?

`linux-cachyos` is essentially CachyOS-repo-only (+ Chaotic-AUR mirror).

`linux-zen` per [Repology](https://repology.org/project/linux-zen/versions):

| Repository           | linux-zen version  |
|----------------------|--------------------|
| Arch Linux `extra`   | 7.0.10.zen1        |
| AUR                  | 7.0.10.zen1        |
| Artix `galaxy`       | 7.0.8.zen1         |
| Gentoo               | 7.0.9              |
| LiGurOS stable       | 6.13.8             |
| LiGurOS develop      | 7.0.6              |
| nixpkgs 24.11        | 6.15.2             |
| nixpkgs 25.05        | 6.18.2             |
| nixpkgs 25.11        | 7.0.9              |
| nixpkgs unstable     | 7.0.10             |

Zen is essentially an **Arch-family + source-distro** kernel.
Debian/Ubuntu/Fedora/openSUSE don't package it; their users go to
**Liquorix** (`linux-lqx`) for the equivalent latency-tuned kernel —
liquorix is the Debian/Ubuntu cousin of zen.

---

## Sources

In-repo analyses:

- [KERNEL_COMPARISON.md](KERNEL_COMPARISON.md)
- [ARCH-KERNELS-BUILD-CONFIG-SCORECARD.md](ARCH-KERNELS-BUILD-CONFIG-SCORECARD.md)
- [comparison-usage-kernels.md](comparison-usage-kernels.md)
- [LIQUORIX.md](LIQUORIX.md)
- [TODO.md](TODO.md) — Done entry 2026-05-28

External (web survey 2026-05-28):

- [Repology — linux-zen versions](https://repology.org/project/linux-zen/versions)
- [Arch Linux — linux-zen package](https://archlinux.org/packages/extra/x86_64/linux-zen/)
- [Garuda Linux — Wikipedia](https://en.wikipedia.org/wiki/Garuda_Linux)
- [Garuda Forum — "Change default kernel to LTS not ZEN"](https://forum.garudalinux.org/t/change-default-kernel-to-lts-not-zen/42124)
- [Athena OS Wiki — 2.1 Kernel](https://github.com/Athena-OS/athena/wiki/2.1-Kernel)
- [CachyOS Wiki — Kernel](https://wiki.cachyos.org/features/kernel/)
- [PrismLinux — FOSS Force review](https://fossforce.com/2026/03/prismlinux-a-no-drama-sane-approach-to-arch-based-linux/)
- [PrismLinux 2026.05.05 release — Notebookcheck](https://www.notebookcheck.net/PrismLinux-2026-05-05-sports-a-redesigned-installer-the-Linux-kernel-7-0-more.1292456.0.html)
- [Mabox 26.01 (LTS kernel)](https://maboxlinux.org/mabox-26-01-latest-6-18-lts-kernel/)
- [BigLinux — DistroWatch](https://distrowatch.com/table.php?distribution=biglinux)
- [Nyarch — DistroWatch](https://distrowatch.com/table.php?distribution=nyarch)
- [Archman — DistroWatch](https://distrowatch.com/archman)
- [Calam Arch — DistroWatch](https://distrowatch.com/calam)
- [Liya 2.1 — Notebookcheck](https://www.notebookcheck.net/Arch-Linux-based-Liya-2-1-rolls-out-with-the-6-11-0-1-kernel.893752.0.html)
- [RebornOS Wiki — Kernel Comparison](https://wiki.rebornos.org/en/customization/kernelcomparison)
- [Liquorix Kernel — the Debian/Ubuntu cousin of zen](https://liquorix.net/)
- [zen-kernel — GitHub](https://github.com/zen-kernel/zen-kernel)
