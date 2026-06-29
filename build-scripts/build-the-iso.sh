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
if command -v tput >/dev/null 2>&1 && [[ -t 1 ]] && tput setaf 1 >/dev/null 2>&1; then
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
# Build configuration
#   User-editable knobs live in build.conf (sourced below) so the CLI
#   and the kiro-iso-builder GUI share one source of truth. Edit them
#   there, or through the GUI — not here.
#####################################################################
kiroVersion='v26.06.29'

# kiroVersion stays in THIS file: apply_version_bump (Phase 2) seds it and
# verify_version_sync greps it. build.conf is sourced right after it — the
# derived paths below depend on build_location/kiroVersion — but it never
# carries the version itself.
# build.conf is the gitignored live working copy. Seed it from the tracked
# canonical defaults on first use so local tweaks never get committed.
if [[ ! -f "${SCRIPT_DIR}/build.conf" ]]; then
    if [[ -f "${SCRIPT_DIR}/build.conf.defaults" ]]; then
        cp "${SCRIPT_DIR}/build.conf.defaults" "${SCRIPT_DIR}/build.conf"
    else
        echo "FATAL: neither build.conf nor build.conf.defaults found beside build-the-iso.sh (${SCRIPT_DIR})" >&2
        exit 1
    fi
fi
source "${SCRIPT_DIR}/build.conf"

if [[ "${build_location}" == "local" ]]; then
    # Build/out folders sit next to the clone (one level above the repo) so the
    # work stays inside the directory you chose to clone into, not your $HOME root.
    PARENT_PATH="$(cd -- "${REPO_DIR}/.." && pwd)"
    buildFolder="${PARENT_PATH}/kiro-build"
    outFolder="${PARENT_PATH}/kiro-Out"
else
    buildFolder="${HOME}/kiro-build"
    outFolder="${HOME}/kiro-Out"
fi
isoLabel="kiro-${kiroVersion}-x86_64.iso"
PACKAGES_FILE="${buildFolder}/archiso/packages.x86_64"

#####################################################################
# Host-preparation helpers (ensure_package, setup_chaotic, setup_cachyos)
#####################################################################
source "${SCRIPT_DIR}/host-prep.sh"

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
    log_section "Phase 3 — Verifying version files are in sync"

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

preflight_checks() {
    # Fail fast before the long mkarchiso run: not enough disk, or no network,
    # both surface here with a clear message instead of dying mid-build.
    log_section "Phase 1 — Preflight checks (disk space + connectivity)"

    # Disk space — buildFolder and outFolder may live on different filesystems,
    # so check whichever has the least free space against the minimum the build needs.
    local min_free_gb=15
    local b_free o_free least_free
    mkdir -p "${buildFolder}" "${outFolder}"
    b_free=$(df --output=avail -BG "${buildFolder}" | tail -1 | tr -dc '0-9')
    o_free=$(df --output=avail -BG "${outFolder}"  | tail -1 | tr -dc '0-9')
    least_free=$(( b_free < o_free ? b_free : o_free ))
    if (( least_free < min_free_gb )); then
        log_error "Not enough free disk space — need at least ${min_free_gb}G free.
  build folder (${buildFolder}): ${b_free}G free
  out folder   (${outFolder}): ${o_free}G free
Free up space and re-run."
        exit 1
    fi
    status_ok "Disk space OK — ${least_free}G free (need ${min_free_gb}G)"

    # Connectivity — the build syncs pacman databases and fetches the latest
    # .bashrc over HTTPS. wget is a hard build dependency, so use it as the probe.
    ensure_package wget
    # A single dropped probe (slow TLS handshake, DNS blip) shouldn't abort the
    # whole build — retry each host a few times before declaring it unreachable.
    local host attempt
    for host in https://archlinux.org https://github.com; do
        attempt=1
        until wget -q --spider --timeout=15 --tries=1 "${host}"; do
            if (( attempt >= 3 )); then
                log_error "No connectivity to ${host} — the build needs internet to sync
packages and fetch the latest .bashrc. Check your network and re-run."
                exit 1
            fi
            attempt=$((attempt + 1))
            sleep 3
        done
        status_ok "Reachable: ${host}"
    done

    # Arch mirror fallback must run BEFORE `pacman -Sy`: the sync below (and
    # every later host-side pacman call, plus mkarchiso) pulls [core]/[extra]
    # through the host mirrorlist. Prefer the user's PC mirrors; if they're all
    # down, swap in our curated geo-CDN set so the build still completes.
    ensure_arch_mirrors

    # Refresh pacman sync databases before any repo-dependent step. On a fresh
    # host (e.g. a just-installed CachyOS) the sync DBs may not be populated yet,
    # which breaks the later keyring/package installs. Runs on every host since
    # setup_cachyos short-circuits where the cachyos repo is already present.
    log_info "Refreshing pacman databases"
    sudo pacman -Sy
}

