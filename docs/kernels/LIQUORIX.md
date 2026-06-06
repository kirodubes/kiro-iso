# Why Kiro Ships the Liquorix Kernel

> **Historical note — 2026-05-28:** Kiro no longer ships `linux-lqx`. The default kernel was switched to `linux-cachyos` (with `linux-zen` as a fallback option in the boot menu). This page is kept as a record of the prior Liquorix era and the reasoning that informed it; for the current kernel choice, see `KERNEL_CHOICE_FOR_KIRO.md`.

Kiro ships `linux-lqx` (Liquorix) as its default kernel instead of the stock Arch `linux` kernel. This page explains **what changed**, **why we changed it**, and **what it means for you as a Kiro user**.

The change was first trialled on the `kiro-iso-next` experimental track, then promoted to the stable `kiro-iso` build once we were satisfied with stability and hardware compatibility.

---

## TL;DR

|                      | Before (stock `linux`)          | After (`linux-lqx`)             |
|----------------------|---------------------------------|---------------------------------|
| Kernel source        | Arch core repo                  | Chaotic-AUR (Liquorix patchset) |
| CPU scheduler        | EEVDF (fairness-oriented)       | PDS/BMQ (latency-biased)        |
| Tick rate            | 300 Hz                          | 1000 Hz                         |
| Preemption           | Voluntary                       | Full (`PREEMPT`)                |
| Page replacement     | Standard                        | MG-LRU                          |
| Security mitigations | All defaults on                 | Identical — nothing disabled    |
| Best for             | General-purpose, servers, batch | Desktop, gaming, audio, UI      |

**You should feel:** snappier window operations, more stable audio under load, smoother game frame pacing, and identical security posture. You will not notice any difference at the login screen, during install, or in day-to-day Pacman use.

---

## What is Liquorix?

