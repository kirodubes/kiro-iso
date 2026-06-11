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
#   Thin dispatcher that lets the kiro-iso-builder GUI invoke a single
#   host-prep.sh helper (ensure_package, setup_chaotic, setup_cachyos,
#   enable_cachyos)
#   in isolation, without running the whole build. host-prep.sh is a
#   sourced fragment that expects its caller to provide the log_*
#   helpers and a few vars; this wrapper supplies lightweight stdout
#   log_* shims, sources build.conf (for chaoticsrepo), sources
#   host-prep.sh, then runs the requested function.
#
#   Why: the GUI runs each fix via `pkexec bash host-prep-run.sh <fn>`
#   so one polkit prompt elevates it; inside (already root) host-prep's
#   own sudo calls are no-ops. build-the-iso.sh stays the single source
#   of truth for the build while the GUI reuses its prep logic.
#
#   Usage: host-prep-run.sh <function> [args...]
#     host-prep-run.sh setup_cachyos
#     host-prep-run.sh enable_cachyos
#     host-prep-run.sh setup_chaotic
#     host-prep-run.sh ensure_package archiso
#
#   NOTE: deliberately off-template (no banner colours / on_error trap /
#   main()). It is a sourced-fragment launcher whose whole job is to
#   provide the minimal environment host-prep.sh needs. See
#   Kiro-HQ/TEMPLATE_EXCLUSIONS.md.
#
#####################################################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Lightweight log_* shims — host-prep.sh's helpers resolve to these when
# it is not sourced by build-the-iso.sh. Plain stdout so the GUI streams
# them straight into its log pane.
log_section() { echo "## $*"; }
log_info()    { echo "[info] $*"; }
log_warn()    { echo "[warn] $*"; }
log_error()   { echo "[error] $*" >&2; }
log_success() { echo "[ok] $*"; }
status_ok()   { echo "[ok] $*"; }
status_nok()  { echo "[!!] $*"; }

# chaoticsrepo (setup_chaotic reads it) and the other knobs come from build.conf.
[[ -f "${SCRIPT_DIR}/build.conf" ]] && source "${SCRIPT_DIR}/build.conf"

source "${SCRIPT_DIR}/host-prep.sh"

if [[ $# -lt 1 ]]; then
    log_error "usage: $(basename "$0") <function> [args...]"
    exit 1
fi

"$@"