clean_cache() {
    if [[ "${clean_pacman_cache}" == "yes" ]]; then
        log_section "Cleaning pacman package cache"
        # Feed exactly the two confirmations -Scc needs. `yes |` streams forever and
        # gets SIGPIPE when pacman exits, which under `set -o pipefail` aborts the
        # build with exit 141. printf closes cleanly after the answers it sends.
        printf 'y\ny\n' | sudo pacman -Scc
    else
        log_info "Skipping pacman cache clean (clean_pacman_cache=no)"
    fi
}

unmount_stale_build_mounts() {
    # An interrupted mkarchiso leaves bind-mounts (dev/proc/sys/run/tmp/pts/shm/
    # efivars) under the work dir. They block 'rm -rf', break the next build, and
    # clutter the file manager. Lazily unmount anything still mounted under
    # buildFolder — deepest path first — so the folder can be removed cleanly.
    [[ -d "${buildFolder}" ]] || return 0
    local target
    while read -r target; do
        [[ -n "${target}" ]] || continue
        log_warn "Unmounting stale build mount: ${target}"
        sudo umount -R -l "${target}" 2>/dev/null || sudo umount -l "${target}" 2>/dev/null || true
    done < <(findmnt -rno TARGET 2>/dev/null \
        | awk -v b="${buildFolder}" 'index($0, b"/") == 1 || $0 == b' | sort -r)
}

cleanup_on_interrupt() {
    # Ctrl-C / kill leaves mkarchiso's bind-mounts live under the work dir,
    # which can wedge the host. Unmount them before exiting so an interrupted
    # build never leaves the system in a broken state.
    echo
    log_warn "Interrupted — unmounting stale build mounts before exit."
    unmount_stale_build_mounts
}
# EXIT catches every exit path — signal, `set -e` failure, or normal end — and
# is the real net: it's a no-op after a clean build (mkarchiso already unmounted,
# so findmnt finds nothing) but always unmounts a half-finished one. The INT/TERM
# traps add the log line and a correct exit code on top. Registered here, after
# buildFolder is set, so the trap never references it unbound under `set -u`.
trap unmount_stale_build_mounts EXIT
trap 'cleanup_on_interrupt; exit 130' INT
trap 'cleanup_on_interrupt; exit 143' TERM

remove_buildfolder() {
    local action="${1:-no}"
    if [[ "${action}" == "yes" ]]; then
        if [[ -d "${buildFolder}" ]]; then
            unmount_stale_build_mounts
            status_ok "Build folder present — proceeding to delete"
            log_warn "Deleting build folder: ${buildFolder}"
            sudo rm -rf "${buildFolder}"
        else
            status_nok "Build folder not found — nothing to delete"
        fi
    fi
}

# ensure_package, setup_chaotic and setup_cachyos now live in host-prep.sh
# (sourced above) so all host-preparation logic stays in one place.

show_overview() {
    log_section "Build overview"
    echo "  Desktop      : ${desktop}"
    echo "  Editions     : ${editions-ohmychadwm}"
    echo "  Version      : ${kiroVersion}"
    echo "  ISO label    : ${isoLabel}"
    echo "  NVIDIA driver: ${nvidia_driver}"
    echo "  Kernel(s)    : ${SELECTED_KERNELS[*]} (live boot: ${PRIMARY_KERNEL})"
    echo "  Build folder : ${buildFolder}"
    echo "  Out folder   : ${outFolder}"
}

