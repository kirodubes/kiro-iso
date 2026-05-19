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
# Run this script on an installed Kiro system to verify the install
# is correct. Add new checks over time. Run monthly.
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
# Counters
#####################################################################
PASS=0
FAIL=0
WARN=0

pass() { echo "  ${GREEN}PASS${RESET}  $1"; PASS=$((PASS + 1)); }
fail() { echo "  ${RED}FAIL${RESET}  $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ${YELLOW}WARN${RESET}  $1"; WARN=$((WARN + 1)); }

pkg_installed()  { pacman -Q "$1" &>/dev/null; }
pkg_missing()    { ! pacman -Q "$1" &>/dev/null; }

#####################################################################
# Functions
#####################################################################
check_kernel() {
    log_section "Kernel"

    local running
    running=$(uname -r)
    if [[ "${running}" == *lqx* ]]; then
        pass "Running kernel is linux-lqx: ${running}"
    else
        fail "Expected linux-lqx kernel, got: ${running}"
    fi

    [[ -f /boot/vmlinuz-linux-lqx ]]   && pass "/boot/vmlinuz-linux-lqx present"   || fail "/boot/vmlinuz-linux-lqx missing"
    [[ -f /boot/initramfs-linux-lqx.img ]] && pass "/boot/initramfs-linux-lqx.img present" || fail "/boot/initramfs-linux-lqx.img missing"
    pkg_installed linux-lqx            && pass "linux-lqx package installed"         || fail "linux-lqx package not installed"
    pkg_installed linux-lqx-headers    && pass "linux-lqx-headers installed"          || fail "linux-lqx-headers not installed"
}

check_microcode() {
    log_section "Microcode"

    if [[ -f /boot/intel-ucode.img ]]; then
        pass "intel-ucode.img present in /boot"
        pkg_missing amd-ucode && pass "amd-ucode not installed (Intel system)" || warn "amd-ucode also installed on Intel system"
    elif [[ -f /boot/amd-ucode.img ]]; then
        pass "amd-ucode.img present in /boot"
        pkg_missing intel-ucode && pass "intel-ucode not installed (AMD system)" || warn "intel-ucode also installed on AMD system"
    else
        fail "No microcode image found in /boot"
    fi
}

check_mkinitcpio() {
    log_section "mkinitcpio"

    local hooks
    hooks=$(grep '^HOOKS=' /etc/mkinitcpio.conf | head -1)

    # Must NOT have archiso hook
    if echo "${hooks}" | grep -q 'archiso'; then
        fail "archiso hook still present in mkinitcpio.conf HOOKS"
    else
        pass "No archiso hook in mkinitcpio.conf"
    fi

    # Must have microcode and kms
    echo "${hooks}" | grep -q 'microcode' && pass "microcode hook present" || fail "microcode hook missing from HOOKS"
    echo "${hooks}" | grep -q 'kms'       && pass "kms hook present"       || fail "kms hook missing from HOOKS"

    # Only linux-lqx preset, no plain linux preset
    [[ -f /etc/mkinitcpio.d/linux-lqx.preset ]] && pass "linux-lqx.preset exists"                     || fail "linux-lqx.preset missing"
    [[ -f /etc/mkinitcpio.d/linux.preset ]]      && fail "linux.preset leftover not cleaned up"        || pass "linux.preset leftover not present (good)"
}

check_audio() {
    log_section "Audio stack"

    for pkg in pipewire pipewire-alsa pipewire-audio pipewire-pulse wireplumber; do
        pkg_installed "${pkg}" && pass "${pkg} installed" || fail "${pkg} missing"
    done

    pkg_missing pulseaudio && pass "pulseaudio not installed (good)" || fail "pulseaudio still installed — conflicts with PipeWire"
}

check_calamares_cleanup() {
    log_section "Calamares cleanup"

    pkg_missing calamares              && pass "calamares binary removed"              || fail "calamares still installed"
    pkg_missing mkinitcpio-archiso     && pass "mkinitcpio-archiso removed"            || fail "mkinitcpio-archiso still installed"
    pkg_missing memtest86+             && pass "memtest86+ removed"                    || warn "memtest86+ still installed"
    if pkg_missing kiro-calamares-config; then
        pass "kiro-calamares-config removed"
        [[ -d /etc/calamares ]] && warn "/etc/calamares config dir still present after package removal" || pass "/etc/calamares directory removed"
    else
        fail "kiro-calamares-config still installed (kiro_final removal step failed)"
    fi

    # kiro_final live-only artifact cleanup
    [[ -f /root/.automated_script.sh ]]              && fail "/root/.automated_script.sh archiso leftover present"    || pass "No /root/.automated_script.sh (good)"
    [[ -f /root/.zlogin ]]                           && fail "/root/.zlogin archiso leftover present"                 || pass "No /root/.zlogin (good)"
    [[ -d /etc/systemd/system/getty@tty1.service.d ]] && fail "getty@tty1 autologin not cleaned up"                  || pass "getty@tty1 autologin removed (good)"
    [[ -f /etc/sudoers.d/g_wheel ]]                  && fail "/etc/sudoers.d/g_wheel live-only rule still present"   || pass "/etc/sudoers.d/g_wheel removed (good)"
    [[ -f /etc/polkit-1/rules.d/49-nopasswd_global.rules ]] && fail "49-nopasswd_global.rules live-only rule still present" || pass "49-nopasswd_global.rules removed (good)"
}

