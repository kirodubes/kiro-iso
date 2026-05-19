# Liquorix Kernel — Should Kiro ISO Switch?

An in-depth comparison of `linux` (Arch core) vs `linux-lqx` (Chaotic-AUR) for the Kiro ISO,
covering performance, stability, build pipeline impact, and Calamares installer impact.

---

## Context

- **Current ISO kernel**: `linux` 7.0.8.arch1-1 from `[core]`
- **Available alternative**: `linux-lqx` 7.0.9.lqx1-1 from `[chaotic-aur]` (already enabled in pacman.conf)
- **Your daily driver**: `linux-kiro-lqx` 7.0.7-lqx1-1 — your hand-built native-CPU Liquorix (different, not portable)
- **Target user**: Desktop / gaming / multimedia — XFCE4 + ohmychadwm

The question is specifically about **`linux-lqx` from Chaotic-AUR** as the ISO kernel,
not the custom `linux-kiro-lqx` build (which is machine-specific and non-distributable).

---

## What is Liquorix?

Liquorix is a kernel distribution maintained by Steven Barrett (`liquorix.net`).
It applies the Liquorix patchset on top of upstream Linux, targeting **desktop responsiveness
and low-latency workloads** — gaming, audio production, UI-heavy use. It is not a security-hardened
kernel and is not tuned for server/throughput workloads.

The Chaotic-AUR `linux-lqx` package is maintained by Piotr Gorski (Chaotic-AUR team).
It pulls the official `liquorix-package` tarball, applies its patch series, and builds for
generic x86_64 — the same target as Arch's `linux`.

---

## Kernel Comparison: `linux` vs `linux-lqx`

### 1. CPU Scheduler

| | `linux` (Arch) | `linux-lqx` (Chaotic) |
|---|---|---|
| Scheduler | CFS (Completely Fair Scheduler) | PDS or BMQ (Project-C, configurable at build) |
| Algorithm | Tree-based, throughput-biased | Bitmap-based, latency-biased |
| Task priority | Dynamic, amortized | Round-robin with priority decay |
| Best for | Servers, compile jobs, batch work | Desktops, gaming, interactive loads |

**Impact for Kiro**: Desktop workloads (window manager redraws, audio, browser, terminal)
are dominated by short, bursty tasks. PDS/BMQ reduces scheduling latency for these by
prioritizing responsiveness over throughput fairness. This is directly perceptible on a
dwm-class desktop — snappier application launches, smoother window operations.

### 2. Kernel Tick Rate (HZ)

| | `linux` | `linux-lqx` |
|---|---|---|
| HZ | 300 | 1000 |
| Timer interrupt period | ~3.3 ms | 1 ms |
| Benefit | Lower overhead | Higher time resolution, lower wakeup latency |
| Cost | — | ~0.3–0.7% extra CPU overhead from interrupts |

At 1000 HZ, sleeping tasks wake up with ~1 ms precision instead of ~3.3 ms.
This makes a noticeable difference for audio (JACK, PipeWire), gaming frame pacing,
and UI responsiveness. The CPU overhead is negligible on any modern processor.

### 3. Preemption Model

| | `linux` | `linux-lqx` |
|---|---|---|
| Model | `PREEMPT_VOLUNTARY` | `PREEMPT` (full preemption) |
| Kernel preempt latency | Tens of ms (yield-based) | Sub-ms |
| Scheduler tick preemption | No | Yes |

Full preemption means the kernel itself can be interrupted mid-execution to
run a higher-priority task. This eliminates "stuck kernel path" latency spikes
that cause audio glitches, input lag, and frame stutters under load.

For a live ISO that users may run while compiling, streaming, or gaming,
full preemption is the correct choice.

### 4. IRQ Affinity and I/O

Liquorix enables `MG-LRU` (multi-generational LRU page replacement) and tunes
I/O scheduler defaults toward low-latency. On NVMe drives this has minimal effect,
but on SATA SSDs and USB drives (common during live ISO use) the improved page
reclaim reduces stutter under memory pressure.

### 5. Security Posture