refresh_skel_bashrc() {
    # Maintainer-only: on the build host, refresh skel's .bashrc from the local
    # kiro-bash-config checkout so the ISO always ships the current shell. No-op (and
    # no phase number) everywhere else.
    [[ "${HOSTNAME}" == "hq" ]] || return 0

    log_section "Refreshing skel .bashrc from kiro-bash-config (maintainer host only)"
    local skel_dir="${REPO_DIR}/archiso/airootfs/etc/skel"
    local skel_bashrc="${skel_dir}/.bashrc"
    local skel_bashrc_latest="${skel_dir}/.bashrc-latest"
    local edu_bashrc_latest="${HOME}/KIRO/kiro-bash-config/etc/skel/.bashrc-latest"
    # Pull the latest .bashrc-latest in, drop the old .bashrc, then promote the
    # fresh copy into its place so skel always ships the current kiro-bash-config .bashrc.
    if [[ -f "${edu_bashrc_latest}" ]]; then
        cp "${edu_bashrc_latest}" "${skel_bashrc_latest}"
        rm -f "${skel_bashrc}"
        mv "${skel_bashrc_latest}" "${skel_bashrc}"
        status_ok "${GREEN}.bashrc refreshed from kiro-bash-config${RESET}"
    else
        log_warn "kiro-bash-config .bashrc-latest not found at ${edu_bashrc_latest}"
    fi
}

check_required_packages() {
    log_section "Phase 4 — Checking required packages"
    ensure_package archiso
    ensure_package grub
}

prepare_build_tree() {
    log_section "Phase 5 — Preparing build tree"

    remove_buildfolder yes
    mkdir -p "${buildFolder}"
    cp -r "${REPO_DIR}/archiso" "${buildFolder}/archiso"

    # Pacman ParallelDownloads in the build-tree pacman.conf (the file mkarchiso
    # uses for the airootfs install) is treated as a floor: raise it to
    # ${parallel_downloads} only when the shipped value is lower or inactive —
    # never lower a higher value. Edits only the build copy, never the repo file.
    local btree_pacman="${buildFolder}/archiso/pacman.conf"
    local current_pd
    current_pd=$(grep -oP '^\s*ParallelDownloads\s*=\s*\K[0-9]+' "${btree_pacman}" | head -1)
    if [[ -z "${current_pd}" ]]; then
        if grep -qE '^\s*#\s*ParallelDownloads' "${btree_pacman}"; then
            sed -i "s|^\s*#\s*ParallelDownloads.*|ParallelDownloads = ${parallel_downloads}|" "${btree_pacman}"
        else
            sed -i "/^\[options\]/a ParallelDownloads = ${parallel_downloads}" "${btree_pacman}"
        fi
        log_warn "ParallelDownloads was inactive in build-tree pacman.conf — enabling it at ${parallel_downloads}"
    elif (( current_pd < parallel_downloads )); then
        sed -i "s|^\s*ParallelDownloads.*|ParallelDownloads = ${parallel_downloads}|" "${btree_pacman}"
        log_warn "Raising ParallelDownloads ${current_pd} -> ${parallel_downloads} in build-tree pacman.conf"
    else
        log_info "ParallelDownloads already ${current_pd} (>= ${parallel_downloads}) — leaving it unchanged"
    fi

    log_section "Phase 6 — Refreshing skel and package list"

    local skel_dir="${buildFolder}/archiso/airootfs/etc/skel"
    echo "Clearing skel..."
    find "${skel_dir}" -mindepth 1 -delete 2>/dev/null || true

    echo "Fetching latest .bashrc..."
    wget -q "https://raw.githubusercontent.com/kirodubes/kiro-bash-config/refs/heads/main/etc/skel/.bashrc-latest" \
        -O "${skel_dir}/.bashrc" \
        || { log_error "Failed to download .bashrc from kiro-bash-config"; exit 1; }

    echo "Refreshing packages.x86_64..."
    cp -f "${REPO_DIR}/archiso/packages.x86_64" "${PACKAGES_FILE}"
    apply_package_selection
    apply_package_additions
}

