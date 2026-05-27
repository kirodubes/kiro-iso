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

status_ok() {
    echo "${GREEN}[ OK ]${RESET}  $1"
}

status_nok() {
    echo "${RED}[ NOK ]${RESET} $1"
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
desktop="xfce4/ohmychadwm"
kiroVersion='v26.05.27'
bump_version="yes"            # yes | no — bump version to vYY.MM.DD before building; set to no for same-day rebuilds
nvidia_driver="open"          # open | 580xx | 390xx
#kernel="linux-lqx"            # space-separated kernel package(s); "ask" = interactive dialog menu. First = the kernel the live ISO boots.
kernel="ask"            # space-separated kernel package(s); "ask" = interactive dialog menu. First = the kernel the live ISO boots.
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
apply_version_bump() {
    if [[ "${bump_version}" != "yes" ]]; then
        log_info "Skipping version bump (bump_version=no) — building ${kiroVersion}"
        return 0
    fi

    local newversion
    newversion="v$(date +%y.%m.%d)"

    log_section "Phase 2 — Bumping version to ${newversion}"

    local devrel="${REPO_DIR}/archiso/airootfs/etc/dev-rel"
    local buildiso="${SCRIPT_DIR}/build-the-iso.sh"
    local profiledef="${REPO_DIR}/archiso/profiledef.sh"

    echo "Updating ${devrel}"
    sed -i "s|^ISO_RELEASE=.*|ISO_RELEASE=${newversion}|" "${devrel}"

    echo "Updating ${buildiso}"
    # Anchored to ^ so this only rewrites the config-block assignment, never this sed line itself
    sed -i "s|^kiroVersion='[^']*'|kiroVersion='${newversion}'|" "${buildiso}"

    echo "Updating iso_label in ${profiledef}"
    sed -i "s|^iso_label=\"kiro-.*\"|iso_label=\"kiro-${newversion}\"|" "${profiledef}"

    echo "Updating iso_version in ${profiledef}"
    sed -i "s|^iso_version=\"v.*\"|iso_version=\"${newversion}\"|" "${profiledef}"

    # Re-derive in-memory values so this build uses the freshly bumped version
    kiroVersion="${newversion}"
    isoLabel="kiro-${kiroVersion}-x86_64.iso"

    log_info "Version bump summary:
  dev-rel     : $(grep '^ISO_RELEASE=' "${devrel}")
  build-iso   : $(grep '^kiroVersion=' "${buildiso}")
  profiledef  : $(grep '^iso_label=' "${profiledef}") / $(grep '^iso_version=' "${profiledef}")"
}

verify_version_sync() {
    # Confirms dev-rel, profiledef.sh and build-the-iso.sh all carry ${kiroVersion}.
    # Matters most for bump_version=no rebuilds, where drift silently survives.
    log_section "Phase 2b — Verifying version files are in sync"

    local devrel="${REPO_DIR}/archiso/airootfs/etc/dev-rel"
    local profiledef="${REPO_DIR}/archiso/profiledef.sh"
    local buildiso="${SCRIPT_DIR}/build-the-iso.sh"

    local devrel_ver prof_version prof_label prof_name build_ver
    devrel_ver=$(grep -oP '^ISO_RELEASE=\K.*'        "${devrel}")
    prof_version=$(grep -oP '^iso_version="\K[^"]*'  "${profiledef}")
    prof_label=$(grep -oP '^iso_label="\K[^"]*'      "${profiledef}")
    prof_name=$(grep -oP '^iso_name="\K[^"]*'        "${profiledef}")
    build_ver=$(grep -oP "^kiroVersion='\K[^']*"     "${buildiso}")

    local expected="${kiroVersion}"
    local errors=()

    [[ "${devrel_ver}" == "${expected}" ]]              || errors+=("dev-rel ISO_RELEASE='${devrel_ver}'")
    [[ "${prof_version}" == "${expected}" ]]            || errors+=("profiledef iso_version='${prof_version}'")
    [[ "${build_ver}" == "${expected}" ]]               || errors+=("build-the-iso kiroVersion='${build_ver}'")
    [[ "${prof_label}" == "${prof_name}-${expected}" ]] || errors+=("profiledef iso_label='${prof_label}' (expected '${prof_name}-${expected}')")

    if (( ${#errors[@]} > 0 )); then
        log_error "Version files out of sync — expected '${expected}' everywhere:
$(printf '  - %s\n' "${errors[@]}")
Fix the files above, or set bump_version=yes to re-stamp them, then re-run."
        exit 1
    fi

    log_info "Version files in sync: ${expected}"
}

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
            status_ok "Build folder present — proceeding to delete"
            log_warn "Deleting build folder: ${buildFolder}"
            sudo rm -rf "${buildFolder}"
        else
            status_nok "Build folder not found — nothing to delete"
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

files_are_identical() {
    # Reports whether two files are a byte-for-byte exact copy. Returns 0 when
    # identical, non-zero otherwise — meant to be used in an `if`, not bare.
    local src="$1"
    local dst="$2"

    if [[ ! -f "${src}" ]]; then
        status_nok "Source file missing: ${src}"
        return 1
    fi
    if [[ ! -f "${dst}" ]]; then
        status_nok "Compare target missing: ${dst}"
        return 1
    fi

    if cmp -s "${src}" "${dst}"; then
        status_ok "Identical:
        ${src}
        == ${dst}"
        return 0
    fi

    status_nok "Differ:
        ${src}
        != ${dst}"
    return 1
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
    echo "  Kernel(s)    : ${SELECTED_KERNELS[*]} (live boot: ${PRIMARY_KERNEL})"
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

#####################################################################
# Kernel selection — keeps the ISO independent of any one kernel.
# The repo ships ${CANONICAL_KERNEL} as its default; this rewrites the
# build-tree copies to whatever the user picks. Pairs with the calamares
# kiro_kernel module, which installs whatever kernel(s) the ISO ships.
#####################################################################
KERNEL_CANDIDATES=(linux linux-lts linux-zen linux-hardened linux-rt linux-rt-lts linux-lqx linux-cachyos linux-xanmod)
CANONICAL_KERNEL="linux-lqx"   # the kernel token the repo's archiso tree ships by default
AVAILABLE_KERNELS=()
SELECTED_KERNELS=()
PRIMARY_KERNEL=""

detect_available_kernels() {
    AVAILABLE_KERNELS=()
    local k
    for k in "${KERNEL_CANDIDATES[@]}"; do
        # Only offer a kernel if both it and its -headers exist in the enabled repos
        # (-headers is required for the DKMS NVIDIA drivers to build).
        if pacman -Si "${k}" &>/dev/null && pacman -Si "${k}-headers" &>/dev/null; then
            AVAILABLE_KERNELS+=("${k}")
        fi
    done

    # Plus EVERY CachyOS kernel flavor the enabled repos offer. CachyOS kernels
    # topped our benchmark study (see KERNEL_COMPARISON), so expose them all and
    # discover dynamically rather than hardcode a list that goes stale as new
    # flavors appear. The "<name>-headers exists" test filters out non-kernel
    # companion packages (zfs, nvidia, etc.).
    local c
    while IFS= read -r c; do
        [[ -z "${c}" || "${c}" == *-headers ]] && continue
        pacman -Si "${c}-headers" &>/dev/null || continue
        [[ " ${AVAILABLE_KERNELS[*]} " == *" ${c} "* ]] && continue
        AVAILABLE_KERNELS+=("${c}")
    done < <(pacman -Slq 2>/dev/null | grep -E '^linux-cachyos' || true)
}

select_kernels() {
    log_section "Selecting kernel(s)"

    if [[ "${kernel}" != "ask" ]]; then
        read -ra SELECTED_KERNELS <<< "${kernel}"
        PRIMARY_KERNEL="${SELECTED_KERNELS[0]}"
        log_info "Kernel(s) from config: ${SELECTED_KERNELS[*]} (live boot: ${PRIMARY_KERNEL})"
        return 0
    fi

    detect_available_kernels
    if [[ "${#AVAILABLE_KERNELS[@]}" -eq 0 ]]; then
        log_error "No kernels with a matching -headers package found in the enabled repos"
        exit 1
    fi

    # gum gives a truecolor, Arc-Dark-themed picker; fall back to dialog on a bare host.
    if command -v gum &>/dev/null; then
        _select_kernels_gum
    else
        _select_kernels_dialog
    fi

    if [[ "${#SELECTED_KERNELS[@]}" -eq 0 || -z "${PRIMARY_KERNEL}" ]]; then
        log_error "No kernel selected — aborting"
        exit 1
    fi
    log_info "Selected kernel(s): ${SELECTED_KERNELS[*]} (live boot: ${PRIMARY_KERNEL})"
}

_select_kernels_gum() {
    # Arc Dark (truecolor): blue accent #5294e2, text #d3dae3, muted header #8b9bb4.
    local blue="#5294e2" text="#d3dae3" muted="#8b9bb4" selection k
    selection="$(gum choose --no-limit --height 12 \
        --header "Kiro ISO builder · select kernel(s) to install" \
        --selected "${CANONICAL_KERNEL}" \
        --cursor.foreground "${blue}" --selected.foreground "${blue}" \
        --item.foreground "${text}" --header.foreground "${muted}" \
        "${AVAILABLE_KERNELS[@]}")" \
        || { log_error "Kernel selection cancelled — aborting"; exit 1; }

    SELECTED_KERNELS=()
    while IFS= read -r k; do
        [[ -n "${k}" ]] && SELECTED_KERNELS+=("${k}")
    done <<< "${selection}"
    if [[ "${#SELECTED_KERNELS[@]}" -le 1 ]]; then
        PRIMARY_KERNEL="${SELECTED_KERNELS[0]:-}"
        return 0
    fi

    PRIMARY_KERNEL="$(gum choose --height 10 \
        --header "Which kernel should the LIVE ISO boot?" \
        --cursor.foreground "${blue}" --selected.foreground "${blue}" \
        --item.foreground "${text}" --header.foreground "${muted}" \
        "${SELECTED_KERNELS[@]}")" \
        || { log_error "Primary-kernel selection cancelled — aborting"; exit 1; }
}

_select_kernels_dialog() {
    ensure_package dialog
    [[ -f "${SCRIPT_DIR}/kiro.dialogrc" ]] && export DIALOGRC="${SCRIPT_DIR}/kiro.dialogrc"

    local items=() k ver state
    for k in "${AVAILABLE_KERNELS[@]}"; do
        ver="$(pacman -Si "${k}" 2>/dev/null | awk -F': *' '/^Version/{print $2; exit}')"
        state="off"; [[ "${k}" == "${CANONICAL_KERNEL}" ]] && state="on"
        items+=("${k}" "${ver}" "${state}")
    done

    local selection
    selection="$(dialog --stdout --backtitle "Kiro ISO builder" --title "Select kernel(s)" --checklist \
        "Select kernel(s) to install on the ISO (the live-boot kernel is chosen next):" \
        20 76 12 "${items[@]}")" \
        || { clear; log_error "Kernel selection cancelled — aborting"; exit 1; }
    clear

    read -ra SELECTED_KERNELS <<< "${selection}"
    if [[ "${#SELECTED_KERNELS[@]}" -le 1 ]]; then
        PRIMARY_KERNEL="${SELECTED_KERNELS[0]:-}"
        return 0
    fi

    local ritems=() rstate
    for k in "${SELECTED_KERNELS[@]}"; do
        rstate="off"; [[ "${k}" == "${SELECTED_KERNELS[0]}" ]] && rstate="on"
        ritems+=("${k}" "" "${rstate}")
    done
    PRIMARY_KERNEL="$(dialog --stdout --backtitle "Kiro ISO builder" --title "Live-boot kernel" --radiolist \
        "Which kernel should the LIVE ISO boot?" 18 70 10 "${ritems[@]}")" \
        || { clear; log_error "Primary-kernel selection cancelled — aborting"; exit 1; }
    clear
}

apply_kernel() {
    log_section "Phase 6b — Applying kernel(s): ${SELECTED_KERNELS[*]} (live boot: ${PRIMARY_KERNEL})"

    # packages.x86_64: drop the canonical kernel + headers, then add every selected kernel + its headers
    sed -i "/^${CANONICAL_KERNEL}\$/d;/^${CANONICAL_KERNEL}-headers\$/d" "${PACKAGES_FILE}"
    local k
    for k in "${SELECTED_KERNELS[@]}"; do
        sed -i "/^${k}\$/d;/^${k}-headers\$/d" "${PACKAGES_FILE}"
        printf '%s\n%s-headers\n' "${k}" "${k}" >> "${PACKAGES_FILE}"
    done

    # boot entries + live presets reference a single kernel — the primary
    if [[ "${PRIMARY_KERNEL}" != "${CANONICAL_KERNEL}" ]]; then
        local f
        for f in \
            "${buildFolder}"/archiso/efiboot/loader/entries/*.conf \
            "${buildFolder}"/archiso/syslinux/archiso_sys-linux.cfg \
            "${buildFolder}"/archiso/syslinux/archiso_pxe-linux.cfg \
            "${buildFolder}"/archiso/grub/grub.cfg \
            "${buildFolder}"/archiso/grub/loopback.cfg \
            "${buildFolder}"/archiso/airootfs/etc/mkinitcpio.d/kiro \
            "${buildFolder}"/archiso/airootfs/etc/mkinitcpio.d/linux.preset; do
            [[ -f "${f}" ]] && sed -i "s/${CANONICAL_KERNEL}/${PRIMARY_KERNEL}/g" "${f}"
        done
    fi
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
    check_not_root
    warn_btrfs
    setup_chaotic

    apply_version_bump
    verify_version_sync

    log_section "Phase 2c — Comparing skel .bashrc with edu-shells"
    # Informational only — print the colored OK/NOK and keep going regardless.
    files_are_identical \
        "${REPO_DIR}/archiso/airootfs/etc/skel/.bashrc" \
        "${HOME}/EDU/edu-shells/etc/skel/.bashrc-latest" || true

    log_section "Phase 1 — Checking required packages"
    ensure_package archiso
    ensure_package grub
    select_kernels
    show_overview

    prepare_build_tree
    prepopulate_keyring
    inject_nvidia_packages
    apply_kernel
    stamp_build_date
    build_iso
    create_checksums

    remove_buildfolder "${remove_build_folder}"

    log_success "$(basename "$0") done — ISO is in ${outFolder}"
}

main "$@"
