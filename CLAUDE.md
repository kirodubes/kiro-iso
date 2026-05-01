# KIRO ISO — Claude Instructions

## Project

Custom Arch Linux ISO builder based on ArchISO. Produces a live/installable ISO with XFCE4 + ohmychadwm/edu-chadwm desktop, pre-configured packages, and systemd optimizations.

Key files:
- `archiso/airootfs/etc/dev-rel` — current ISO version string
- `archiso/packages.x86_64` — full package list
- `archiso/profiledef.sh` — ISO label and version
- `build-scripts/build-the-iso.sh` — build entry point
- `change-version.sh` — bumps version across all version files
- `up.sh` — update helper

## Changelog Style

When updating `CHANGELOG.md`:
- **Newest commits first**
- **Group pure daily rebuilds** (version bump + mirrorlist only) into a single line: `## YYYY-MM-DD — vXX.XX.XX.XX` with bullet `- **Version bump** + mirrorlist refresh`
- **Separate substantive changes** into their own dated section with categorized bullets
- Use **bold** for file names, package names, and key actions
- Use sub-headers (`###`) for multi-commit days with distinct themes
- Be concise — one bullet per logical change, not per file

## Commit Conventions

All commits currently use generic `update` messages. When asked to commit, use semantic messages:
- `feat: add <package/feature>`
- `fix: <what was broken>`
- `chore: version bump vXX.XX.XX.XX`
- `refactor: <what changed and why>`
- `docs: update CHANGELOG / README`

## Branding Notes

- Project was originally based on ArcoLinux — references to `arcolinux-*` are being replaced with `edu-*` or `kiro-*` equivalents
- Desktop environments: XFCE4 (primary), ohmychadwm, edu-chadwm
- Package repo: Chaotic-AUR + optional local `personal_repo`