Liquorix is a Linux kernel distribution maintained by Steven Barrett ([liquorix.net](https://liquorix.net)). It takes upstream Linux and applies a curated **patchset focused on desktop responsiveness and low-latency workloads** — gaming, audio production, UI-heavy use.

It is **not** a security-hardened kernel and is **not** tuned for server / throughput workloads. It is also not an experimental kernel — Liquorix has been in continuous development since around 2009 and powers daily-driver installs for millions of users on distributions like Garuda Linux and Manjaro.

Kiro's specific package, `linux-lqx`, is built by the Chaotic-AUR team (Piotr Gorski). It takes the official Liquorix patch series, applies it to upstream Linux, and builds for generic x86_64 — exactly the same target as Arch's stock `linux`.

> One note for readers comparing notes with Erik's personal machine: Erik also maintains a separate package called `linux-kiro-lqx`, which is a **machine-specific native-CPU Liquorix build** — different from `linux-lqx` and not portable. Kiro the distribution ships `linux-lqx`, not `linux-kiro-lqx`.

---

## The studies we ran

Each of the sections below is a place we looked, what we found, and what the practical consequence is for someone running Kiro.

### 1. CPU scheduler

|               | `linux` (Arch)                    | `linux-lqx`                         |
|---------------|-----------------------------------|-------------------------------------|
| Scheduler     | EEVDF (Earliest Eligible Virtual Deadline First) | PDS or BMQ (Project-C) |
| Algorithm     | Tree-based, fairness-oriented     | Bitmap-based, latency-biased        |
| Task priority | Dynamic, amortized                | Round-robin with priority decay     |
| Best for      | Servers, compile jobs, batch work | Desktops, gaming, interactive loads |

Desktop workloads — window-manager redraws, audio callback chains, browser repaints, terminal input — are dominated by short, bursty tasks. PDS/BMQ schedules these by **prioritizing responsiveness over throughput fairness**. On a tiling WM like ohmychadwm or i3, the effect is directly perceptible: snappier application launches, smoother window operations.

### 2. Kernel tick rate (HZ)

|                        | `linux` | `linux-lqx`                   |
|------------------------|---------|-------------------------------|
| HZ                     | 300     | 1000                          |
| Timer interrupt period | ~3.3 ms | 1 ms                          |
| Wakeup precision       | ~3.3 ms | ~1 ms                         |
| Cost                   | —       | ~0.3–0.7 % extra CPU overhead |

At 1000 Hz, sleeping tasks wake up with ~1 ms precision instead of ~3.3 ms. This is the difference between "audio glitch every few minutes under load" and "no audible artifacts." For JACK / PipeWire users, gamers chasing consistent frame pacing, and anyone running a UI-heavy desktop, this is the single most noticeable change. The overhead is negligible on any modern CPU.

### 3. Preemption model

|                           | `linux`                  | `linux-lqx`                 |
|---------------------------|--------------------------|-----------------------------|
| Model                     | `PREEMPT_VOLUNTARY`      | `PREEMPT` (full preemption) |
| Kernel preempt latency    | Tens of ms (yield-based) | Sub-ms                      |
| Scheduler tick preemption | No                       | Yes                         |

Full preemption means the kernel itself can be interrupted mid-execution to run a higher-priority task. This eliminates the "stuck kernel path" latency spikes that cause audio glitches, input lag, and frame stutters under load.

For a live ISO that users may run while compiling, streaming, or gaming, full preemption is the correct choice.

### 4. Memory and I/O

`linux-lqx` enables **MG-LRU** (multi-generational LRU page replacement) and tunes I/O scheduler defaults toward low latency. On modern NVMe drives the effect is small, but on SATA SSDs and USB drives — common during live-ISO use from a thumbstick — the improved page reclaim noticeably reduces stutter under memory pressure.

### 5. Security posture

|                                       | `linux`                      | `linux-lqx`                   |
|---------------------------------------|------------------------------|-------------------------------|
| Hardening patches                     | Arch-standard                | Same base + Liquorix patchset |
| Mitigations (Spectre, Meltdown, etc.) | All defaults on              | Same — **nothing disabled**   |
| Kernel lockdown                       | Off (default)                | Off (default)                 |
| `CONFIG_LSM`                          | `landlock,lockdown,yama,bpf` | Same                          |

Liquorix does **not** trade security for performance. None of the standard CPU-vulnerability mitigations are disabled. The Linux Security Modules configuration matches Arch's. Anyone telling you Liquorix is "less secure" is repeating a misconception.

### 6. Built-in module availability

`linux-lqx` provides built-in support for: KSMBD, NTSYNC, VirtualBox guest modules, WireGuard, and VHBA. In practice this means VirtualBox guest tooling and WireGuard work out of the box without separate DKMS packages.

### 7. DKMS / NVIDIA compatibility

DKMS modules compile against kernel headers at install time. They are kernel-version agnostic as long as the matching headers package is installed. Kiro ships `linux-lqx-headers` alongside `linux-lqx`, so `nvidia-open-dkms` (and any other DKMS module) compiles cleanly against the Liquorix headers. **There is no NVIDIA regression** from this switch — verified on multiple cards before promoting to stable.

### 8. Update cadence and stability

|                  | `linux`                   | `linux-lqx`                               |
|------------------|---------------------------|-------------------------------------------|
| Source           | kernel.org + Arch patches | kernel.org + Liquorix patchset            |
| Release tracking | Follows kernel.org stable | Follows kernel.org stable (~hours behind) |
| ABI breaks       | With each minor version   | Same — no extra instability               |
| Build pipeline   | Direct from Arch team     | Chaotic-AUR (fast, automated builds)      |

Chaotic-AUR typically publishes the new `linux-lqx` within hours of an upstream Liquorix release.

---

## Performance verdict

| Scenario                         | Winner        | Margin          |
|----------------------------------|---------------|-----------------|
| Desktop responsiveness (UI, WM)  | `linux-lqx`   | Noticeable      |
| Audio / low-latency I/O          | `linux-lqx`   | Significant     |
| Gaming (frame pacing)            | `linux-lqx`   | Moderate        |
| Compile / batch throughput       | `linux` (EEVDF) | Minor           |
| Server / database workloads      | `linux` (EEVDF) | Moderate        |
| Security                         | Tie           | Identical       |
| Stability (desktop use)          | Tie           | Identical       |
| Stability (package supply chain) | `linux`       | Minor advantage |

For a desktop-first ISO targeting a tiling-WM-savvy audience, `linux-lqx` wins on every metric that matters to the target user.

---

## Validation — what we tested on real hardware

The sections above are the *why*. This is the *proof*: the kernel-specific results pulled from every boot/install test we ran. Liquorix was trialled on the `kiro-iso-next` track first, then promoted to the stable `kiro-iso` build on **2026-05-19** once these passed. Full per-build logs (including non-kernel checks) live in [DISTRO_TESTING.md](../../DISTRO_TESTING.md); this table is the kernel summary.

| Build            | Hardware                  | `linux-lqx`  | Boot | Kernel-specific result                                                                                          |
|------------------|---------------------------|--------------|------|----------------------------------------------------------------------------------------------------------------|
| v26.05.18        | VirtualBox (UEFI, Intel)  | 7.0.9-lqx1   | PASS | Kernel running, `vmlinuz-linux-lqx` + initramfs present, `linux-lqx.preset` exists / `linux.preset` removed — all PASS |
| v26.05.19        | VirtualBox (UEFI, Intel)  | 7.0.9-lqx1   | PASS | 93/0/0 audit; kernel boot phase 3.0s                                                                            |
| v26.05.24 (next) | Bare metal (UEFI, Intel)  | 7.0.10-lqx1  | PASS | 92/0/0; **hibernate/resume (S4) + suspend (S3) PASS**; kernel boot phase 1.7s                                   |
| v26.05.25        | Bare metal (UEFI, Intel)  | 7.0.10-lqx1  | PASS | 110/1/0; kernel boot phase 1.655s                                                                               |

What each kernel-relevant check confirmed:

- **Boot path (UEFI / systemd-boot)** — PASS on both VirtualBox and bare-metal Picard. The EFI entries reference `vmlinuz-linux-lqx` / `initramfs-linux-lqx.img` and load correctly.
- **Boot path (BIOS / syslinux)** — syslinux configs updated to the `-lqx` paths; BIOS boot verified working.
- **Boot image generation** — `mkarchiso` detects the installed `linux-lqx` and generates matching boot images; on the installed system `linux-lqx.preset` is present and the stock `linux.preset` is removed.
- **NVIDIA DKMS** — `nvidia-open-dkms` compiles cleanly against `linux-lqx-headers`; `driver=nonfree` boot verified on a real NVIDIA GPU. No regression versus the stock kernel.
- **Hibernate / resume (S4) and suspend (S3)** — PASS on bare metal. The `resume` hook is present in the `linux-lqx` initramfs, ordered after `block` / before `filesystems`, and the `resume=UUID=` cmdline matches the swap partition. (Hibernate could not be validated under VirtualBox — `vmwgfx` blocks the freeze while 3D resources are active; that is a VM virtual-GPU limitation, not a kernel issue.)
- **Boot-phase timing** — kernel phase ~1.7s on bare metal, ~3.0s in VirtualBox; in line with stock-kernel timings, no regression from the Liquorix patchset.

> mkinitcpio hooks, microcode handling, and the PipeWire stack are kernel-agnostic and were verified unaffected by the switch — see DISTRO_TESTING.md for those non-kernel details.

---

## The trade-off we accepted

The honest counter-argument: **Chaotic-AUR is a third-party repository**. Two real (if infrequent) consequences:

1. **Supply chain risk.** If Chaotic-AUR ships a broken `linux-lqx` build, or is late after an upstream kernel.org release, our ISO build can't happen until they fix it. With Arch core's `linux`, the failure domain is the Arch team — a tighter SLA.

2. **Slightly behind upstream.** Liquorix tracks kernel.org but applies its patchset first, so `linux-lqx` may be one point release behind `linux` at any moment. For a normal install this never matters; for someone building an ISO **right after a kernel security disclosure**, a few hours can matter.

3. **No LTS variant.** `linux` users can swap to `linux-lts` with the same configs. Liquorix has no LTS branch. If a Liquorix release breaks a specific hardware combo, users wait until the next release.

We considered these acceptable because: (a) we already had `[chaotic-aur]` enabled in the ISO build for unrelated reasons, so no new plumbing; (b) Erik has been daily-driving the Liquorix patchset locally for a long time, so the failure modes are well-characterised; and (c) the change is genuinely small — five files, all trivial string replacements — meaning we can switch back to `linux` in minutes if a Chaotic-AUR outage ever forces our hand.

---

## What actually changed (for the curious)

For users who fork or rebuild Kiro themselves, here is the exact change set. Five files; each change is a string replacement.

| File                                                            | Change                                                                                   |
|-----------------------------------------------------------------|------------------------------------------------------------------------------------------|
| `kiro-iso/archiso/packages.x86_64`                              | `linux` → `linux-lqx`, `linux-headers` → `linux-lqx-headers`                             |
| `kiro-iso/archiso/efiboot/loader/entries/01-archiso-linux.conf` | `vmlinuz-linux` → `vmlinuz-linux-lqx`, `initramfs-linux.img` → `initramfs-linux-lqx.img` |
| `kiro-iso/archiso/efiboot/loader/entries/02-nvidianouveau.conf` | Same path renames                                                                        |
| `kiro-iso/archiso/efiboot/loader/entries/03-nomodeset.conf`     | Same path renames                                                                        |
| `kiro-iso/archiso/syslinux/archiso_sys-linux.cfg`               | Same path renames                                                                        |
| `kiro-iso/archiso/syslinux/archiso_pxe-linux.cfg`               | Same path renames                                                                        |
| `kiro-calamares-config/etc/calamares/modules/unpackfs2.conf`    | Source + destination kernel path                                                         |

Files that **did not** need to change, in case you're checking parity with another ISO:

- `archiso/profiledef.sh` — `mkarchiso` detects installed kernels and generates boot images accordingly.
- `archiso/airootfs/etc/mkinitcpio.conf` — hooks are kernel-agnostic.
- `archiso/grub/grub.cfg` — `mkarchiso` populates the paths.
- `build-scripts/build-the-iso.sh` — NVIDIA inject targets package names, not kernel names.
- `kiro-calamares-config/.../bootloader.conf` — pattern `^vmlinuz.*` matches `vmlinuz-linux-lqx`.
- `kiro-calamares-config/.../packages.conf` — `try_remove` is kernel-agnostic.
- `kiro-calamares-config/.../initcpio.conf` — `kernel: all` runs against whatever is installed.

---

## Looking ahead

Things we still want to track over time:

- **NVIDIA DKMS** — on each Liquorix major version bump, smoke-test that `nvidia-open-dkms` still builds. It always has so far, but this is the most likely place a regression would first appear.
- **LTS fallback** — we don't currently ship `linux-lts` as a fallback kernel. If we add one in the future, we'd also add `linux-lts-headers` and a second EFI entry. Worth doing once we hit a Liquorix release that misbehaves on real user hardware.
- **rEFInd support** — Kiro uses systemd-boot, so the `refindKernelList` in `bootloader.conf` is currently inert. If we ever add rEFInd, `linux-lqx` needs to be added to that list.
- **Package-name clarity** — the `linux-lqx` / `linux-liquorix` / `linux-kiro-lqx` names are a recurring source of confusion for anyone reading the source or comparing notes. Keep the distinction documented; see [A note on names](#a-note-on-names) at the end of this doc.

---

## A note on names

Three similar-looking names float around the Liquorix world. Only the first is what Kiro ships:

- **`linux-lqx`** — the Arch package of the Liquorix patchset, built by the Chaotic-AUR team (Piotr Gorski). **This is Kiro's kernel.** Kiro pulls it as a prebuilt binary from `[chaotic-aur]`; there is no compile step.
- **`linux-liquorix`** — shorthand for the *upstream* Liquorix project's own pre-compiled binaries, distributed via [liquorix.net](https://liquorix.net) for Debian/Ubuntu (installed there with a repo/curl script). Same patchset, different packaging — it is **not** the Arch package name and **not** how Kiro installs the kernel. If a comparison or article calls Kiro's kernel "linux-liquorix", read it as `linux-lqx`.
- **`linux-kiro-lqx`** — Erik's personal, machine-specific **native-CPU** Liquorix build. Not portable, not distributed, and **not** what the ISO ships. It shares the patchset but nothing else — different package, different purpose, no shared code path.

If you remember one thing: **Kiro ships `linux-lqx` from Chaotic-AUR.**

---

## Credits

- Liquorix patchset — Steven Barrett ([liquorix.net](https://liquorix.net))
- `linux-lqx` package build — Piotr Gorski / Chaotic-AUR team
- Performance studies, integration into Kiro, and this writeup — Erik Dubois
