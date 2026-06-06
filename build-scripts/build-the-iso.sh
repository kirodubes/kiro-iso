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
kiroVersion='v26.06.06'
bump_version="yes"            # yes | no — bump version to vYY.MM.DD before building; set to no for same-day rebuilds
nvidia_driver="open"          # open | 580xx | 390xx
kernel="linux-cachyos linux-zen"   # space-separated kernel package(s); "ask" = interactive menu. First = the kernel the live ISO boots.
picker="auto"                 # auto | dialog | gum — picker UI for kernel="ask" (auto = dialog if installed, else gum)
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
    wget -q "https://raw.githubusercontent.com/kirodubes/kiro-shells/refs/heads/main/etc/skel/.bashrc-latest" \
        -O "${skel_dir}/.bashrc" \
        || { log_error "Failed to download .bashrc from kiro-shells"; exit 1; }

    echo "Refreshing packages.x86_64..."
    cp -f "${REPO_DIR}/archiso/packages.x86_64" "${PACKAGES_FILE}"
}

prepopulate_keyring() {
    log_section "Phase 5 — Prepopulating pacman keyring"

    local keyring_dir="${buildFolder}/archiso/airootfs/etc/pacman.d/gnupg"
    sudo pacman-key --gpgdir "${keyring_dir}" --init
    sudo pacman-key --gpgdir "${keyring_dir}" --populate archlinux
    sudo pacman-key --gpgdir "${keyring_dir}" --populate chaotic
    sudo pacman-key --gpgdir "${keyring_dir}" --populate cachyos
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
KERNEL_CANDIDATES=(linux linux-lts linux-zen linux-hardened linux-rt linux-rt-lts linux-mainline)
CANONICAL_KERNEL="linux-cachyos"   # the kernel token the repo's archiso tree ships by default
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

    # Plus every flavor of the multi-variant families the repos offer — CachyOS,
    # XanMod, and the pinned-LTS series — discovered dynamically so the list never
    # goes stale as new flavors land. The "<name>-headers exists" test filters out
    # non-kernel companion packages (zfs, nvidia, etc.). We deliberately do NOT
    # match the CPU-microarch builds (linux-x64v*, linux-znver*) or niche kernels
    # (cjktty, nitrous, tachyon, vfio): low demand, and the microarch ones silently
    # fail to boot on the wrong CPU level — a bad default for a general ISO.
    local c
    while IFS= read -r c; do
        [[ -z "${c}" || "${c}" == *-headers ]] && continue
        pacman -Si "${c}-headers" &>/dev/null || continue
        [[ " ${AVAILABLE_KERNELS[*]} " == *" ${c} "* ]] && continue
        AVAILABLE_KERNELS+=("${c}")
    done < <(pacman -Slq 2>/dev/null | grep -E '^(linux-cachyos|linux-xanmod|linux-lts[0-9])' || true)
}

select_kernels() {
    log_section "Selecting kernel(s)"

    case "${picker}" in
        auto|gum|dialog) ;;
        *) log_error "Invalid picker='${picker}'. Valid options: auto | gum | dialog"; exit 1 ;;
    esac

    # Fixed kernel(s): validate only the named package(s) — no full repo enumeration.
    if [[ "${kernel}" != "ask" ]]; then
        read -ra SELECTED_KERNELS <<< "${kernel}"
        local bad
        for bad in "${SELECTED_KERNELS[@]}"; do
            if ! pacman -Si "${bad}" &>/dev/null || ! pacman -Si "${bad}-headers" &>/dev/null; then
                detect_available_kernels   # only on a bad name, to suggest valid ones
                log_error "Unknown kernel '${bad}' — no '${bad}' + '${bad}-headers' in the enabled repos.
Use kernel=\"ask\" to pick interactively, or one of these:
$(printf '  %s\n' "${AVAILABLE_KERNELS[@]}")"
                exit 1
            fi
        done
        PRIMARY_KERNEL="${SELECTED_KERNELS[0]}"
        log_info "Kernel(s) from config: ${SELECTED_KERNELS[*]} (live boot: ${PRIMARY_KERNEL})"
        return 0
    fi

    # kernel="ask": enumerate the kernels the enabled repos offer, for the menu.
    detect_available_kernels
    if [[ "${#AVAILABLE_KERNELS[@]}" -eq 0 ]]; then
        log_error "No kernels with a matching -headers package found in the enabled repos"
        exit 1
    fi

    # Picker UI for kernel="ask": gum (truecolor Arc Dark) or dialog. "auto" = dialog if installed, else gum.
    case "${picker}" in
        gum)
            command -v gum &>/dev/null || { log_error "picker=gum but gum is not installed"; exit 1; }
            _select_kernels_gum ;;
        dialog) _select_kernels_dialog ;;
        auto)   if command -v dialog &>/dev/null; then _select_kernels_dialog; else _select_kernels_gum; fi ;;
    esac

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

    # Zen fallback entries: keep only if linux-zen is in SELECTED_KERNELS, else strip them.
    # The boot menus include a "fallback kernel linux-zen" entry in 04-fallback-zen.conf
    # and inside KIRO_ZEN_FALLBACK markers in syslinux/grub configs — these reference
    # vmlinuz-linux-zen, so they're dead entries unless linux-zen is installed.
    if [[ ! " ${SELECTED_KERNELS[*]} " == *" linux-zen "* ]]; then
        log_info "linux-zen not selected — stripping zen fallback entries from boot configs"
        rm -f "${buildFolder}/archiso/efiboot/loader/entries/04-fallback-zen.conf"
        local zf
        for zf in \
            "${buildFolder}"/archiso/syslinux/archiso_sys-linux.cfg \
            "${buildFolder}"/archiso/grub/grub.cfg; do
            [[ -f "${zf}" ]] && sed -i '/KIRO_ZEN_FALLBACK_BEGIN/,/KIRO_ZEN_FALLBACK_END/d' "${zf}"
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

