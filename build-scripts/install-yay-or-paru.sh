#!/bin/bash
set -euo pipefail
#####################################################################
# Author    : Erik Dubois
# Website   : https://kiroproject.be
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
install_aur_helper() {
    local name="$1"
    local url="$2"
    local archive="${name}-git.tar.gz"
    local srcdir="${name}-git"

    log_section "Building and installing ${name}"

    cd /tmp
    curl -LO "${url}"
    tar -xf "${archive}"
    cd "${srcdir}"
    makepkg -si
    cd /tmp
    rm -rf "${archive}" "${srcdir}"

    log_success "${name} installed"
}

#####################################################################
# Main
#####################################################################
main() {
    local yay_url="https://aur.archlinux.org/cgit/aur.git/snapshot/yay-git.tar.gz"
    local paru_url="https://aur.archlinux.org/cgit/aur.git/snapshot/paru-git.tar.gz"

    log_section "AUR helper installer"
    echo "Choose a package to build:"
    echo "  1) yay"
    echo "  2) paru"
    echo "  *) exit"
    read -rp "Enter your choice: " choice

    case "${choice}" in
        1) install_aur_helper "yay"  "${yay_url}"  ;;
        2) install_aur_helper "paru" "${paru_url}" ;;
        *)
            log_info "Exiting — no package selected"
            exit 0
            ;;
    esac

    log_success "$(basename "$0") done"
}

main "$@"
