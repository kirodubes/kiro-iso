# Kernel Build-File Comparison

Comparison of the **PKGBUILD build recipes** for 8 Arch kernels, cloned 2026-05-27.
This compares *how each is packaged and configured*, not the kernel C source.

Repos live beside this file:
- `linux/`, `linux-zen/`, `linux-hardened/`, `linux-lts/` — Arch official (GitLab)
- `linux-xanmod/`, `linux-lqx/` — AUR
- `linux-cachyos/` — GitHub (holds `linux-cachyos/` and `linux-cachyos-bore/` + 8 more flavors)

---

## Snapshot versions (at clone time)

| Kernel             | pkgver              | Series                                |
|--------------------|---------------------|---------------------------------------|
| linux              | 7.0.10.arch1        | mainline 7.0                          |
| linux-zen          | 7.0.10.zen1         | mainline 7.0 + zen                    |
| linux-hardened     | 7.0.9.**hardened1** | mainline 7.0 (lags one point release) |
| linux-lts          | **6.18.33**         | LTS 6.18                              |
| linux-xanmod       | 7.0.10-xanmod1      | mainline 7.0 + xanmod                 |
| linux-lqx          | 7.0.10.lqx1         | mainline 7.0 + liquorix               |
| linux-cachyos      | 7.0.10              | mainline 7.0 + cachy sauce            |
| linux-cachyos-bore | 7.0.10              | mainline 7.0 + cachy sauce            |

---

## The one-line character of each

| Kernel                 | In a sentence                                                                                                                         |
|------------------------|---------------------------------------------------------------------------------------------------------------------------------------|
| **linux**              | Vanilla mainline + a tiny Arch patch. The neutral reference. GCC, generic CPU, builds htmldocs, Rust on.                              |
| **linux-zen**          | Stock recipe + the zen-kernel patch for desktop responsiveness. Almost byte-identical PKGBUILD to `linux`.                            |
| **linux-hardened**     | Stock recipe + anthraxx security-hardening patch. Rust install disabled; adds `usbctl` (deny_new_usb) optdep.                         |
| **linux-lts**          | LTS 6.18 base + 3 small local patches (userns sysctl + 2 amdgpu fixes). Huge SPDX license list. Stability over features.              |
| **linux-xanmod**       | Vanilla + XanMod patch (SourceForge). Build-time env knobs (µarch, NUMA, tracers, GCC/Clang). Enables Android binder, provides NTFS3. |
| **linux-lqx**          | Vanilla + Liquorix patch series (zen+lqx). **Project-C PDS scheduler** default. DWARF5, landlock LSM for pacman sandbox.              |
| **linux-cachyos**      | Pre-patched CachyOS source + cachy patches. **Clang + thin-LTO** default, BORE sched, native CPU, 1000 Hz, full tickless/preempt.     |
| **linux-cachyos-bore** | Same framework, but **GCC, no LTO**, BORE scheduler. The non-LTO sibling of linux-cachyos.                                            |

---

## Axis-by-axis comparison

### 1. Where the patches come from (build model)
- **linux / zen / hardened / xanmod / lqx**: download the **vanilla kernel.org tarball**, then apply patch(es) at build time.
  - linux → Arch's own `linux-<tag>.patch.zst` (minimal)
  - zen → `zen-kernel` release patch
  - hardened → `anthraxx/linux-hardened` patch
  - xanmod → XanMod patch from SourceForge
  - lqx → `damentz/liquorix-package` tarball, applies its `zen/` + `lqx/` patch series
- **cachyos / cachyos-bore**: download a **pre-baked CachyOS source tarball** (`CachyOS/linux` releases), then layer scheduler-specific patches from `cachyos/kernel-patches`.

### 2. Config strategy
- **Arch (linux/zen/hardened)**: one static `config.x86_64` → `make olddefconfig`. **Zero build-time options.**
- **linux-lts**: static `config` + olddefconfig.
- **xanmod**: XanMod `CONFIGS/` base + env-var toggles; re-Arch-ifies TOMOYO paths.
- **lqx**: Debian `config-arch-64` base; forces scheduler, DWARF5, landlock; Arch-ifies TOMOYO.
- **cachyos**: `config` base **rewritten by dozens of `scripts/config` calls** driven by `: "${_var:=default}"` options — effectively a config compiler.

