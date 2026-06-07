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
#   Fail-safe cleanup for an interrupted ISO build. mkarchiso leaves
#   bind-mounts (dev/proc/sys/run/tmp/pts/shm/efivars) live under the
#   work dir when a build is stopped or crashes; stacked broken mounts
#   block the next build, jam the file manager, and can freeze the box.
#   This unmounts everything still mounted under the work dir.
#
#     unmount-build.sh check   list stale mounts (read-only, no root);
#                              exit 0 = none, 1 = some.
#     unmount-build.sh clean   lazily unmount them deepest-first. Run as
#                              root (the GUI calls it via pkexec).
#
#   Why: the GUI's Stop button only SIGTERMs the build — the mounts it
#   leaves behind were what wedged the system. build-the-iso.sh derives
#   the work dir the same way; this helper reuses that derivation so the
#   CLI, the GUI Stop handler, and the pre-flight check all agree on what
#   to clean.
#
#   NOTE: deliberately off-template (no colours / on_error / main), a
#   lean sibling of host-prep-run.sh. See Kiro-HQ/TEMPLATE_EXCLUSIONS.md.
#
#####################################################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

# Resolve the invoking user's home even under pkexec (where $HOME is root's),
# so build_location=home points at the real work dir, not /root/kiro-build.
if [[ -n "${PKEXEC_UID:-}" ]]; then
    user_home="$(getent passwd "${PKEXEC_UID}" | cut -d: -f6)"
else
    user_home="${HOME}"
fi

# Derive buildFolder exactly like build-the-iso.sh (build_location decides
# whether work sits next to the clone or under $HOME).
build_location="local"
[[ -f "${SCRIPT_DIR}/build.conf" ]] && source "${SCRIPT_DIR}/build.conf"
if [[ "${build_location}" == "local" ]]; then
    buildFolder="$(cd -- "${REPO_DIR}/.." && pwd)/kiro-build"
else
    buildFolder="${user_home}/kiro-build"
fi

list_stale_mounts() {
    [[ -d "${buildFolder}" ]] || return 0
    findmnt -rno TARGET 2>/dev/null \
        | awk -v b="${buildFolder}" 'index($0, b"/") == 1 || $0 == b' | sort -r
}

mode="${1:-clean}"
case "${mode}" in
    check)
        mounts="$(list_stale_mounts)"
        [[ -n "${mounts}" ]] && echo "${mounts}"
        [[ -z "${mounts}" ]]   # exit 0 when clean, 1 when mounts remain
        ;;
    clean)
        while read -r target; do
            [[ -n "${target}" ]] || continue
            echo "Unmounting stale build mount: ${target}"
            umount -R -l "${target}" 2>/dev/null || umount -l "${target}" 2>/dev/null || true
        done < <(list_stale_mounts)
        echo "Build-mount cleanup done."
        ;;
    *)
        echo "usage: $(basename "$0") {check|clean}" >&2
        exit 1
        ;;
esac
