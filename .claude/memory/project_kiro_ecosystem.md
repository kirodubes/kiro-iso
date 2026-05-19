---
name: KIRO project ecosystem
description: Which repos exist under /home/erik/KIRO/ and which to ignore
type: project
originSessionId: f2f98e51-aaa7-4015-8188-6fff3023f347
---
Active KIRO repos under `/home/erik/KIRO/`:
- `kiro-iso` — main ISO build (primary working project)
- `kiro-iso-next` — parallel next-branch ISO
- `kiro-calamares-config` — Calamares installer config (kiro_before, kiro_final, kiro_remove_nvidia, kiro_ucode modules)
- `kiro-pkgbuild` — PKGBUILDs for custom Calamares packages
- `kiro_repo` — binary package repo served to the ISO

**Desktop environments (as of 2026-05-18):**
- XFCE4 (primary)
- ohmychadwm
- edu-chadwm is **dropped** — user confirmed it will not be installed going forward. Package is commented out in `packages.x86_64`. Remove any new references to edu-chadwm in scripts, docs, and configs.

**Omit from analysis and changelogs:**
- `linux-kiro` — user said to ignore

**Beta/testing repos (active, not to be ignored):**
- `kiro-iso-next` — paired with `kiro-calamares-config-next` for testing; current experiment: Liquorix kernel (`linux-lqx`)
- `kiro-calamares-config-next` — experimental Calamares config; `unpackfs2.conf` updated for `vmlinuz-linux-lqx`

**Why:** User explicitly asked to exclude these two folders.

**How to apply:** When exploring the KIRO ecosystem, surveying projects, or generating changelogs, skip these two directories.