### 3. CPU scheduler (the headline difference)
| Kernel                           | Default scheduler                           |
|----------------------------------|---------------------------------------------|
| linux, linux-lts, linux-hardened | Stock **EEVDF** (no sched patch)            |
| linux-zen                        | EEVDF + zen tweaks                          |
| linux-xanmod                     | EEVDF + xanmod tuning                       |
| linux-lqx                        | **Project-C PDS** (switchable to BMQ / CFS) |
| linux-cachyos                    | **BORE** (CachyOS "sauce", thin-LTO build)  |
| linux-cachyos-bore               | **BORE** (GCC build)                        |

### 4. Compiler & LTO
- **GCC, no LTO**: linux, zen, hardened, lts, lqx, **cachyos-bore**.
- **GCC default, optional Clang+thinLTO**: xanmod (`_compiler=clang`).
- **Clang + thin-LTO by default**: **linux-cachyos**.

### 5. CPU micro-arch optimization
- **Generic x86-64** (portable): all Arch kernels, lqx.
- **User-selectable, generic default**: xanmod (`choose-gcc-optimization.sh`).
- **NATIVE by default** (optimizes for the building machine): **cachyos / cachyos-bore** — fastest locally, NOT portable to other CPUs unless you set `_processor_opt=generic`.

### 6. Latency / desktop tuning defaults
- **linux / lts / hardened**: general-purpose mainline defaults.
- **zen / xanmod / lqx**: desktop-tuned via their patchsets (higher HZ, preemption).
- **cachyos**: explicit & aggressive — 1000 Hz, full tickless (`NO_HZ_FULL`), full preempt, THP `always`, optional BBR3 TCP + performance governor.

### 7. Build-time flexibility (number of user knobs)
`linux ≈ zen ≈ hardened ≈ lts` (none) **<** `lqx` (scheduler + menuconfig) **<** `xanmod` (µarch/NUMA/tracers/compiler) **<<** **`cachyos` (30+ options)**.

### 8. Notable extras
- **hardened**: `usbctl` deny_new_usb; Rust deliberately off.
- **lts**: explicit per-package SPDX license arrays; ships license files.
- **xanmod**: `ANDROID_BINDERFS`/`BINDER_IPC` on (waydroid/anbox); provides NTFS3-MODULE.
- **lqx**: adds `landlock` to `CONFIG_LSM` for **pacman sandbox** support; DWARF5 debug info.
- **cachyos**: AutoFDO + Propeller PGO workflow, optional kCFI, built-in ZFS, `nvidia-open` & `r8125` subpackages, module signing, QR-code panic screen on GCC builds.

### 9. PKGBUILD size / complexity
| Kernel                 | ~Lines   | Shape                          |
|------------------------|----------|--------------------------------|
| linux / zen / hardened | ~280–290 | near-identical boilerplate     |
| linux-lts              | ~395     | boilerplate + license lists    |
| linux-lqx              | ~395     | + scheduler/config logic       |
| linux-xanmod           | ~400     | + env-var build options        |
| linux-cachyos(-bore)   | ~750–820 | a configurable build framework |

---

## linux-cachyos vs linux-cachyos-bore — the precise difference

Both enable the **BORE** scheduler and the CachyOS config (`CACHY=y`), native CPU, 1000 Hz, full tickless/preempt, O3. The *only* meaningful divergence in defaults:

| Option          | linux-cachyos            | linux-cachyos-bore |
|-----------------|--------------------------|--------------------|
| `_use_llvm_lto` | `thin` (Clang + ThinLTO) | `none`             |
| Compiler        | Clang/LLVM               | GCC                |
| `_cpusched`     | `cachyos` (→ BORE)       | `bore` (→ BORE)    |
| Package suffix  | `cachyos`                | `cachyos-bore`     |

So: **linux-cachyos = the Clang/ThinLTO build, linux-cachyos-bore = the plain GCC build** — same scheduler, different toolchain.

---

## Takeaways for distro packaging

- For a **stock, predictable, reproducible** kernel: `linux` / `linux-lts` (generic CPU, no native, no LTO) are the safe shippable choices — which is why Kiro and most Arch distros ship `linux`.
- **zen / xanmod / lqx** are "patch + retune" kernels: same vanilla source, desktop-latency patchsets, modest packaging differences.
- **cachyos** is a different animal — a parameterized build system aimed at squeezing performance (native CPU, LTO/PGO, BORE). Its **native-CPU default makes binaries non-portable**, so a distro shipping it must pin `_processor_opt=generic` or build per-µarch repos (which CachyOS in fact does: v3/v4/znver4).

---

# Config personality comparison