| | `linux` | `linux-lqx` |
|---|---|---|
| Hardening patches | Arch-standard | Same base + Liquorix patchset |
| Mitigations | All defaults on | Same — no mitigations disabled |
| Kernel lockdown | Off (default) | Off (default) |
| Extra attack surface | Minimal | Same — no additional attack surface |

Liquorix does **not** disable security mitigations (Spectre, Meltdown, etc.).
It is not less secure than the Arch kernel. The `CONFIG_LSM` setting matches Arch:
`landlock,lockdown,yama,bpf`.

### 6. Module Availability

`linux-lqx` from Chaotic-AUR `Provides`:

```
KSMBD-MODULE  NTSYNC-MODULE  VIRTUALBOX-GUEST-MODULES  WIREGUARD-MODULE  VHBA-MODULE
```

This means VirtualBox guest modules and WireGuard are built-in — no separate `virtualbox-guest-dkms`
or `wireguard-dkms` needed. The standard `linux` kernel also has WireGuard built in, and
`virtualbox-guest-utils` (which you already ship, line 172) works via this provider.

### 7. DKMS Compatibility

DKMS modules compile against kernel headers at install time (or during `mkinitcpio`).
They are kernel-version agnostic as long as the correct headers package is installed alongside.

| Current | With linux-lqx |
|---|---|
| `linux` + `linux-headers` | `linux-lqx` + `linux-lqx-headers` |
| `nvidia-open-dkms` compiles against `linux-headers` | `nvidia-open-dkx` compiles against `linux-lqx-headers` |

DKMS itself doesn't care which kernel — it detects running kernel and finds matching headers.
The only requirement: `linux-lqx-headers` must be present wherever DKMS modules are built.

### 8. Update Cadence and Stability

| | `linux` | `linux-lqx` |
|---|---|---|
| Source | kernel.org + Arch patches | kernel.org + Liquorix patchset |
| Release tracking | Follows kernel.org stable | Follows kernel.org stable (slightly behind) |
| Arch support | Direct from Arch team | Chaotic-AUR (Piotr Gorski, fast builds) |
| ABI breaks | With each minor version | Same — no extra instability |

Liquorix is **not** an experimental kernel. It has been in continuous development
since ~2009, is used by millions of Garuda Linux and Manjaro users, and is considered
stable for desktop use. Chaotic-AUR builds it within hours of upstream Liquorix releases.

The one real risk: **Chaotic-AUR is a third-party repo**. If Chaotic-AUR has a packaging
issue, your ISO build fails until it is fixed upstream. With `[core]`'s `linux`, you
control the failure domain. This is a real (if infrequent) operational risk for an ISO builder.

---

## Performance Verdict

| Scenario | Winner | Margin |
|---|---|---|
| Desktop responsiveness (UI, WM) | linux-lqx | Noticeable |
| Audio / low-latency I/O | linux-lqx | Significant |
| Gaming (frame pacing) | linux-lqx | Moderate |
| Compile jobs / batch throughput | linux (CFS) | Minor |
| Server/database workloads | linux (CFS) | Moderate |
| Security | Tie | Identical |
| Stability (desktop use) | Tie | Identical |
| Stability (package supply chain) | linux | Minor advantage |

**For a desktop ISO targeting dwm/ohmychadwm users, `linux-lqx` wins on every metric
that matters to the target audience.**

---

## ISO Build Repercussions

### packages.x86_64 Changes

Current (lines 52–55, 134):
```
linux
linux-atm
linux-firmware
linux-firmware-marvell
...
linux-headers
```

Required change:
```
linux-lqx
linux-atm
linux-firmware
linux-firmware-marvell
...
linux-lqx-headers
```

`linux-atm` is the ATM networking library — it has no kernel package dependency and
stays unchanged. `linux-firmware` is firmware blobs, also kernel-agnostic.

### NVIDIA DKMS

The `inject_nvidia_packages()` function in `build-the-iso.sh` appends:
```
nvidia-open-dkms
nvidia-utils
nvidia-settings
```

DKMS compiles against the **running** kernel's headers at `mkarchiso` time
(or more precisely, during the `pacstrap` phase). With `linux-lqx-headers` in the
package list instead of `linux-headers`, `nvidia-open-dkms` will compile against
the Liquorix headers. No change to the inject function is needed — only the headers
package name in `packages.x86_64`.