record_build_time() {
    # Append a row to ../BUILD_TIMES.md ## ISO Builds with this build's
    # duration, kernel(s), live squashfs setting, and ISO size. Non-fatal —
    # failure here logs a warning but doesn't abort the build.
    #
    # Hostname gate: only run on Erik's dev box ('hq'). End users who clone
    # kiro-iso and run build-the-iso.sh shouldn't end up with a dirty
    # working tree from a row they don't care about — they hit this early
    # return silently. Erik's machine is the only one that ever builds the
    # canonical ISO, so this is a safe identity check.
    if [[ "$(hostname)" != "hq" ]]; then
        return 0
    fi

    [[ -z "${build_start_epoch:-}" ]] && { log_warn "record_build_time: build_start_epoch unset — skipping"; return 0; }

    local end_epoch duration mins secs stamp iso_file iso_size compression kernels_used row btf tmp
    end_epoch=$(date +%s)
    duration=$((end_epoch - build_start_epoch))
    mins=$((duration / 60))
    secs=$((duration % 60))
    stamp="$(date '+%Y-%m-%d %H:%M')"

    iso_file="$(ls -1t "${outFolder}"/*.iso 2>/dev/null | head -1)"
    iso_size="$(du -h "${iso_file}" 2>/dev/null | cut -f1)"

    # Squashfs setting read live from profiledef.sh so we always log what
    # the build actually used, not a stale constant.
    compression="$(grep -E '^airootfs_image_tool_options=' "${REPO_DIR}/archiso/profiledef.sh" 2>/dev/null \
        | sed -E "s/.*'-comp' '([^']+)'.*-Xcompression-level' '([0-9]+)'.*'-b' '([^']+)'.*/\\1 L\\2 -b \\3/")"
    compression="${compression:-?}"

    # Prefer SELECTED_KERNELS (what the build actually shipped, in order)
    # over the kernel= config value (which is "ask" in interactive mode).
    if [[ ${#SELECTED_KERNELS[@]} -gt 0 ]]; then
        kernels_used="${SELECTED_KERNELS[*]}"
    else
        kernels_used="${kernel}"
    fi

    row="| ${stamp} | ${kiroVersion} | ${kernels_used} | ${compression} | ${mins}m${secs}s | ${iso_size:-?} | |"
    btf="${REPO_DIR}/BUILD_TIMES.md"

    if [[ ! -f "${btf}" ]] || ! grep -q '^## ISO Builds$' "${btf}"; then
        log_warn "BUILD_TIMES.md missing or malformed — skipping time record (would have been: ${row})"
        return 0
    fi

    # Insert the new row right after the |--- separator line inside the
    # ## ISO Builds section. awk gives us a safe in-section anchor.
    tmp="$(mktemp)"
    awk -v row="${row}" '
        /^## ISO Builds$/ { in_section = 1 }
        /^## / && !/^## ISO Builds$/ { in_section = 0 }
        { print }
        /^\|---/ && in_section && !injected { print row; injected = 1 }
    ' "${btf}" > "${tmp}" && mv "${tmp}" "${btf}"

    log_info "Build time recorded in BUILD_TIMES.md — ${mins}m${secs}s, ${iso_size:-?} ISO"
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
    local build_start_epoch
    build_start_epoch=$(date +%s)

    check_not_root
    warn_btrfs
    setup_chaotic

    apply_version_bump
    verify_version_sync

    if [[ "$(hostname)" == "hq" ]]; then
        log_section "Phase 2c — Refreshing skel .bashrc from kiro-shells"
        local skel_dir="${REPO_DIR}/archiso/airootfs/etc/skel"
        local skel_bashrc="${skel_dir}/.bashrc"
        local skel_bashrc_latest="${skel_dir}/.bashrc-latest"
        local edu_bashrc_latest="${HOME}/KIRO/kiro-shells/etc/skel/.bashrc-latest"
        # Pull the latest .bashrc-latest in, drop the old .bashrc, then promote the
        # fresh copy into its place so skel always ships the current kiro-shells .bashrc.
        if [[ -f "${edu_bashrc_latest}" ]]; then
            cp "${edu_bashrc_latest}" "${skel_bashrc_latest}"
            rm -f "${skel_bashrc}"
            mv "${skel_bashrc_latest}" "${skel_bashrc}"
            status_ok "${GREEN}.bashrc refreshed from kiro-shells${RESET}"
        else
            log_warn "kiro-shells .bashrc-latest not found at ${edu_bashrc_latest}"
        fi
    fi

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

    record_build_time

    log_success "$(basename "$0") done — ISO is in ${outFolder}"
}

main "$@"