apply_package_selection() {
    # Comment out the TIER 3 packages the kiro-iso-builder GUI marked for
    # exclusion in build-scripts/package-selection.conf (one package per line).
    # Literal whole-line match via awk — no regex metachar pitfalls — and it
    # only ever prefixes '#', so it can never pull in a package, only drop an
    # optional one. Missing/empty file = ship the full list (default).
    local sel="${SCRIPT_DIR}/package-selection.conf"
    [[ -f "${sel}" ]] || return 0
    local tmp
    tmp="$(mktemp)"
    awk '
        NR==FNR { line=$0; sub(/#.*/,"",line); gsub(/[ \t]/,"",line)
                  if (line!="") excl[line]=1; next }
        { key=$0; sub(/[ \t]+$/,"",key)
          if (key in excl) print "#" $0; else print $0 }
    ' "${sel}" "${PACKAGES_FILE}" > "${tmp}" && mv "${tmp}" "${PACKAGES_FILE}"
    local n
    n="$(grep -cvE '^[[:space:]]*(#|$)' "${sel}" || true)"
    log_info "Package selection: applied ${sel##*/} (${n} TIER 3 package(s) excluded)"
}

apply_package_additions() {
    # Opt-in EXTRA APPS the kiro-iso-builder "Add apps" page selected. Each app is a
    # commented EXTRA-APP block in packages.x86_64; this UNcomments the block(s) whose key
    # is listed in build-scripts/package-additions.conf (one key per line). Missing/empty
    # file = add nothing (= standard production ISO). Mirror of apply_editions, but a stale
    # key warns-and-skips instead of aborting — an opt-in extra must never break the build.
    local add="${SCRIPT_DIR}/package-additions.conf"
    [[ -f "${add}" ]] || return 0
    local n=0 key
    while IFS= read -r key; do
        key="${key%%#*}"; key="${key//[[:space:]]/}"
        [[ -z "${key}" ]] && continue
        if ! grep -qF ">>> EXTRA-APP ${key} " "${PACKAGES_FILE}"; then
            log_warn "Extra app '${key}' has no block in packages.x86_64 — skipped"
            continue
        fi
        # Uncomment the block's package lines (#pkg -> pkg); leave the ### markers.
        sed -i "/>>> EXTRA-APP ${key} /,/<<< EXTRA-APP ${key} <<</ s/^#\([^#]\)/\1/" "${PACKAGES_FILE}"
        log_info "Added extra app: ${key}"
        n=$((n + 1))
    done < "${add}"
    log_info "Package additions: applied ${add##*/} (${n} extra app(s) added)"
}

prepopulate_keyring() {
    log_section "Phase 7 — Prepopulating pacman keyring"

    local keyring_dir="${buildFolder}/archiso/airootfs/etc/pacman.d/gnupg"
    sudo pacman-key --gpgdir "${keyring_dir}" --init
    sudo pacman-key --gpgdir "${keyring_dir}" --populate archlinux
    sudo pacman-key --gpgdir "${keyring_dir}" --populate chaotic
    sudo pacman-key --gpgdir "${keyring_dir}" --populate cachyos
    # Kiro signing key — pre-seed it so the airootfs trusts nemesis_repo/kiro_repo
    # signatures out of the box (the shipped pacman.conf enforces them). Reads the
    # host's /usr/share/pacman/keyrings/kiro.gpg, provided by the kiro-keyring pkg.
    sudo pacman-key --gpgdir "${keyring_dir}" --populate kiro
    log_info "Keyring prepopulation complete"
}

inject_nvidia_packages() {
    log_section "Phase 8 — Injecting NVIDIA driver: ${nvidia_driver}"

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
        none)
            # No NVIDIA GPU (AMD / Intel / VM): strip every NVIDIA package, add none.
            # AMD/Intel run on in-kernel drivers + mesa, which are already on the ISO.
            sed -i '/^nvidia-open-dkms/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-580xx/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-390xx/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-utils/d' "${PACKAGES_FILE}"
            sed -i '/^nvidia-settings/d' "${PACKAGES_FILE}"
            log_info "NVIDIA driver: none — AMD/Intel/VM, relying on in-kernel drivers + mesa."
            ;;
        *)
            log_error "Unknown NVIDIA driver option: ${nvidia_driver}\nValid options: open | 580xx | 390xx | none"
            exit 1
            ;;
    esac
}

