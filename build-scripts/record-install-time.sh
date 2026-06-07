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
#   SSH into a freshly-installed Kiro target, read /var/log/Calamares.log
#   to compute the Calamares install wall-clock + mkinitcpio pass count,
#   read /etc/dev-rel for the ISO version, and prepend a row to the
#   "## Calamares Installs" table in kiro-iso/BUILD_TIMES.md.
#
#   Why: closes the install-time tracking loop. ISO build times are
#   auto-appended by build-the-iso.sh; install times needed a manual
#   step until now. Run this after each test install on any target to
#   keep the table populated with no kiro_final-side change required
#   (Calamares.log already timestamps every line — that's the data
#   source, no package rebuild needed).
#
#   Works on any Arch system: the target is given as `vm` (the
#   VirtualBox NAT default) or `[user@]host[:port]`. SSH user, port and
#   password resolve from the target/flags, then KIRO_SSH_USER /
#   KIRO_SSH_PORT / KIRO_SSH_PASS env vars, then sensible defaults.
#
#####################################################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${SCRIPT_DIR}/.."
BUILD_TIMES="${REPO_DIR}/BUILD_TIMES.md"

#####################################################################
# Colors
#####################################################################
if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    CYAN="$(tput setaf 6)"
    RESET="$(tput sgr0)"
else
    RED="" GREEN="" YELLOW="" BLUE="" CYAN="" RESET=""
fi

#####################################################################
# Logging
#####################################################################
log_section() { echo; echo "${GREEN}############################################################################${RESET}"; echo "$1"; echo "${GREEN}############################################################################${RESET}"; echo; }
log_info()    { echo; echo "${BLUE}############################################################################${RESET}"; echo "$1"; echo "${BLUE}############################################################################${RESET}"; echo; }
log_warn()    { echo; echo "${YELLOW}############################################################################${RESET}"; echo "$1"; echo "${YELLOW}############################################################################${RESET}"; echo; }
log_error()   { echo; echo "${RED}############################################################################${RESET}"; echo "$1"; echo "${RED}############################################################################${RESET}"; echo; }
log_success() { echo; echo "${GREEN}############################################################################${RESET}"; echo "$1"; echo "${GREEN}############################################################################${RESET}"; echo; }

#####################################################################
# Error handling
#####################################################################
on_error() {
    local lineno="$1"
    local cmd="$2"
    echo
    echo "${RED}ERROR on line ${lineno}: ${cmd}${RESET}"
    echo
    sleep 10
}
trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

#####################################################################
# Functions
#####################################################################
show_help() {
    cat <<EOF
record-install-time.sh — pull Calamares install timing from a target and
log it to BUILD_TIMES.md.

Usage:
    bash record-install-time.sh <target> [--user U] [--port P] [--password PW] [--notes "..."] [--dry-run]

Target:
    vm                  → 127.0.0.1 on port 2022 (VirtualBox NAT forward default)
    [user@]host[:port]  → any reachable host (e.g. me@192.168.1.50, box.local:22)

User / port / password resolve highest-precedence first:
    1. the user@ / :port in the target, or the --user / --port / --password flags
    2. the KIRO_SSH_USER / KIRO_SSH_PORT / KIRO_SSH_PASS environment variables
    3. defaults: user=\$USER, port=22 (2022 for the 'vm' keyword), key/agent auth

Options:
    --user U       SSH user (default: \$USER or KIRO_SSH_USER).
    --port P       SSH port (default: 22, or 2022 for 'vm').
    --password PW  Use sshpass with this password instead of key/agent auth.
                   Requires the 'sshpass' package. Prefer key auth where possible.
    --notes "..."  Free-text column for the table row (e.g. "post-fix",
                   "BIOS install", "with X tweak").
    --dry-run      Print the row that would be inserted, don't modify the file.
    -h, --help     This message.

Data source: /var/log/Calamares.log on the target.
  - Duration  = last timestamp - first timestamp
  - Passes    = count of '==> Building image' lines
  - ISO       = ISO_RELEASE value from /etc/dev-rel

Idempotent? No — re-running prepends another row. Trim duplicates by hand.
EOF
}