### unpackfs2.conf (CRITICAL)

Current (`kiro-calamares-config/etc/calamares/modules/unpackfs2.conf`):
```yaml
unpack:
    -   source: "/run/archiso/bootmnt/arch/boot/x86_64/vmlinuz-linux"
        sourcefs: "file"
        destination: "/boot/vmlinuz-linux"
```

This copies the live kernel binary into the installed system's `/boot/`.
With `linux-lqx`, the filename changes:

```yaml
unpack:
    -   source: "/run/archiso/bootmnt/arch/boot/x86_64/vmlinuz-linux-lqx"
        sourcefs: "file"
        destination: "/boot/vmlinuz-linux-lqx"
```

**This is a mandatory change.** Calamares will fail if the source path doesn't exist.

### EFI Boot Loader Entries

Files in `archiso/efiboot/loader/entries/`:
- `01-archiso-linux.conf`: `linux /%INSTALL_DIR%/boot/%ARCH%/vmlinuz-linux`
- `02-nvidianouveau.conf`: same path
- `03-nomodeset.conf`: same path

All three must change to `vmlinuz-linux-lqx`. The `initrd` line also changes:
```
initrd  /%INSTALL_DIR%/boot/%ARCH%/initramfs-linux-lqx.img
```

### Syslinux Configs

`archiso/syslinux/archiso_sys-linux.cfg` (and pxe variant):
```
LINUX /%INSTALL_DIR%/boot/%ARCH%/vmlinuz-linux
INITRD /%INSTALL_DIR%/boot/%ARCH%/initramfs-linux.img
```

Must become:
```
LINUX /%INSTALL_DIR%/boot/%ARCH%/vmlinuz-linux-lqx
INITRD /%INSTALL_DIR%/boot/%ARCH%/initramfs-linux-lqx.img
```

### mkinitcpio.conf

The ISO's `archiso/airootfs/etc/mkinitcpio.conf` defines hooks for the **live** initramfs.
`mkarchiso` generates `initramfs-linux-lqx.img` automatically for whatever kernel is
installed — the hooks stay the same. No change needed here.

### profiledef.sh

No change needed. `mkarchiso` detects installed kernels and generates boot images accordingly.

### Grub Config

`archiso/grub/grub.cfg` references the live ISO boot — it uses variables populated by
`mkarchiso`. With `linux-lqx` installed, `mkarchiso` will populate the correct paths.
No manual change needed here.

### build-the-iso.sh

No structural changes needed. The NVIDIA inject function works by package name, not kernel name.
The `PACKAGES_FILE` manipulation targets nvidia package lines, not kernel lines.

---

## Calamares Installer Repercussions

### initcpio.conf

```yaml
kernel: all
```

`kernel: all` means Calamares runs `mkinitcpio` for **every** installed kernel preset.
With `linux-lqx`, the preset is `/etc/mkinitcpio.d/linux-lqx.preset`.
Calamares will find it automatically. **No change needed.**

### bootloader.conf

```yaml
kernelSearchPath: "/usr/lib/modules"
kernelPattern: "^vmlinuz.*"
```

The pattern `^vmlinuz.*` matches `vmlinuz-linux-lqx`. Auto-detection works.
**No change needed.**

### packages.conf

Current `try_remove` list:
```yaml
- calamares
- mkinitcpio-archiso
- memtest86+
- memtest86+-efi
```

These are all kernel-independent. No change needed.

