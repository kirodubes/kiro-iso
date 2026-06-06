#!/bin/bash
#####################################################################
# Author    : Erik Dubois
# Website   : https://kiroproject.be
#####################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
#   Purpose:
#   Host-preparation helpers for the Kiro ISO build. This file is
#   SOURCED by build-the-iso.sh — it defines functions only and has
#   no main(). It makes the build self-contained on any Arch-based
#   host (Arch, Kiro, EndeavourOS, CachyOS, Garuda) by ensuring the
#   extra repositories mkarchiso needs are present before the build:
#     - archiso/grub             (ensure_package)
#     - chaotic-aur keyring+mirrorlist
#     - cachyos keyring+mirrorlist   (linux-cachyos lives here)
#
#   Why: archiso/pacman.conf pulls from [chaotic-aur] and [cachyos],
#   and prepopulate_keyring runs `pacman-key --populate cachyos`. A
#   host that lacks the cachyos keyring/mirrorlist fails the build.
#   Every function below is idempotent — already-configured hosts are
#   detected and skipped — so the procedure is identical everywhere:
#   the user only ever runs ./build.sh.
#
#   Requires: must be sourced by a script that provides the log_*
#   helpers and colour variables (build-the-iso.sh does).
#
#####################################################################

# Load-once guard — safe to source multiple times.
[[ -n "${HOST_PREP_SH_LOADED:-}" ]] && return 0
HOST_PREP_SH_LOADED=1

#####################################################################
# Functions
#####################################################################
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

setup_cachyos() {
    # linux-cachyos (the default live kernel) lives in [cachyos], and
    # prepopulate_keyring runs `pacman-key --populate cachyos`, so the
    # build host needs the cachyos keyring + mirrorlist. Idempotent:
    # hosts that already have them (CachyOS, or any previously-set-up
    # box) are detected and skipped.
    if pacman -Q cachyos-keyring &>/dev/null && pacman -Q cachyos-mirrorlist &>/dev/null; then
        log_info "CachyOS keyring and mirrorlist are both installed"
        return 0
    fi

    log_warn "Installing cachyos-keyring and cachyos-mirrorlist"

    local key_id="F3B607488DB35A47"

    log_info "Trusting the CachyOS signing key"
    sudo pacman-key --recv-keys "${key_id}" --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key "${key_id}"

    # Enable the CachyOS repo from the CDN77 geo-mirror (worldwide datacenters —
    # routes each user to the nearest one) so pacman fetches the keyring and
    # mirrorlist by name: always the latest version, no pinning, no scraping.
    if ! grep -q '^\[cachyos\]' /etc/pacman.conf; then
        log_info "Adding [cachyos] repo (CDN77 geo-mirror) to /etc/pacman.conf"
        sudo tee -a /etc/pacman.conf >/dev/null <<'EOF_CACHYOS'

[cachyos]
Server = https://cdn77.cachyos.org/repo/$arch/$repo
EOF_CACHYOS
    fi

    log_info "Installing cachyos-keyring and cachyos-mirrorlist from the geo-mirror"
    sudo pacman -Sy --needed --noconfirm cachyos-keyring cachyos-mirrorlist

    log_success "cachyos-keyring and cachyos-mirrorlist installed"
}