Curated "personality" CONFIG_* options across all 8 kernels (generated 2026-05-27 by
grepping the configs). This is where the runtime character actually lives.

| Option                        | linux      | zen        | hardened    | lts           | xanmod        | lqx                 | cachyos         | cachyos-bore    |
|-------------------------------|------------|------------|-------------|---------------|---------------|---------------------|-----------------|-----------------|
| **CPU scheduler**             | EEVDF      | EEVDF +zen | EEVDF       | EEVDF         | EEVDF +xanmod | **PDS** (Project-C) | **BORE** ¹      | **BORE** ¹      |
| **Tick rate (HZ)**            | 1000       | 1000       | 1000        | **300**       | **250**       | 1000                | 300→**1000** ¹  | 300→**1000** ¹  |
| **Tickless**                  | full       | full       | full        | full          | **idle**      | full                | full            | full            |
| **Preemption**                | full (dyn) | full (dyn) | full (dyn)  | **voluntary** | **lazy**      | full                | full ¹          | full ¹          |
| **Compiler**                  | GCC        | GCC        | GCC         | GCC           | Clang ²       | GCC                 | GCC→**Clang** ¹ | GCC             |
| **LTO**                       | none       | none       | none        | none          | ThinLTO ²     | none                | none→**Thin** ¹ | none            |
| **Opt level**                 | O2         | **O3**     | O2          | O2            | O2            | **O3**              | O2→**O3** ¹     | O2→**O3** ¹     |
| **CPU target (ISA)**          | v1 generic | v1 generic | v1 generic  | v1 generic    | **v3**        | v1 generic          | v1→**native** ¹ | v1→**native** ¹ |
| **Transparent HugePages**     | always     | always     | **madvise** | always        | always        | **madvise**         | always          | always          |
| **Default TCP CC**            | cubic      | cubic      | cubic       | cubic         | **bbr**       | **bbr**             | cubic           | cubic           |
| **KASLR (RANDOMIZE_BASE)**    | on         | on         | on          | on            | on            | **OFF**             | on              | on              |
| **init_on_alloc**             | on         | on         | on          | on            | on            | on                  | on              | on              |
| **init_on_free**              | off        | off        | **ON**      | off           | off           | off                 | off             | off             |
| **FORTIFY_SOURCE**            | on         | on         | on          | on            | on            | **OFF**             | on              | on              |
| **lockdown LSM**              | on         | on         | on          | on            | on            | **OFF**             | on              | on              |
| **SLAB freelist hardened**    | on         | on         | on          | on            | on            | **OFF**             | on              | on              |
| **Rust support**              | on         | on         | **OFF**     | on            | on            | on                  | on              | on              |
| **Android binder (waydroid)** | off        | off        | off         | off           | module        | off                 | **builtin**     | **builtin**     |
| **DWARF debug**               | v5         | v5         | v5          | v5            | v5            | off→**v5** ¹        | v5              | v5              |
| **Module compression**        | zstd       | zstd       | zstd        | zstd          | zstd          | zstd                | zstd            | zstd            |

**Footnotes**
- ¹ **CachyOS** — the left value is the shipped base `config`; the **bold** value is what the
  PKGBUILD's *default* options apply via `scripts/config` at build time (the kernel you actually
  run). The base config is deliberately near-vanilla; CachyOS's identity is injected at build:
  `CACHY` config on, BORE scheduler, HZ 1000, O3, native CPU, and (for `linux-cachyos` only)
  Clang + ThinLTO. `linux-cachyos-bore` stays GCC / no-LTO.
- ² **xanmod** — the committed config was generated with **Clang + ThinLTO** and is **x86-64-v3**.
  But the AUR PKGBUILD's default `_compiler` is **GCC**, so an AUR build with defaults runs
  `olddefconfig` and drops LTO / uses GCC. Set `env _compiler=clang` to match upstream.

## Key insights from the configs

1. **Stock `linux` is already aggressively desktop-tuned** — 1000 Hz, full preemption, full
   tickless, THP=always, BBR available. The gap to "gaming kernels" is smaller than marketing
   implies *on these axes*.
2. **zen's *config* is ~identical to stock** (only O2→O3 differs here). Zen's real difference is
   the **zen-kernel patchset**, not the Arch config — so a config diff understates it.
3. **linux-lts is the true philosophical outlier** — voluntary preemption + 300 Hz = throughput
   and stability over latency. The conservative, server-leaning choice.
