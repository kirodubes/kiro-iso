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
REPO_DIR="${SCRIPT_DIR}/.."

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
# Build configuration — edit these before building
#####################################################################
desktop="xfce4/edu-chadwm/ohmychadwm"
kiroVersion='v26.05.18.01'
nvidia_driver="open"          # open | 580xx | 390xx
chaoticsrepo=true
clean_pacman_cache="no"       # yes | no
remove_build_folder="no"      # yes | no — set to yes to clean up after build

buildFolder="${HOME}/kiro-build"
outFolder="${HOME}/kiro-Out"
isoLabel="kiro-${kiroVersion}-x86_64.iso"
PACKAGES_FILE="${buildFolder}/archiso/packages.x86_64"

#####################################################################
# Functions
#####################################################################
check_not_root() {
    if [[ "${EUID}" -eq 0 ]]; then
        log_error "Do not run this script as root. Run as a normal user — sudo is called internally where needed."
        exit 1
    fi
}

warn_btrfs() {
    if lsblk -f | grep -q btrfs; then
        log_warn "Btrfs filesystem detected.
This script may cause issues on Btrfs. Make backups before continuing.
Press CTRL+C to stop now."
        for i in $(seq 10 -1 1); do
            echo -ne "Continuing in ${i} seconds... \r"
            sleep 1
        done
        echo
    fi
}

clean_cache() {
    if [[ "${clean_pacman_cache}" == "yes" ]]; then
        log_section "Cleaning pacman package cache"
        yes | sudo pacman -Scc
    else
        log_info "Skipping pacman cache clean (clean_pacman_cache=no)"
    fi
}

remove_buildfolder() {
    local action="${1:-no}"
    if [[ "${action}" == "yes" ]]; then
        if [[ -d "${buildFolder}" ]]; then
            log_warn "Deleting build folder: ${buildFolder}"
            sudo rm -rf "${buildFolder}"
        else
            log_info "No build folder found — nothing to delete"
        fi
    fi
}

ensure_package() {
    local pkg="$1"
    if ! pacman -Qi "${pkg}" &>/dev/null; then
        log_warn "${pkg} not installed — installing now"
        sudo pacman -S --noconfirm "${pkg}"
    fi
    if ! pacman -Qi "${pkg}" &>/dev/null; then
        log_error "${pkg} could not be installed — aborting"
        exit 1
    fi
}

setup_chaotic() {
    [[ "${chaoticsrepo}" == "true" ]] || return 0

    if pacman -Q chaotic-keyring &>/dev/null && pacman -Q chaotic-mirrorlist &>/dev/null; then
        log_info "Chaotic keyring and mirrorlist are both installed"
    else
        local setup_script="${SCRIPT_DIR}/get-pacman-repos-keys-and-mirrors.sh"
        if [[ -f "${setup_script}" ]]; then
            log_warn "Installing chaotic-keyring and chaotic-mirrorlist"
            bash "${setup_script}"
        else
            log_error "Setup script not found: ${setup_script}"
            exit 1
        fi
    fi
}

show_overview() {
    log_section "Build overview"
    echo "  Desktop      : ${desktop}"
    echo "  Version      : ${kiroVersion}"
    echo "  ISO label    : ${isoLabel}"
    echo "  NVIDIA driver: ${nvidia_driver}"
    echo "  Build folder : ${buildFolder}"
    echo "  Out folder   : ${outFolder}"
}

prepare_build_tree() {
    log_section "Phase 3 — Preparing build tree"

    remove_buildfolder yes
    mkdir -p "${buildFolder}"
    cp -r "${REPO_DIR}/archiso" "${buildFolder}/archiso"

    log_section "Phase 4 — Refreshing skel and package list"

    local skel_dir="${buildFolder}/archiso/airootfs/etc/skel"
    echo "Clearing skel..."
    find "${skel_dir}" -mindepth 1 -delete 2>/dev/null || true

    echo "Fetching latest .bashrc..."
    wget -q "https://raw.githubusercontent.com/erikdubois/edu-shells/refs/heads/main/etc/skel/.bashrc-latest" \
        -O "${skel_dir}/.bashrc" \
        || { log_error "Failed to download .bashrc from edu-shells"; exit 1; }

    echo "Refreshing packages.x86_64..."
    cp -f "${REPO_DIR}/archiso/packages.x86_64" "${PACKAGES_FILE}"
}

