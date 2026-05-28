# Arch-Based Distros — Kernel Usage Comparison

Reference table of 20 Arch-based distributions and the kernels they ship.
"Default" = what you boot after a stock install; nearly all let you switch via
the bootloader, since these kernels live in Arch's official repos.

_Compiled 2026-05-27. Live-verified rows noted below; others are long-standing defaults._

| #   | Distro                       | Base                 | Default kernel                                              | Also offers / notes                                                          |
|-----|------------------------------|----------------------|-------------------------------------------------------------|------------------------------------------------------------------------------|
| 1   | **Arch Linux** (reference)   | —                    | `linux` (stock mainline)                                    | `linux-lts`, `linux-zen`, `linux-hardened`, `linux-rt` in official repos     |
| 2   | **EndeavourOS**              | Arch                 | `linux` (stock)                                             | AKM tool adds zen/lts/hardened/rt post-install                               |
| 3   | **CachyOS**                  | Arch                 | `linux-cachyos` (BORE/sched-ext, LTO+PGO)                   | Largest selection: -lts, -rt, -server, BMQ/EEVDF variants via Kernel Manager |
| 4   | **Garuda Linux**             | Arch                 | `linux-zen`                                                 | lts/hardened/mainline via Garuda Settings Manager                            |
| 5   | **Manjaro**                  | Arch (own repos)     | Recent **stock-based stable** (points to highest installed) | Many stable + LTS series via `mhwd-kernel` / Manjaro Settings                |
| 6   | **ArcoLinux**                | Arch                 | `linux` (stock)                                             | Designed for learning; easy to add zen/lts                                   |
| 7   | **Artix Linux**              | Arch (systemd-free)  | `linux` (stock)                                             | `linux-lts`, `linux-zen`; init = OpenRC/runit/s6/dinit                       |
| 8   | **RebornOS**                 | Arch                 | `linux` (stock, bleeding-edge)                              | lts/zen selectable                                                           |
| 9   | **Archcraft**                | Arch                 | `linux` (stock)                                             | Minimal Openbox/WM spin                                                      |
| 10  | **Athena OS**                | Arch                 | `linux` (stock)                                             | Pentest-focused; `linux-hardened` option                                     |
| 11  | **SteamOS 3**                | Arch                 | Valve **custom kernel** (~6.11; 6.16 in 3.8 preview)        | Immutable; tuned for Steam Deck/handhelds                                    |
| 12  | **BlendOS**                  | Arch                 | `linux` (stock, ~6.9 at v4)                                 | Immutable/declarative/atomic                                                 |
| 13  | **Crystal Linux**            | Arch                 | `linux` (stock)                                             | GNOME-focused, `ame` AUR helper                                              |
| 14  | **Mabox Linux**              | Manjaro→Arch         | **LTS** kernel (6.18 LTS in 26.01)                          | Openbox; stable + LTS images                                                 |
| 15  | **ArchBang**                 | Arch                 | `linux` (stock)                                             | Lightweight Openbox live distro                                              |
| 16  | **Bluestar Linux**           | Arch                 | `linux` (stock, latest)                                     | Full KDE, ships current mainline                                             |
| 17  | **Parch Linux**              | Arch                 | `linux` (stock)                                             | Beginner-friendly, multi-DE                                                  |
| 18  | **Obarun**                   | Arch (systemd-free)  | `linux` (stock)                                             | s6/66 init instead of systemd                                                |
| 19  | **Arch Linux GUI / Anarchy** | Arch                 | `linux` (stock)                                             | Installer projects; lts/zen optional at install                              |
| 20  | **Hyperbola**                | Arch-derived (libre) | `linux-libre` **LTS**                                       | Fully-free kernel; project migrating to BSD                                  |

## The pattern across all of them

- **Stock `linux`** is the overwhelming default (rows 1–2, 6–10, 12–13, 15–19).
- **`linux-zen`** is the notable default outlier — Garuda.
- **`linux-cachyos`** — CachyOS, the performance-tuned standout that's grown fast.
- **LTS as default** — Mabox and Hyperbola favor long-term-support kernels.
- **Custom vendor kernels** — only SteamOS (Valve) and CachyOS maintain their own.

## Where Kiro sits

**Kiro ships stock `linux`** — placing it in the mainstream majority above
(rows 1–2, 6–10, etc.). This is the conventional, lowest-surprise choice and
matches Arch and EndeavourOS.

## Confidence

- **Live-verified (2026-05-27):** CachyOS, Garuda, Manjaro, SteamOS, Mabox, Artix, BlendOS.
- **From standing knowledge:** rows 13, 16, 17, 18, 19 — stable long-standing defaults.

## Sources

- [ArchWiki — Kernel](https://wiki.archlinux.org/title/Kernel)
- [ArchWiki — Arch-based distributions](https://wiki.archlinux.org/title/Arch-based_distributions)
- [CachyOS Wiki — Kernel](https://wiki.cachyos.org/features/kernel/)
- [Garuda Linux](https://garudalinux.org/)
- [Artix Linux — Wikipedia](https://en.wikipedia.org/wiki/Artix_Linux)
- [SteamOS 3.7 kernel — Phoronix](https://www.phoronix.com/news/SteamOS-3.7.8-Stable)
- [Mabox 26.01 — 6.18 LTS kernel](https://maboxlinux.org/mabox-26-01-latest-6-18-lts-kernel/)
- [blendOS v4 release — 9to5Linux](https://9to5linux.com/immutable-distro-blendos-4-officially-released-now-fully-declarative)
- [Arch-based distros 2026 — commandlinux](https://commandlinux.com/arch-linux/arch-based-distros/)