#####################################################################
# Desktop / WM editions — bake extra sessions onto the XFCE base.
# Each edition has a commented block in packages.x86_64 (marked EDITION-BLOCK <name>);
# this uncomments the package lines of every edition listed in build.conf
# editions=. XFCE stays the login/fallback session, so nothing else
# (sddm / calamares default session) changes — these only ADD a session.
# Generic by design: TWMs now; full DEs (plasma/gnome) later use the same blocks.
#####################################################################
apply_editions() {
    # Unset (e.g. an old live build.conf seeded before this knob existed) falls back to
    # the shipped default so the standard ISO never silently changes.
    local sel="${editions-xfce ohmychadwm}"
    local default_sess="${default_session-xfce}"
    log_section "Desktop / WM editions — ${sel:-none}  (login session: ${default_sess})"
    # SAFEGUARD: an ISO must ship at least one session — refuse a desktop-less / WM-less build.
    if [[ -z "${sel// /}" ]]; then
        log_error "No editions selected (editions=\"\") — an ISO needs at least one desktop or window manager. Set 'editions' in build.conf."
        exit 1
    fi
    # Guard: the login session must be one of the installed editions, else the live ISO
    # would autologin to a session that isn't there. Fallback priority when default_session
    # isn't valid: a selected full desktop (DE) wins over the WMs — a chosen desktop is the
    # intended primary, so plasma/gnome/… outrank ohmychadwm; for several DEs the first in
    # editions= wins. With no DE, the flagship ohmychadwm; with neither, the first edition.
    # (DE list mirrors KIB's DESKTOPS set in configure_gui.py — keep them in sync.)
    if [[ " ${sel} " != *" ${default_sess} "* ]]; then
        local desktops="xfce cinnamon plasma gnome mate budgie lxqt deepin"
        local fallback="" ed
        for ed in ${sel}; do
            if [[ " ${desktops} " == *" ${ed} "* ]]; then fallback="${ed}"; break; fi
        done
        if [[ -z "${fallback}" ]]; then
            if [[ " ${sel} " == *" ohmychadwm "* ]]; then fallback="ohmychadwm"; else fallback="${sel%% *}"; fi
        fi
        log_warn "default_session='${default_sess}' is not in editions='${sel}' — using '${fallback}'."
        default_sess="${fallback}"
    fi
    # Live ISO autologin session follows default_session, so a non-XFCE build (e.g.
    # editions="cinnamon") boots its own desktop instead of a now-absent XFCE.
    # Most editions' SDDM session basename equals the edition name, but budgie is the
    # exception: Arch's budgie-desktop ships wayland-sessions/budgie-desktop.desktop, so
    # SDDM needs Session=budgie-desktop — Session=budgie matches nothing and autologin
    # silently drops to the greeter. Map the odd ones here; pass the rest through.
    local sddm_session="${default_sess}"
    case "${default_sess}" in
        budgie) sddm_session="budgie-desktop" ;;
    esac
    local sddm_conf="${buildFolder}/archiso/airootfs/etc/sddm.conf.d/kde_settings.conf"
    [[ -f "${sddm_conf}" ]] && sed -i "s/^Session=.*/Session=${sddm_session}/" "${sddm_conf}"
    local ed
    for ed in ${sel}; do
        if ! grep -qF ">>> EDITION-BLOCK ${ed} >>>" "${PACKAGES_FILE}"; then
            log_error "Edition '${ed}' has no block in packages.x86_64"
            exit 1
        fi
        # Uncomment the block's package lines (#pkg -> pkg); leave the ### markers.
        sed -i "/>>> EDITION-BLOCK ${ed} >>>/,/<<< EDITION-BLOCK ${ed} <<</ s/^#\([^#]\)/\1/" "${PACKAGES_FILE}"
        log_info "Enabled edition: ${ed}"
    done
}