check_kiro_final_config() {
    log_section "kiro_final configuration"

    # /root permissions
    local root_perm
    root_perm=$(stat -c '%a' /root 2>/dev/null)
    [[ "${root_perm}" == "700" ]] && pass "/root permissions: 700" || fail "/root permissions wrong: ${root_perm} (expected 700)"

    # sudoers.d permissions
    local sudoers_perm
    sudoers_perm=$(stat -c '%a' /etc/sudoers.d 2>/dev/null)
    [[ "${sudoers_perm}" == "750" ]] && pass "/etc/sudoers.d permissions: 750" || fail "/etc/sudoers.d permissions wrong: ${sudoers_perm} (expected 750)"

    # polkit-1/rules.d permissions
    local polkit_perm
    polkit_perm=$(stat -c '%a' /etc/polkit-1/rules.d 2>/dev/null || echo "missing")
    [[ "${polkit_perm}" == "750" ]] && pass "/etc/polkit-1/rules.d permissions: 750" || fail "/etc/polkit-1/rules.d permissions wrong: ${polkit_perm} (expected 750)"

    # EDITOR=nano in /etc/profile
    grep -q 'EDITOR=nano' /etc/profile 2>/dev/null && pass "EDITOR=nano set in /etc/profile" || fail "EDITOR=nano not set in /etc/profile"

    # Bluetooth AutoEnable
    grep -q '^AutoEnable=true' /etc/bluetooth/main.conf 2>/dev/null && pass "Bluetooth AutoEnable=true" || warn "Bluetooth AutoEnable not set (no Bluetooth hardware?)"

    # makepkg.conf optimizations (kiro_before)
    grep -q '^MAKEFLAGS="-j' /etc/makepkg.conf 2>/dev/null && pass "makepkg.conf MAKEFLAGS set" || fail "makepkg.conf MAKEFLAGS not optimized"
    grep -q "^PKGEXT='.pkg.tar.zst'" /etc/makepkg.conf 2>/dev/null && pass "makepkg.conf PKGEXT=.pkg.tar.zst" || fail "makepkg.conf PKGEXT not set to .pkg.tar.zst"
    grep -qP '^OPTIONS=.*!debug' /etc/makepkg.conf 2>/dev/null && pass "makepkg.conf !debug in OPTIONS" || fail "makepkg.conf debug not disabled in OPTIONS"
}

check_pacman_repos() {
    log_section "Pacman repositories"

    grep -q '^\[nemesis_repo\]' /etc/pacman.conf && pass "nemesis_repo in pacman.conf" || fail "nemesis_repo missing from pacman.conf"
    grep -q '^\[chaotic-aur\]'  /etc/pacman.conf && pass "chaotic-aur in pacman.conf"  || fail "chaotic-aur missing from pacman.conf"
    grep -q '^\[multilib\]'     /etc/pacman.conf && pass "multilib in pacman.conf"     || warn "multilib missing from pacman.conf"
}

check_desktop() {
    log_section "Desktop environments"

    pkg_installed ohmychadwm-git && pass "ohmychadwm-git installed" || fail "ohmychadwm-git not installed"
    pkg_installed xfwm4           && pass "xfwm4 installed"          || fail "xfwm4 not installed"
    pkg_missing   edu-chadwm      && pass "edu-chadwm not installed (dropped)" || warn "edu-chadwm still installed — should be removed"

    [[ -f /usr/share/xsessions/ohmychadwm.desktop ]] && pass "ohmychadwm.desktop session file present" || fail "ohmychadwm.desktop missing"
    [[ -f /usr/share/xsessions/xfce.desktop ]]       && pass "xfce.desktop session file present"       || fail "xfce.desktop missing"
}