4. **linux-lqx trades security for speed** — KASLR off, FORTIFY off, lockdown off, freelist
   hardening off: the least-hardened of the eight. Combined with PDS + BBR + O3, it is pure
   latency/throughput focus.
5. **linux-hardened leans the opposite way** — init-on-free on, THP=madvise (less memory
   exposure), Rust off. Most of its hardening is in the patchset + sysctls, not these flags.
6. **xanmod ships the most modern-toolchain config** — Clang/ThinLTO, x86-64-v3, BBR default,
   lazy preempt — though an AUR default build falls back to GCC.
7. **cachyos's committed config is deceptively plain** — reading it alone undersells the kernel;
   everything that makes it "cachy" happens in the PKGBUILD.
8. **Android binder (waydroid/anbox)** is enabled only by cachyos (builtin) and xanmod (module);
   the Arch kernels leave it off.

> Caveat: `linux-lts` is the 6.18 series while the rest are 7.0, so a few values reflect version
> drift rather than deliberate divergence. The scheduler / preempt / HZ / hardening rows above are
> design choices, not drift.

---

# Baseline diffs vs stock `linux`

Per-kernel normalized config diffs against stock `linux` (`# … is not set` → `=n`, toolchain
version strings stripped). **linux-lts excluded** — it's 6.18 vs everyone else's 7.0, so its diff
would be dominated by version drift, not design. Full deltas saved in `diffs-vs-linux/<kernel>.diff`.

| Kernel                 | CONFIG keys changed vs stock linux                 |
|------------------------|----------------------------------------------------|
| zen                    | **8**                                              |
| cachyos / cachyos-bore | **67** (base configs byte-identical to each other) |
| xanmod                 | 193                                                |
| hardened               | 367                                                |
| lqx                    | **1336**                                           |

The headline: **the delta count does not track how "different" the kernel feels** — zen flips 8
keys, lqx flips 1336 mostly because its config descends from Debian's (huge driver set), not
because it's radically retuned.

### zen — 8 keys (the whole story)
`ZEN_INTERACTIVE=y` (the zen desktop-interactivity tunable) · O2→**O3** ·
`USER_NS_UNPRIVILEGED=y` · `VHBA=m` · `COMPACT_UNEVICTABLE_DEFAULT 1→0` · exposes the Project-C
(`SCHED_ALT`) and `PREEMPT_RT` options (left off). Everything else is identical to stock — zen's
real work is in its **patchset**, invisible to a config diff.

### cachyos / cachyos-bore — 67 keys (identical base)
Almost entirely **availability, not tuning**: waydroid binder on (`ANDROID_BINDER_IPC=y`,
binderfs), Clang-LTO machinery available, BBR**3** (`TCP_CONG_BBR3=m`), the **ADIOS** I/O
scheduler, `V4L2_LOOPBACK`/`VHBA` builtin, extra hardware drivers (Apple T2 BCE/SMC, sound
codecs, AMD ISP camera), all four schedulers present-but-off, hostname `archlinux`→`cachyos`,
panic screen QR→kmsg, and base HZ 300 / ISA v1. **The actual cachy tuning (BORE, HZ 1000, O3,
native, LTO) is applied by the PKGBUILD** — confirming the base config is deliberately plain.

