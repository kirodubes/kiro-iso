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

enable_cachyos() {
    # Re-enable a [cachyos] repo that is present in pacman.conf but commented out
    # (Kiro ships it disabled by default — chaotic-aur is the backstop). Only
    # needed when the user picks a cachyos-only kernel that chaotic-aur doesn't
    # carry. Assumes the keyring/mirrorlist are already installed; setup_cachyos
    # handles the from-scratch case. Idempotent.
    if grep -qE '^[[:space:]]*\[cachyos\]' /etc/pacman.conf; then
        log_info "[cachyos] is already enabled in /etc/pacman.conf"
    elif grep -qE '^[[:space:]]*#[[:space:]]*\[cachyos\][[:space:]]*$' /etc/pacman.conf; then
        log_info "Uncommenting the [cachyos] repo in /etc/pacman.conf"
        [[ -f /etc/pacman.conf.kiro-bak ]] || sudo cp /etc/pacman.conf /etc/pacman.conf.kiro-bak
        # Uncomment the [cachyos] header and its commented config lines, stopping
        # at the next blank line or section header so nothing else is touched.
        awk '
            function uncomment(s) { sub(/^[[:space:]]*#[[:space:]]?/, "", s); return s }
            /^[[:space:]]*#[[:space:]]*\[cachyos\][[:space:]]*$/ { print uncomment($0); blk=1; next }
            blk==1 {
                if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^[[:space:]]*\[/) { blk=0; print; next }
                if ($0 ~ /^[[:space:]]*#/) { print uncomment($0); next }
                blk=0; print; next
            }
            { print }
        ' /etc/pacman.conf | sudo tee /etc/pacman.conf.kiro-new >/dev/null
        sudo mv /etc/pacman.conf.kiro-new /etc/pacman.conf
    else
        log_warn "No [cachyos] section in /etc/pacman.conf — running full setup"
        setup_cachyos
    fi

    log_info "Syncing package databases"
    sudo pacman -Sy --noconfirm
    log_success "[cachyos] repo enabled"
}

#####################################################################
# Repository mirror health + fallback
#
# Two layers, two policies:
#   * BUILD HOST  — prefer the user's own pacman mirrors (their PC's
#     settings); if every one of them is unreachable, fall back to our
#     curated geo-CDN set so the build still completes on a broken host.
#   * SHIPPED ISO — always ships the curated geo-CDN mirrorlists committed
#     under archiso/airootfs/etc/pacman.d/ (handled at the file level, not
#     here). This function only guards the build host.
# nemesis_repo / kiro_repo are single GitHub-Pages servers — our own infra,
# nothing to fall back to, so they are probed for reporting only.
#####################################################################

# Curated, geo-routed CDN mirrors — fast and complete worldwide. Kept as
# literal '$repo'/'$arch' templates; _probe_mirror substitutes them.
KIRO_CURATED_ARCH_MIRRORS=(
    'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch'
    'Server = https://fastly.mirror.pkgbuild.com/$repo/os/$arch'
    'Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch'
    'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch'
)
KIRO_CURATED_CHAOTIC_MIRRORS=(
    'Server = https://geo-mirror.chaotic.cx/$repo/$arch'
    'Server = https://cdn-mirror.chaotic.cx/$repo/$arch'
)

# _probe_mirror <server-template> <repo> [arch]
# Substitutes $repo/$arch into the template and HEAD-checks the repo's .db.
# Returns 0 if reachable. The template may be a bare URL or a "Server = URL".
_probe_mirror() {
    local tmpl="${1#Server = }" repo="$2" arch="${3:-x86_64}"
    local url="${tmpl//\$repo/${repo}}"
    url="${url//\$arch/${arch}}"
    url="${url%/}/${repo}.db"
    wget -q --spider --timeout=8 --tries=1 "${url}"
}

# _write_curated_list <file> <header> <mirror-array-name>
_write_curated_list() {
    local file="$1" header="$2" arrname="$3"
    local -n arr="${arrname}"
    [[ -f "${file}" && ! -f "${file}.kiro-bak" ]] && sudo cp "${file}" "${file}.kiro-bak"
    {
        printf '##\n## %s\n## Installed by build-the-iso.sh because the host mirrors were unreachable.\n## Original (if any) saved alongside as %s.kiro-bak\n##\n\n' \
            "${header}" "$(basename "${file}")"
        printf '%s\n' "${arr[@]}"
    } | sudo tee "${file}" >/dev/null
}

# ensure_arch_mirrors — must run BEFORE the host `pacman -Sy`, since mkarchiso
# and every host-side pacman call resolve [core]/[extra] against this file.
ensure_arch_mirrors() {
    local ml="/etc/pacman.d/mirrorlist"
    log_info "Checking host Arch mirrors (the user's PC settings)"

    local active=()
    mapfile -t active < <(grep -oP '^\s*Server\s*=\s*\K\S+' "${ml}" 2>/dev/null || true)

    local tmpl
    for tmpl in "${active[@]:0:5}"; do
        if _probe_mirror "${tmpl}" core; then
            status_ok "Host Arch mirrors reachable — using the user's PC mirrorlist"
            return 0
        fi
    done

    log_warn "Host Arch mirrors unreachable or empty — falling back to Kiro curated geo-CDN mirrors"
    _write_curated_list "${ml}" "Kiro curated Arch mirrors" KIRO_CURATED_ARCH_MIRRORS
    status_ok "Curated Arch mirrors written to ${ml} (backup: ${ml}.kiro-bak)"
}

# ensure_chaotic_mirrors — run AFTER setup_chaotic (which creates the file).
ensure_chaotic_mirrors() {
    [[ "${chaoticsrepo}" == "true" ]] || return 0
    local ml="/etc/pacman.d/chaotic-mirrorlist"
    log_info "Checking host Chaotic-AUR mirrors"

    local active=()
    mapfile -t active < <(grep -oP '^\s*Server\s*=\s*\K\S+' "${ml}" 2>/dev/null || true)

    local tmpl
    for tmpl in "${active[@]:0:5}"; do
        if _probe_mirror "${tmpl}" chaotic-aur; then
            status_ok "Host Chaotic-AUR mirrors reachable — using the user's PC mirrorlist"
            return 0
        fi
    done

    log_warn "Host Chaotic-AUR mirrors unreachable or empty — falling back to Kiro curated CDN mirrors"
    _write_curated_list "${ml}" "Kiro curated Chaotic-AUR mirrors" KIRO_CURATED_CHAOTIC_MIRRORS
    status_ok "Curated Chaotic-AUR mirrors written to ${ml} (backup: ${ml}.kiro-bak)"
}

# mirror_health_report — the "all green" gate before the long mkarchiso run.
# Probes one representative server per repo for both the BUILD layer (host
# mirrors the build pulls from) and the SHIP layer (curated mirrors the ISO
# carries). Aborts if any REQUIRED repo (Arch, chaotic) is fully unreachable;
# nemesis/kiro are our own single-server CDNs, so a miss there is a warning.
mirror_health_report() {
    log_section "Mirror health check — all repos must be green before building"

    local fail=0 warn=0

    # Build layer — the host mirrorlists mkarchiso actually pulls from.
    local first_arch first_chaotic
    first_arch=$(grep -m1 -oP '^\s*Server\s*=\s*\K\S+' /etc/pacman.d/mirrorlist 2>/dev/null)
    if [[ -n "${first_arch}" ]] && _probe_mirror "${first_arch}" core; then
        status_ok "Arch  (build/host)   : ${first_arch}"
    else
        status_nok "Arch  (build/host)   : ${first_arch:-<none>}"; fail=1
    fi

    if [[ "${chaoticsrepo}" == "true" ]]; then
        first_chaotic=$(grep -m1 -oP '^\s*Server\s*=\s*\K\S+' /etc/pacman.d/chaotic-mirrorlist 2>/dev/null)
        if [[ -n "${first_chaotic}" ]] && _probe_mirror "${first_chaotic}" chaotic-aur; then
            status_ok "Chaotic (build/host) : ${first_chaotic}"
        else
            status_nok "Chaotic (build/host) : ${first_chaotic:-<none>}"; fail=1
        fi
    fi

    # Ship layer — the curated mirrors baked into the ISO (sanity-check the
    # default we ship is actually alive, so we never ship a dead mirrorlist).
    local m
    for m in "${KIRO_CURATED_ARCH_MIRRORS[@]}"; do
        if _probe_mirror "${m}" core; then status_ok "Arch  (shipped curated): ${m#Server = }"; break; fi
    done
    if [[ "${chaoticsrepo}" == "true" ]]; then
        for m in "${KIRO_CURATED_CHAOTIC_MIRRORS[@]}"; do
            if _probe_mirror "${m}" chaotic-aur; then status_ok "Chaotic (shipped)    : ${m#Server = }"; break; fi
        done
    fi

    # Kiro's own single-server repos — warn-only (build-time reachability does
    # not guarantee install-time, and a GH-Pages blip shouldn't block a build).
    if _probe_mirror 'Server = https://erikdubois.github.io/$repo/$arch' nemesis_repo; then
        status_ok "nemesis_repo         : https://erikdubois.github.io"
    else
        status_nok "nemesis_repo         : https://erikdubois.github.io (warn)"; warn=1
    fi
    if _probe_mirror 'Server = https://kirodubes.github.io/$repo/$arch' kiro_repo; then
        status_ok "kiro_repo            : https://kirodubes.github.io"
    else
        status_nok "kiro_repo            : https://kirodubes.github.io (warn)"; warn=1
    fi

    if (( fail )); then
        log_error "A required repository (Arch or Chaotic-AUR) is unreachable — aborting before the build.
Check your connection and re-run; the host->curated fallback already tried our mirrors."
        exit 1
    fi
    if (( warn )); then
        log_warn "All required repos green; one or more Kiro CDNs missed (warn-only). Continuing."
    else
        log_success "All repositories green"
    fi
}
