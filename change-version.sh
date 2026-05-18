#!/bin/bash
set -euo pipefail
#####################################################################
# Author    : Erik Dubois
# Website   : https://www.erikdubois.be
#####################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
#####################################################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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
log_section() {
    echo
    echo "${GREEN}############################################################################${RESET}"
    echo "$1"
    echo "${GREEN}############################################################################${RESET}"
    echo
}

log_info() {
    echo
    echo "${BLUE}############################################################################${RESET}"
    echo "$1"
    echo "${BLUE}############################################################################${RESET}"
    echo
}

log_warn() {
    echo
    echo "${YELLOW}############################################################################${RESET}"
    echo "$1"
    echo "${YELLOW}############################################################################${RESET}"
    echo
}

log_error() {
    echo
    echo "${RED}############################################################################${RESET}"
    echo "$1"
    echo "${RED}############################################################################${RESET}"
    echo
}

log_success() {
    echo
    echo "${GREEN}############################################################################${RESET}"
    echo "$1"
    echo "${GREEN}############################################################################${RESET}"
    echo
}

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
bump_version() {
    local year month day extra newversion
    year=$(date +%y)
    month=$(date +%m)
    day=$(date +%d)
    extra="01"  # bump manually for same-day rebuilds

    newversion="v${year}.${month}.${day}.${extra}"

    log_section "Bumping version to ${newversion}"

    local devrel="${SCRIPT_DIR}/archiso/airootfs/etc/dev-rel"
    local buildiso="${SCRIPT_DIR}/build-scripts/build-the-iso.sh"
    local profiledef="${SCRIPT_DIR}/archiso/profiledef.sh"

    echo "Updating ${devrel}"
    sed -i "s|^ISO_RELEASE=.*|ISO_RELEASE=${newversion}|" "${devrel}"

    echo "Updating ${buildiso}"
    sed -i "s|\(.*kiroVersion='\)[^']*\('.*\)|\1${newversion}\2|" "${buildiso}"

    echo "Updating iso_label in ${profiledef}"
    sed -i "s|^iso_label=\"kiro-.*\"|iso_label=\"kiro-${newversion}\"|" "${profiledef}"

    echo "Updating iso_version in ${profiledef}"
    sed -i "s|^iso_version=\"v.*\"|iso_version=\"${newversion}\"|" "${profiledef}"

    log_info "Old → new version summary:
  dev-rel     : $(grep '^ISO_RELEASE=' "${devrel}")
  build-iso   : $(grep 'kiroVersion=' "${buildiso}")
  profiledef  : $(grep '^iso_label=' "${profiledef}") / $(grep '^iso_version=' "${profiledef}")"
}

#####################################################################
# Main
#####################################################################
main() {
    bump_version
    log_success "$(basename "$0") done"
}

main "$@"