# Builds the SSH command for a target. Reads opt_user/opt_port/opt_pass set by
# main, falling back to KIRO_SSH_* env vars and then built-in defaults.
resolve_ssh() {
    local target="$1"
    local t_user="" t_host="" t_port="" default_port=22

    if [[ "${target}" == "vm" ]]; then
        t_host="127.0.0.1"
        default_port=2022
    else
        local raw="${target}"
        if [[ "${raw}" == *@* ]]; then
            t_user="${raw%%@*}"
            raw="${raw#*@}"
        fi
        if [[ "${raw}" == *:* ]]; then
            t_port="${raw##*:}"
            raw="${raw%:*}"
        fi
        t_host="${raw}"
    fi

    local user port password
    user="${t_user:-${opt_user:-${KIRO_SSH_USER:-$USER}}}"
    port="${t_port:-${opt_port:-${KIRO_SSH_PORT:-$default_port}}}"
    password="${opt_pass:-${KIRO_SSH_PASS:-}}"

    local ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -p ${port}"
    if [[ -n "${password}" ]]; then
        echo "sshpass -p ${password} ssh ${ssh_opts} ${user}@${t_host}"
    else
        echo "ssh ${ssh_opts} ${user}@${t_host}"
    fi
}

# Pulls four newline-separated fields from the target:
#   first_ts | last_ts | iso_version | mkinitcpio_passes
#
# first_ts uses the first "Starting job .+ ( 1 / N )" marker — that's the
# canonical "user clicked Install" event, since Calamares only emits
# numbered job lines once the install pipeline actually starts. Using the
# very first timestamped line would instead measure Calamares-app-launch
# (welcome screen) → end-of-install, which includes the time the user
# spent reading/clicking through the wizard. Fallback to the very first
# timestamp on the unlikely chance the marker isn't present.
fetch_facts() {
    local ssh_cmd="$1"
    ${ssh_cmd} '
        if [[ ! -f /var/log/Calamares.log ]]; then
            echo "ERROR: /var/log/Calamares.log not present on this target" >&2
            exit 1
        fi
        first_ts=$(grep -E "Starting job .+\( 1 / [0-9]+ \)" /var/log/Calamares.log | head -1 \
                   | grep -oE "^[0-9]{4}-[0-9]{2}-[0-9]{2} - [0-9]{2}:[0-9]{2}:[0-9]{2}")
        if [[ -z "${first_ts}" ]]; then
            first_ts=$(grep -oE "^[0-9]{4}-[0-9]{2}-[0-9]{2} - [0-9]{2}:[0-9]{2}:[0-9]{2}" /var/log/Calamares.log | head -1)
        fi
        last_ts=$(grep -oE "^[0-9]{4}-[0-9]{2}-[0-9]{2} - [0-9]{2}:[0-9]{2}:[0-9]{2}" /var/log/Calamares.log | tail -1)
        iso_release=$(grep -oP "^ISO_RELEASE=\K.*" /etc/dev-rel 2>/dev/null || echo "?")
        mkinitcpio_passes=$(grep -c "==> Building image" /var/log/Calamares.log || true)
        printf "%s\n%s\n%s\n%s\n" "${first_ts}" "${last_ts}" "${iso_release}" "${mkinitcpio_passes}"
    '
}

