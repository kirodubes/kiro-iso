#!/bin/bash
set -euo pipefail
#####################################################################
# Author    : Erik Dubois
# Website   : https://kiroproject.be
#####################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
#   Purpose:
#   Print, one per line, the kernels the enabled repos offer that are
#   safe to ship on the ISO. A package qualifies ONLY if both <k> and
#   <k>-headers exist — the -headers test is what tells a real kernel
#   apart from a companion package (zfs, nvidia, …) AND guarantees the
#   DKMS drivers (nvidia-*-dkms, virtualbox) can build. No false
#   positives: CPU-microarch builds (linux-x64v*, linux-znver*) and
#   niche kernels are deliberately excluded.
#
#   Why: single source of truth for kernel discovery. build-the-iso.sh
#   sources nothing here — it runs this and reads stdout — and the
#   kiro-iso-builder GUI's "Detect" button runs the exact same logic,
#   so the CLI and GUI always agree on what is offerable.
#
#   Output: kernel package names on stdout, one per line (machine
#   readable — no logging/colour noise here). Read-only: uses only
#   pacman -Si / -Slq against the already-synced DBs, never root.
#
#   NOTE: off-template on purpose (stdout must stay machine-readable).
#   See Kiro-HQ/TEMPLATE_EXCLUSIONS.md.
#
#####################################################################

# Single-variant kernels to probe by name.
KERNEL_CANDIDATES=(linux linux-lts linux-zen linux-hardened linux-rt linux-rt-lts linux-mainline)

main() {
    local found=()
    local k
    for k in "${KERNEL_CANDIDATES[@]}"; do
        if pacman -Si "${k}" &>/dev/null && pacman -Si "${k}-headers" &>/dev/null; then
            found+=("${k}")
        fi
    done

    # Multi-variant families (CachyOS, XanMod, pinned-LTS series) discovered
    # dynamically so the list never goes stale as new flavors land.
    local c
    while IFS= read -r c; do
        [[ -z "${c}" || "${c}" == *-headers ]] && continue
        pacman -Si "${c}-headers" &>/dev/null || continue
        [[ " ${found[*]} " == *" ${c} "* ]] && continue
        found+=("${c}")
    done < <(pacman -Slq 2>/dev/null | grep -E '^(linux-cachyos|linux-xanmod|linux-lts[0-9])' || true)

    [[ ${#found[@]} -gt 0 ]] && printf '%s\n' "${found[@]}"
}

main "$@"