prepopulate_keyring() {
    log_section "Phase 5 — Prepopulating pacman keyring"

    local keyring_dir="${buildFolder}/archiso/airootfs/etc/pacman.d/gnupg"
    sudo pacman-key --gpgdir "${keyring_dir}" --init
    sudo pacman-key --gpgdir "${keyring_dir}" --populate archlinux
    sudo pacman-key --gpgdir "${keyring_dir}" --populate chaotic
    log_info "Keyring prepopulation complete"
}

inject_nvidia_packages() {
    log_section "Phase 6 — Injecting NVIDIA driver: ${nvidia_driver}"

    case "${nvidia_driver}" in
        open)
            sed -i '/^nvidia-580xx/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-390xx/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-open-dkms/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-utils/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-settings/d' "${PACKAGES_FILE}"
            printf 'nvidia-open-dkms\nnvidia-utils\nnvidia-settings\n' >> "${PACKAGES_FILE}"
            ;;
        580xx)
            sed -i '/^nvidia-open-dkms/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-utils/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-settings/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-580xx/d' "${PACKAGES_FILE}"
            printf 'nvidia-580xx-dkms\nnvidia-580xx-utils\nnvidia-580xx-settings\n' >> "${PACKAGES_FILE}"
            ;;
        390xx)
            sed -i '/^nvidia-open-dkms/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-utils/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-settings/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-390xx/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-580xx/d' "${PACKAGES_FILE}"
            printf 'nvidia-390xx-dkms\nnvidia-390xx-utils\nnvidia-390xx-settings\n' >> "${PACKAGES_FILE}"
            ;;
        *)
            log_error "Unknown NVIDIA driver option: ${nvidia_driver}\nValid options: open | 580xx | 390xx"
            exit 1
            ;;
    esac
}

stamp_build_date() {
    log_section "Phase 7 — Stamping build date"
    local date_build
    date_build=$(date -d now)
    echo "ISO build on: ${date_build}"
    sudo sed -i "s/\(^ISO_BUILD=\).*/\1${date_build}/" "${buildFolder}/archiso/airootfs/etc/dev-rel"
    clean_cache
}

build_iso() {
    log_section "Phase 8 — Running mkarchiso (this takes a while)"
    mkdir -p "${outFolder}"
    cd "${buildFolder}/archiso/"
    sudo mkarchiso -v -w "${buildFolder}" -o "${outFolder}" "${buildFolder}/archiso/"
}

create_checksums() {
    log_section "Phase 9 — Creating checksums and pkglist"
    cd "${outFolder}"

    echo "sha1sum..."
    sha1sum "${isoLabel}" | tee "${isoLabel}.sha1"
    echo "sha256sum..."
    sha256sum "${isoLabel}" | tee "${isoLabel}.sha256"
    echo "md5sum..."
    md5sum "${isoLabel}" | tee "${isoLabel}.md5"

    echo "Copying pkglist..."
    cp "${buildFolder}/iso/arch/pkglist.x86_64.txt" "${outFolder}/${isoLabel}.pkglist.txt"
}

#####################################################################
# Main
#####################################################################
main() {
    log_section "First run change-version.sh if you haven't already"

    check_not_root
    warn_btrfs
    setup_chaotic

    log_section "Phase 1 — Checking required packages"
    ensure_package archiso
    ensure_package grub
    show_overview

    prepare_build_tree
    prepopulate_keyring
    inject_nvidia_packages
    stamp_build_date
    build_iso
    create_checksums

    remove_buildfolder "${remove_build_folder}"

    log_success "$(basename "$0") done — ISO is in ${outFolder}"
}

main "$@"