#####################################################################
# Qt/GTK theme-override rules — applied when plasma or a GTK-stack
# desktop (gnome, budgie, …) is in editions=. Kiro ships XFCE-oriented
# Qt/GTK theme settings (the qt5ct package plus QT_QPA_PLATFORMTHEME /
# QT_STYLE_OVERRIDE / GTK_THEME in /etc/environment). Desktops that
# manage their own theming fight those settings:
#   1. Strip qt5ct/qt6ct from the package list — PLASMA ONLY: they
#      conflict with plasma-integration and break Qt apps' look-and-feel.
#      The GTK-stack desktops have no such conflict, so qt5ct stays.
#   2. Comment QT_QPA_PLATFORMTHEME / QT_STYLE_OVERRIDE / GTK_THEME in
#      /etc/environment — PLASMA AND the GTK-stack desktops: these
#      overrides stomp the desktop's own theming and trigger the yellow
#      "could not apply theme" popup (the same fix ATT's themes.py applies).
#   3. Warn (can't auto-fix) when gnome AND plasma are both selected: the
#      gnome group pulls xdg-desktop-portal-gnome, which conflicts with
#      xdg-desktop-portal-kde.
# ATT (desktopr.py / themes.py) is the reference for these desktop rules.
# (Name kept as apply_plasma_rules for call-site/doc stability.)
#####################################################################
apply_plasma_rules() {
    local sel="${editions-}"
    local has_plasma=0 has_gnome=0 has_budgie=0
    [[ " ${sel} " == *" plasma "* ]] && has_plasma=1
    [[ " ${sel} " == *" gnome "* ]]  && has_gnome=1
    [[ " ${sel} " == *" budgie "* ]] && has_budgie=1
    # GTK-stack desktops that manage their own theming: they need the
    # /etc/environment fix but not the (Plasma-specific) qt5ct strip.
    local has_gtk_de=0
    (( has_gnome || has_budgie )) && has_gtk_de=1
    (( has_plasma || has_gtk_de )) || return 0

    local which=""
    (( has_plasma )) && which+="Plasma "
    (( has_gnome ))  && which+="GNOME "
    (( has_budgie )) && which+="Budgie "
    log_section "Qt/GTK theme rules (${which% })"

    # 1. Strip the Qt platform-theme conflicts — Plasma only (whole-line match; only ever prefixes '#').
    if (( has_plasma )); then
        local pkg
        for pkg in qt5ct qt6ct; do
            if grep -qxF "${pkg}" "${PACKAGES_FILE}"; then
                sed -i "s/^${pkg}\$/#${pkg}   # removed for Plasma: conflicts with plasma-integration/" "${PACKAGES_FILE}"
                log_info "Stripped Qt-theme conflict: ${pkg}"
            fi
        done
    fi

    # 2. Comment the theme-override vars in /etc/environment — Plasma or a GTK-stack DE
    #    (idempotent — already-#'d lines won't match).
    local env_file="${buildFolder}/archiso/airootfs/etc/environment"
    if [[ -f "${env_file}" ]]; then
        sed -i -E 's/^(QT_QPA_PLATFORMTHEME=|QT_STYLE_OVERRIDE=|GTK_THEME=)/#\1/' "${env_file}"
        log_info "Commented QT_QPA_PLATFORMTHEME / QT_STYLE_OVERRIDE / GTK_THEME in /etc/environment"
    fi

    # 3. gnome + plasma: portal conflict we can't comment out (transitive via the gnome group).
    if (( has_plasma && has_gnome )); then
        log_warn "gnome + plasma in one ISO: the gnome group pulls xdg-desktop-portal-gnome, which conflicts with xdg-desktop-portal-kde (KDE packaging rules). Consider separate ISOs."
    fi
}

#####################################################################
# Kernel selection — keeps the ISO independent of any one kernel.
# The repo ships ${CANONICAL_KERNEL} as its default; this rewrites the
# build-tree copies to whatever the user picks. Pairs with the calamares
# kiro_kernel module, which installs whatever kernel(s) the ISO ships.
#####################################################################
CANONICAL_KERNEL="linux-cachyos"   # the kernel token the repo's archiso tree ships by default
AVAILABLE_KERNELS=()
SELECTED_KERNELS=()
PRIMARY_KERNEL=""

# Kernel discovery lives in list-kernels.sh (shared with the kiro-iso-builder
# GUI) so the CLI and GUI always agree on what is offerable. It prints every
# kernel that has a matching -headers package, one per line — the full repo
# offering (CachyOS/XanMod flavors, pinned-LTS series and CPU-microarch builds
# included); the -headers test is the only filter.
detect_available_kernels() {
    mapfile -t AVAILABLE_KERNELS < <(bash "${SCRIPT_DIR}/list-kernels.sh")
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
    log_section "Phase 9 — Applying kernel(s): ${SELECTED_KERNELS[*]} (live boot: ${PRIMARY_KERNEL})"

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
    log_section "Phase 10 — Stamping build date"
    local date_build
    date_build=$(date -d now)
    echo "ISO build on: ${date_build}"
    sudo sed -i "s/\(^ISO_BUILD=\).*/\1${date_build}/" "${buildFolder}/archiso/airootfs/etc/dev-rel"
    clean_cache
}

build_iso() {
    log_section "Phase 11 — Running mkarchiso (this takes a while)"
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
    if [[ "${HOSTNAME}" != "hq" ]]; then
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
    log_section "Phase 12 — Creating checksums and pkglist"
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
    preflight_checks
    setup_chaotic
    ensure_chaotic_mirrors
    setup_cachyos
    setup_kiro_keyring
    setup_kiro_mirrorlist

    # "All green" gate — confirm every repo the build/install depends on is
    # reachable (after the host->curated fallbacks above) before mkarchiso runs.
    mirror_health_report

    apply_version_bump
    verify_version_sync
    refresh_skel_bashrc

    check_required_packages
    select_kernels
    show_overview
    prepare_build_tree
    prepopulate_keyring
    inject_nvidia_packages
    apply_editions
    apply_plasma_rules
    apply_kernel
    stamp_build_date
    build_iso
    create_checksums
    remove_buildfolder "${remove_build_folder}"
    record_build_time
    log_success "$(basename "$0") done — ISO is in ${outFolder}"
}

main "$@"
