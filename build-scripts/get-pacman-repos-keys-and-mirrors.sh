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
install_chaotic_packages() {
    # Stable names from Chaotic-AUR's own install guide (no index scraping).
    local base_url="https://cdn-mirror.chaotic.cx/chaotic-aur"
    # Full fingerprint of Chaotic-AUR's primary key (Pedro Henrique Lara Campos). Packages are signed
    # by a subkey; gpg reports the primary in the last field of VALIDSIG, which is what we compare.
    local chaotic_key="EF925EA60F33D0CB85C44AD13056513887B78AEB"

    log_section "Installing chaotic-keyring and chaotic-mirrorlist"

    log_info "Updating system and installing required tools"
    sudo pacman -Syu --needed --noconfirm wget curl

    log_info "Trusting the Chaotic-AUR signing key"
    sudo pacman-key --recv-keys "${chaotic_key}" --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key "${chaotic_key}"

    # pacman -U on a local file does not check signatures (LocalFileSigLevel = Optional,
    # no .sig beside it), so verify each package against the pinned key before installing.
    local dl pkg primary
    dl="$(mktemp -d)"
    for pkg in chaotic-keyring chaotic-mirrorlist; do
        log_info "Downloading and verifying ${pkg}"
        wget -q "${base_url}/${pkg}.pkg.tar.zst"     -O "${dl}/${pkg}.pkg.tar.zst"
        wget -q "${base_url}/${pkg}.pkg.tar.zst.sig" -O "${dl}/${pkg}.pkg.tar.zst.sig"
        primary="$(gpg --homedir /etc/pacman.d/gnupg --status-fd 1 \
            --verify "${dl}/${pkg}.pkg.tar.zst.sig" "${dl}/${pkg}.pkg.tar.zst" 2>/dev/null \
            | awk '$2 == "VALIDSIG" {print $NF}')" || true
        if [[ "${primary}" != "${chaotic_key}" ]]; then
            log_error "${pkg}: signature does not verify against the Chaotic-AUR key ${chaotic_key}
(got: '${primary:-no valid signature}'). Not installing it."
            rm -rf "${dl}"
            exit 1
        fi
        echo "${pkg}: signature OK (${chaotic_key})"
    done

    log_info "Installing keyring and mirrorlist"
    sudo pacman -U --noconfirm --needed "${dl}/chaotic-keyring.pkg.tar.zst" "${dl}/chaotic-mirrorlist.pkg.tar.zst"

    rm -rf "${dl}"
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

    # Append only the repo sections the host lacks. Never copy the template over the host file:
    # on a non-Kiro build host (Ryoku, CachyOS, EndeavourOS, Garuda…) that deletes the distro's own repos.
    local repo block added=0
    for repo in nemesis_repo chaotic-aur; do
        if grep -qE "^[[:space:]]*\[${repo}\][[:space:]]*$" "${target}"; then
            log_info "[${repo}] already in ${target} — leaving it as is"
            continue
        fi
        block="$(awk -v hdr="[${repo}]" '
            $0 == hdr { p = 1; print; next }
            p && (/^\[/ || !NF) { exit }
            p { print }
        ' "${source_conf}")"
        if [[ -z "${block}" ]]; then
            log_error "[${repo}] not found in ${source_conf}"
            exit 1
        fi
        log_info "Appending [${repo}] to ${target}"
        printf '\n%s\n' "${block}" | sudo tee -a "${target}" >/dev/null
        added=$((added + 1))
    done

    if (( added == 0 )); then
        log_success "pacman.conf already has nemesis_repo and chaotic-aur — nothing changed"
    else
        log_success "pacman.conf updated — ${added} repo section(s) appended, existing repos untouched"
    fi
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