### xanmod — 193 keys
Built **Clang + ThinLTO**, **x86-64-v3** · **HZ 1000→250**, full-tickless→**idle**,
PREEMPT→**lazy** (a *less* latency-aggressive profile than stock Arch's 1000/full/full!) ·
**BBR default** + BBR builtin · BFQ & Kyber I/O scheds demoted to modules · ZSWAP default
compressor zstd→**lzo** · waydroid binder (module) · Rust/GCC-plugins absent (clang build).
*(AUR default `_compiler=gcc` would undo the Clang/LTO half of this.)*

### hardened — 367 keys
Real hardening flips: **GCC hardening plugins** on (`LATENT_ENTROPY`, `STACKLEAK`) ·
`INIT_ON_FREE_DEFAULT_ON` · `BUG_ON_DATA_CORRUPTION` + `KFENCE_BUG_ON_DATA_CORRUPTION` ·
`DEBUG_PREEMPT` · THP **always→madvise** (+ shmem/tmpfs huge→never, less memory exposure) ·
**Rust off**. The bulk of the 367 is USB-gadget/configfs and driver-availability differences
(config-base divergence + the 7.0.9-vs-7.0.10 gap), not hardening.

### lqx — 1336 keys
Design flips: O2→**O3** · **Project-C PDS** scheduler (`SCHED_PDS`/`SCHED_ALT` on) which **rips
out** upstream `SCHED_CLASS_EXT` (sched-ext), `SCHED_CORE`, `SCHED_AUTOGROUP` · `ZEN_INTERACTIVE`
(it's zen-derived) · **BBR default** · ZSWAP **off by default**, compressor zstd→**lz4** · **DAMON
removed** · **security stripped**: KASLR off, FORTIFY off, SLAB-freelist-hardened off, lockdown
off, LSM drops landlock+integrity, **module signing removed entirely** (17 `MODULE_SIG_*` keys) ·
DWARF5 off in base (PKGBUILD re-adds). **The remaining ~1200 keys are Debian heritage** — its
config enables a vast extra driver set (FB_TFT displays, COMEDI DAQ, MTD-NAND, every TCP CC algo,
USB gadget), which is why the count is so high.

## Bottom line vs stock linux

- **Closest to stock:** zen (8) and cachyos-base (67) — both rely on layers *outside* the config
  (patchset / PKGBUILD).
- **Genuinely retuned in-config:** xanmod (toolchain + latency profile) and lqx (scheduler swap +
  de-hardening + Debian driver set).
- **Security spectrum:** hardened (most) → stock/zen/cachyos (Arch baseline) → **lqx (least:
  KASLR/FORTIFY/lockdown/module-sig all off)**.

---

# Scorecard (x / 10)

Each kernel rated across six axes. Scores are an **evidence-based judgment** from the configs and
PKGBUILDs compared above — not benchmarks. They reflect the kernel *as actually built*: cachyos
rows include the PKGBUILD-applied tuning (BORE, native, O3, LTO), and the xanmod row reflects its
upstream Clang/ThinLTO config (an AUR build with the default `_compiler=gcc` would shave a point or
two off Speed and Power). Weight the columns to your own priorities — there is deliberately **no
total**, since a server admin and a gamer would weight these very differently.

| Kernel                 | Speed  | Stability | Security | Responsiveness | Power | HW/Features | Best for                                  |
|------------------------|:------:|:---------:|:--------:|:--------------:|:-----:|:-----------:|-------------------------------------------|
| **linux**              |   6    |     9     |    8     |       7        |   6   |      6      | Default daily driver; the safe baseline   |
| **linux-zen**          |   7    |     8     |    8     |       8        |   6   |      6      | Desktop daily driver with extra snap      |
| **linux-hardened**     |   4    |     7     |  **10**  |       6        |   6   |      5      | Exposed / security-sensitive machines     |
| **linux-lts**          |   5    |   **10**  |    8     |       5        |   7   |      5      | Servers, stability-first, fallback kernel |
| **linux-xanmod**       |   8    |     7     |    7     |       7        | **8** |      8      | Laptops + balanced perf, waydroid         |
| **linux-lqx**          |   8    |     5     |  **3**   |     **9**      |   5   |      9      | Pure desktop/gaming feel, trusted machine |
| **linux-cachyos**      | **10** |     6     |    7     |       9        |   5   |      9      | Maximum-performance gaming desktop        |
| **linux-cachyos-bore** |   8    |     7     |    7     |       9        |   5   |      9      | cachyos performance, safer GCC build      |

**Why the standout scores:**
- **Speed** — cachyos 10 (native + ThinLTO + O3 + BORE); hardened 4 (hardening overhead, no opt, THP=madvise).
- **Stability** — lts 10 (LTS + voluntary preempt + vanilla); lqx 5 (de-hardened, sched-ext ripped out, no module sig, Debian-derived).
- **Security** — hardened 10 (stackleak/latent-entropy plugins, init-on-free, bug-on-corruption); lqx 3 (KASLR/FORTIFY/lockdown/freelist/module-sig all off).
- **Responsiveness** — lqx & cachyos 9 (PDS/BORE + full preempt + 1000 Hz); lts 5 (voluntary preempt + 300 Hz).
- **Power** — xanmod 8 (250 Hz + idle-tickless + lazy preempt); cachyos/lqx 5 (1000 Hz, full preempt/tickless, perf-leaning).
- **HW/Features** — lqx/cachyos 9 (huge driver set / binder + BBR3 + ADIOS + ZFS + v4l2loopback); hardened & lts 5 (lean).

> These are relative scores within *this* set of Arch kernels, not absolute. Stock `linux` scoring
> 8 on security and 9 on stability is why it remains the sensible default for a general distro.