check_sddm() {
    log_section "SDDM"

    pkg_installed sddm && pass "sddm installed" || fail "sddm not installed"
    systemctl is-enabled sddm &>/dev/null && pass "sddm.service enabled" || fail "sddm.service not enabled"

    if grep -q 'edu-simplicity' /etc/sddm.conf.d/*.conf 2>/dev/null || grep -q 'edu-simplicity' /etc/sddm.conf 2>/dev/null; then
        pass "SDDM theme set to edu-simplicity"
    else
        warn "SDDM theme not set to edu-simplicity"
    fi
}

check_user_groups() {
    log_section "User groups"

    local user
    user=$(getent passwd 1000 | cut -d: -f1)
    if [[ -z "${user}" ]]; then
        warn "No user with UID 1000 found — skipping group checks"
        return
    fi

    log_info "Checking groups for user: ${user}"
    local groups
    groups=$(groups "${user}")

    for grp in wheel audio video storage optical network; do
        echo "${groups}" | grep -q "${grp}" && pass "${user} in group: ${grp}" || fail "${user} not in group: ${grp}"
    done
}

check_services() {
    log_section "Systemd services"

    for svc in NetworkManager sddm bluetooth; do
        systemctl is-enabled "${svc}" &>/dev/null && pass "${svc} enabled" || warn "${svc} not enabled"
    done

    # These should NOT be enabled on installed system
    systemctl is-enabled pacman-init &>/dev/null && fail "pacman-init still enabled (archiso leftover)" || pass "pacman-init not enabled (good)"
    systemctl is-enabled reflector   &>/dev/null && warn "reflector enabled (was this intentional?)" || true
}

check_permissions() {
    log_section "Key file permissions"

    local shadow_perm gshadow_perm
    shadow_perm=$(stat -c '%a' /etc/shadow   2>/dev/null || echo "missing")
    gshadow_perm=$(stat -c '%a' /etc/gshadow 2>/dev/null || echo "missing")

    [[ "${shadow_perm}"  == "400" ]] && pass "/etc/shadow permissions: 400"   || fail "/etc/shadow permissions wrong: ${shadow_perm} (expected 400)"
    [[ "${gshadow_perm}" == "400" ]] && pass "/etc/gshadow permissions: 400"  || fail "/etc/gshadow permissions wrong: ${gshadow_perm} (expected 400)"
}

check_dev_rel() {
    log_section "ISO version"

    if [[ -f /etc/dev-rel ]]; then
        pass "/etc/dev-rel present"
        echo "  ${CYAN}INFO${RESET}  $(cat /etc/dev-rel)"
    else
        fail "/etc/dev-rel missing"
    fi
}

check_nvidia() {
    log_section "NVIDIA"

    if lspci 2>/dev/null | grep -qi nvidia; then
        log_info "NVIDIA GPU detected"
        pkg_installed nvidia-open-dkms  && pass "nvidia-open-dkms installed"  || warn "NVIDIA GPU present but nvidia-open-dkms not installed"
        pkg_installed nvidia-utils       && pass "nvidia-utils installed"       || warn "nvidia-utils not installed"
    else
        pass "No NVIDIA GPU detected — DKMS packages not expected"
        pkg_missing nvidia-open-dkms && pass "nvidia-open-dkms not installed (no GPU, good)" || warn "nvidia-open-dkms installed but no NVIDIA GPU detected"
    fi
}

check_package_integrity() {
    log_section "Package integrity (pacman -Qk)"

    local missing
    missing=$(pacman -Qk 2>/dev/null \
        | grep -v ' 0 missing files$' \
        | grep 'missing files' \
        | grep -v '^ohmychadwm-git:' \
        | grep -v '^bind:' \
        | grep -v '^cups:' \
        | grep -v '^nfs-utils:') || true

    if [[ -z "${missing}" ]]; then
        pass "All packages have no missing files"
    else
        fail "Packages with missing files:"
        echo "${missing}" | while read -r line; do
            echo "        ${line}"
        done
    fi
}

check_bootloader() {
    log_section "Bootloader"

    if [[ -d /sys/firmware/efi ]]; then
        pass "System booted via UEFI"
        if command -v bootctl &>/dev/null && efibootmgr 2>/dev/null | grep -qi 'Linux Boot Manager'; then
            pass "systemd-boot is installed"
        elif [[ -d /boot/grub ]]; then
            pass "GRUB EFI bootloader detected"
        else
            warn "UEFI system but bootloader type unclear"
        fi
    else
        pass "System booted via BIOS"
        [[ -d /boot/grub ]] && pass "GRUB BIOS bootloader detected" || warn "BIOS system but no GRUB found"
    fi
}

#####################################################################
# Main
#####################################################################
main() {
    log_section "Kiro ISO — Installed System Audit"
    echo "  Host   : $(hostname)"
    echo "  Kernel : $(uname -r)"
    echo "  Date   : $(date)"

    check_kernel
    check_microcode
    check_mkinitcpio
    check_audio
    check_calamares_cleanup
    check_kiro_final_config
    check_pacman_repos
    check_desktop
    check_sddm
    check_user_groups
    check_services
    check_permissions
    check_dev_rel
    check_nvidia
    check_bootloader
    check_package_integrity

    log_section "Audit Summary"
    echo "  ${GREEN}PASS: ${PASS}${RESET}"
    echo "  ${YELLOW}WARN: ${WARN}${RESET}"
    echo "  ${RED}FAIL: ${FAIL}${RESET}"
    echo

    if [[ ${FAIL} -gt 0 ]]; then
        log_error "Audit completed with ${FAIL} failure(s)"
        exit 1
    elif [[ ${WARN} -gt 0 ]]; then
        log_warn "Audit completed with ${WARN} warning(s)"
    else
        log_success "$(basename "$0") — all checks passed"
    fi
}

main "$@"