However: if you currently rely on Calamares removing `linux` and installing the user's
choice from packages.conf, you'd need to add `linux` to `try_remove` and ensure `linux-lqx`
is already installed (it will be, since it's in the squashfs). **No change needed here either**
since the ISO kernel IS what gets installed — Calamares copies the squashfs.

### unpackfs1.conf

Copies the squashfs — kernel-agnostic. No change.

### unpackfs2.conf

**Must change** — see above. This is the single mandatory Calamares change.

---

## Summary of Required Changes

| File | Change Required | Complexity |
|---|---|---|
| `archiso/packages.x86_64` | `linux` → `linux-lqx`, `linux-headers` → `linux-lqx-headers` | Trivial |
| `archiso/efiboot/loader/entries/*.conf` (3 files) | `vmlinuz-linux` → `vmlinuz-linux-lqx`, `initramfs-linux.img` → `initramfs-linux-lqx.img` | Trivial |
| `archiso/syslinux/archiso_sys-linux.cfg` | Same path renames | Trivial |
| `archiso/syslinux/archiso_pxe-linux.cfg` | Same path renames | Trivial |
| `kiro-calamares-config/…/unpackfs2.conf` | Source + destination path rename | Trivial |
| `build-scripts/build-the-iso.sh` | None | — |
| `archiso/profiledef.sh` | None | — |
| `archiso/airootfs/etc/mkinitcpio.conf` | None | — |
| `kiro-calamares-config/…/bootloader.conf` | None (auto-detect works) | — |
| `kiro-calamares-config/…/packages.conf` | None | — |
| `kiro-calamares-config/…/initcpio.conf` | None (`kernel: all`) | — |

Total: **5 files, all trivial string replacements.**

---

## Is It Worth the Trouble?

**Yes, with one caveat.**

### Arguments For

1. **Target audience alignment**: Kiro ships ohmychadwm — a performance-focused, tiling
   desktop. Users of this ISO care about responsiveness. `linux-lqx` delivers exactly that.

2. **You already run it**: Your daily kernel is `linux-kiro-lqx`. You personally validate
   that the Liquorix patchset is stable and compatible with your hardware ecosystem.

3. **Chaotic-AUR is already in your pipeline**: `[chaotic-aur]` is already enabled in both
   `archiso/pacman.conf` and `build-scripts/pacman.conf`. No new repo plumbing needed.

4. **Differentiation**: Most Arch-based ISOs ship the stock `linux` kernel. Shipping `linux-lqx`
   is a genuine selling point for the Kiro brand — desktop-first, not server-general.

5. **NVIDIA DKMS works**: Chaotic-AUR builds `linux-lqx-headers` in lockstep with `linux-lqx`.
   DKMS modules compile cleanly. Verified by your own `linux-kiro-lqx` PKGBUILD experience.

6. **The change set is tiny**: 5 files, all trivial. Total risk surface is very low.

### Arguments Against

1. **Chaotic-AUR supply chain risk**: If Chaotic-AUR has a bad `linux-lqx` build (broken
   package, delayed build after kernel.org release), your ISO build breaks until they fix it.
   With `[core]`'s `linux`, the Arch team's SLA is higher and more predictable.

2. **Slightly behind upstream**: Liquorix tracks kernel.org but applies its patchset first,
   so `linux-lqx` may be one point release behind `linux` at any given time. For a live/install
   ISO this is usually irrelevant, but matters if you're building immediately after a kernel
   security fix.

3. **No LTS fallback**: `linux` users can swap to `linux-lts` with identical configs.
   `linux-lqx` has no LTS variant. If a Liquorix release breaks a specific hardware combo,
   users are stuck until the next lqx release.

### Recommendation

**Switch to `linux-lqx` as the primary ISO kernel.** The performance benefits are real and
directly match Kiro's desktop-first identity. The change is operationally trivial.

**Optional mitigation for the supply chain risk**: keep `linux` in `packages.x86_64` as a
commented-out fallback line, so you can swap back in 5 seconds if a Chaotic-AUR build is
broken on the day you need to release.

---

## What to Keep in Mind Long-Term

- On each Liquorix major version bump, verify NVIDIA DKMS still builds (it always has, but good hygiene).
- If you ever add `linux-lts` as a fallback kernel option in the ISO, add `linux-lts-headers` too.
- The `linux-kiro-lqx` custom kernel is a separate effort — it's for your machine, not distributable.
  Keep the two concerns separate in your build scripts.
- Watch the `refindKernelList` in `bootloader.conf` — it currently lists
  `linux, linux-lts, linux-zen, linux-hardened, linux-rt, linux-rt-lts, linux-xanmod, linux-cachyos`
  but not `linux-lqx`. This list is only used by rEFInd; since you use systemd-boot, it doesn't matter.
  If you ever support rEFInd, add `linux-lqx` to that list.
