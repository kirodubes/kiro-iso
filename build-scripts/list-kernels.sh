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
#   Print, one per line, every kernel the enabled repos offer. A
#   package qualifies as a kernel ONLY if both <k> and <k>-headers
#   exist — the -headers test is what tells a real kernel apart from a
#   companion package (zfs, nvidia, …) AND guarantees the DKMS drivers
#   (nvidia-*-dkms, virtualbox) can build against it. No curation
#   beyond that: the full offering is listed (every CachyOS/XanMod
#   flavor, pinned-LTS series, and CPU-microarch builds like
#   linux-x64v* / linux-znver* are all included), so the chooser sees
#   exactly what the repos carry.
#
#   Why: single source of truth for kernel discovery. build-the-iso.sh
#   sources nothing here — it runs this and reads stdout — and the
#   kiro-iso-builder GUI runs the exact same logic, so the CLI and GUI
#   always agree on what is offerable.
#
#   Output: kernel package names on stdout, one per line, sorted
#   (machine readable — no logging/colour noise here). With
#   --with-repo each line is "<repo><TAB><kernel>" instead (the GUI
#   uses this to group kernels by source; the build never passes it).
#   Read-only: a single `pacman -Sl` against the already-synced DBs,
#   never root.
#
#   NOTE: off-template on purpose (stdout must stay machine-readable).
#   See Kiro-HQ/TEMPLATE_EXCLUSIONS.md.
#
#####################################################################

main() {
    local with_repo=0
    [[ "${1:-}" == "--with-repo" ]] && with_repo=1

    # One pass over every repo package: remember which names exist, and map
    # name -> repo (first hit wins, i.e. highest-priority repo, the order
    # `pacman -Sl` emits). A kernel is then any name X that is not itself a
    # -headers package and has a matching X-headers.
    local -A repo_of=()
    local -A exists=()
    local rname pname rest
    while read -r rname pname rest; do
        exists["${pname}"]=1
        [[ -n "${repo_of[${pname}]+x}" ]] || repo_of["${pname}"]="${rname}"
    done < <(pacman -Sl 2>/dev/null || true)

    local name
    local -a names=()
    for name in "${!exists[@]}"; do
        [[ "${name}" == *-headers ]] && continue
        [[ -n "${exists["${name}-headers"]+x}" ]] || continue
        names+=("${name}")
    done
    [[ ${#names[@]} -eq 0 ]] && return 0

    local sorted
    while IFS= read -r sorted; do
        if (( with_repo )); then
            printf '%s\t%s\n' "${repo_of[${sorted}]}" "${sorted}"
        else
            printf '%s\n' "${sorted}"
        fi
    done < <(printf '%s\n' "${names[@]}" | sort)
}

main "$@"