compute_duration() {
    # Args: "YYYY-MM-DD - HH:MM:SS" "YYYY-MM-DD - HH:MM:SS"
    # Output: "NmMs" (e.g. "3m20s")
    local first="$1" last="$2"
    # Strip the " - " separator so `date -d` can parse
    local first_clean last_clean
    first_clean="$(echo "${first}" | sed 's/ - / /')"
    last_clean="$(echo "${last}" | sed 's/ - / /')"
    local first_epoch last_epoch duration mins secs
    first_epoch=$(date -d "${first_clean}" +%s 2>/dev/null || echo 0)
    last_epoch=$( date -d "${last_clean}" +%s 2>/dev/null || echo 0)
    if [[ "${first_epoch}" -eq 0 || "${last_epoch}" -eq 0 ]]; then
        echo "?"; return
    fi
    duration=$((last_epoch - first_epoch))
    mins=$((duration / 60))
    secs=$((duration % 60))
    echo "${mins}m${secs}s"
}

insert_row() {
    local row="$1"
    if [[ ! -f "${BUILD_TIMES}" ]] || ! grep -q '^## Calamares Installs$' "${BUILD_TIMES}"; then
        log_error "BUILD_TIMES.md missing or malformed (no '## Calamares Installs' section)"
        exit 1
    fi
    local tmp
    tmp="$(mktemp)"
    awk -v row="${row}" '
        /^## Calamares Installs$/ { in_section = 1 }
        /^## / && !/^## Calamares Installs$/ { in_section = 0 }
        { print }
        /^\|---/ && in_section && !injected { print row; injected = 1 }
    ' "${BUILD_TIMES}" > "${tmp}" && mv "${tmp}" "${BUILD_TIMES}"
}

#####################################################################
# Main
#####################################################################
main() {
    local target="" notes="" dry_run=false
    local opt_user="" opt_port="" opt_pass=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)  show_help; exit 0 ;;
            --user)     opt_user="$2"; shift 2 ;;
            --port)     opt_port="$2"; shift 2 ;;
            --password) opt_pass="$2"; shift 2 ;;
            --notes)    notes="$2"; shift 2 ;;
            --dry-run)  dry_run=true; shift ;;
            -*)         log_error "Unknown option: $1"; exit 1 ;;
            *)          target="$1"; shift ;;
        esac
    done

    if [[ -z "${target}" ]]; then
        log_error "Missing target argument. Use --help for usage."
        exit 1
    fi

    # Password auth needs sshpass; fail early with a clear message if it's missing.
    if [[ -n "${opt_pass:-${KIRO_SSH_PASS:-}}" ]] && ! command -v sshpass &>/dev/null; then
        log_error "A password was supplied (--password or KIRO_SSH_PASS) but 'sshpass' is not installed.
Install it (sudo pacman -S sshpass) or use key-based SSH auth instead."
        exit 1
    fi

    log_section "Fetching install facts from '${target}'"
    local ssh_cmd
    ssh_cmd="$(resolve_ssh "${target}")"

    local facts first_ts last_ts iso_release passes
    facts="$(fetch_facts "${ssh_cmd}")" || { log_error "SSH fetch failed"; exit 1; }
    first_ts="$(echo "${facts}" | sed -n '1p')"
    last_ts="$( echo "${facts}" | sed -n '2p')"
    iso_release="$(echo "${facts}" | sed -n '3p')"
    passes="$(echo "${facts}"  | sed -n '4p')"

    if [[ -z "${first_ts}" || -z "${last_ts}" ]]; then
        log_error "Could not extract timestamps from Calamares.log on target"
        exit 1
    fi

    local duration
    duration="$(compute_duration "${first_ts}" "${last_ts}")"

    local stamp row
    stamp="$(date '+%Y-%m-%d %H:%M')"
    row="| ${stamp} | ${iso_release} | ${target} | ${duration} | ${passes} | ${notes} |"

    log_info "Row to insert:
${row}

  install_started: ${first_ts}
  install_ended:   ${last_ts}
  iso_release:     ${iso_release}
  passes:          ${passes}
  duration:        ${duration}"

    if [[ "${dry_run}" == true ]]; then
        log_warn "--dry-run set — not modifying ${BUILD_TIMES}"
        exit 0
    fi

    insert_row "${row}"
    log_success "$(basename "$0") done — prepended row to ${BUILD_TIMES}"
}

main "$@"
