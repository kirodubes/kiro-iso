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
install_chaotic_packages() {
    local base_url="https://geo-mirror.chaotic.cx/chaotic-aur/x86_64/"

    log_section "Installing chaotic-keyring and chaotic-mirrorlist"

    log_info "Updating system and installing required tools"
    sudo pacman -Syu --needed --noconfirm wget jq curl

    log_info "Fetching latest package URLs from Chaotic-AUR"

    local keyring_pkg mirrorlist_pkg
    keyring_pkg=$(curl -s "${base_url}" | grep -oP "chaotic-keyring-[0-9][^\"]+\.pkg\.tar\.zst" | sort -V | tail -n 1)
    mirrorlist_pkg=$(curl -s "${base_url}" | grep -oP "chaotic-mirrorlist-[0-9][^\"]+\.pkg\.tar\.zst" | sort -V | tail -n 1)

    if [[ -z "${keyring_pkg}" || -z "${mirrorlist_pkg}" ]]; then
        log_error "Failed to resolve one or more package filenames from ${base_url}"
        exit 1
    fi

    local keyring_url="${base_url}${keyring_pkg}"
    local mirrorlist_url="${base_url}${mirrorlist_pkg}"

    log_info "Downloading packages"
    wget -q "${keyring_url}"    -O chaotic-keyring.pkg.tar.zst
    wget -q "${mirrorlist_url}" -O chaotic-mirrorlist.pkg.tar.zst

    log_info "Installing keyring and mirrorlist"
    sudo pacman -U --noconfirm --needed chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst

    rm -f chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst
    log_success "chaotic-keyring and chaotic-mirrorlist installed"
}

configure_pacman_conf() {
    local source_conf="${SCRIPT_DIR}/pacman.conf"
    local target="/etc/pacman.conf"
    local backup="${target}.kiro"

    log_section "Configuring /etc/pacman.conf"

    if [[ ! -f "${source_conf}" ]]; then
        log_error "Source pacman.conf not found: ${source_conf}"
        exit 1
    fi

    if [[ -e "${backup}" ]]; then
        log_info "Backup already exists at ${backup} — skipping backup"
    else
        log_info "Backing up ${target} to ${backup}"
        sudo cp -v "${target}" "${backup}"
    fi

    log_info "Installing ${source_conf} → ${target}"
    sudo cp -v "${source_conf}" "${target}"
    log_success "pacman.conf updated — nemesis_repo and chaotic-aur are now configured"
}

#####################################################################
# Main
#####################################################################
main() {
    install_chaotic_packages
    configure_pacman_conf
    log_success "$(basename "$0") done"
}

main "$@"
