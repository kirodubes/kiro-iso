#!/usr/bin/env bash
set -Eeuo pipefail

##################################################################################################################
# Author    : Erik Dubois
# Website   : https://www.erikdubois.be
# Youtube   : https://youtube.com/erikdubois
# Github    : https://github.com/erikdubois
# Github    : https://github.com/kirodubes
# Github    : https://github.com/buildra
# SF        : https://sourceforge.net/projects/kiro/files/
##################################################################################################################

workdir="$(pwd)"
mirrorlist_path="$workdir/archiso/airootfs/etc/pacman.d/mirrorlist"
mirrorlist_dir="$(dirname "$mirrorlist_path")"

# Allow override: USE_MIRRORLIST_FETCH=false ./script.sh
USE_MIRRORLIST_FETCH="${USE_MIRRORLIST_FETCH:-true}"

# Network / fetch tuning
CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-5}"   # seconds
MAX_TIME="${MAX_TIME:-20}"               # seconds total
RETRIES="${RETRIES:-3}"

# Prefer IPv4 because your curl(28) indicates connect issues (often IPv6/routing)
PREFER_IPV4="${PREFER_IPV4:-true}"

# Mirrorlist query (keep it configurable)
MIRRORLIST_URL="${MIRRORLIST_URL:-https://archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4}"

tmpfile=""
official_tmp=""

on_error() {
  local exit_code=$?
  echo "ERROR: script failed at line $1 (exit=$exit_code)" >&2
  exit "$exit_code"
}
trap 'on_error $LINENO' ERR

cleanup() {
  [[ -n "${tmpfile}" && -f "${tmpfile}" ]] && rm -f "$tmpfile"
  [[ -n "${official_tmp}" && -f "${official_tmp}" ]] && rm -f "$official_tmp"
}
trap cleanup EXIT

info() { echo "==> $*"; }

ensure_paths() {
  [[ -d "$mirrorlist_dir" ]] || mkdir -p "$mirrorlist_dir"
}

write_static_mirrorlist() {
  cat <<'EOF'
## Best Arch Linux servers worldwide

Server = https://mirror.osbeck.com/archlinux/$repo/os/$arch
Server = http://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
EOF
}

curl_flags_common() {
  # shellcheck disable=SC2046
  echo -n "--fail --silent --show-error --location --connect-timeout ${CONNECT_TIMEOUT} --max-time ${MAX_TIME} --retry ${RETRIES} --retry-all-errors"
}

curl_ip_flag() {
  if [[ "$PREFER_IPV4" == "true" ]]; then
    echo -n "-4"
  fi
}

url_reachable() {
  command -v curl >/dev/null 2>&1 || return 1
  # quick HEAD ping with small max-time
  curl $(curl_ip_flag) -I --silent --fail --connect-timeout "${CONNECT_TIMEOUT}" --max-time "${MAX_TIME}" "https://archlinux.org/" >/dev/null
}

fetch_official_mirrorlist() {
  local url="$1"
  local out_file="$2"

  if command -v curl >/dev/null 2>&1; then
    # Fast pre-check avoids hanging on dead routing
    if ! url_reachable; then
      return 2
    fi

    # Fetch
    curl $(curl_ip_flag) $(curl_flags_common) "$url" > "$out_file"
  elif command -v wget >/dev/null 2>&1; then
    # Wget fallback with timeouts
    local wget_ip=()
    [[ "$PREFER_IPV4" == "true" ]] && wget_ip=(-4)

    wget "${wget_ip[@]}" -qO- \
      --timeout="$MAX_TIME" \
      --tries="$RETRIES" \
      "$url" > "$out_file"
  else
    return 127
  fi

  # Uncomment only lines that start with "#Server"
  sed -i 's/^#Server/Server/g' "$out_file"
}

get_mirrorlist() {
  ensure_paths
  tmpfile="$(mktemp)"
  official_tmp="$(mktemp)"

  info "getting mirrorlist (static)"
  write_static_mirrorlist > "$tmpfile"

  if [[ "$USE_MIRRORLIST_FETCH" == "true" ]]; then
    info "getting mirrorlist (official)"
    if fetch_official_mirrorlist "$MIRRORLIST_URL" "$official_tmp"; then
      echo >> "$tmpfile"
      cat "$official_tmp" >> "$tmpfile"
      info "official mirrorlist appended"
    else
      info "official mirrorlist fetch failed (keeping static list)"
    fi
  else
    info "Skipping mirrorlist fetch (USE_MIRRORLIST_FETCH=$USE_MIRRORLIST_FETCH)"
  fi

  # Atomic replace
  mv -f "$tmpfile" "$mirrorlist_path"
  tmpfile=""  # so cleanup doesn't delete the new file
  info "mirrorlist written to: $mirrorlist_path"
}

run_git_workflow() {
  git add --all .

  if git diff --cached --quiet; then
    info "No changes to commit"
  else
    git commit -m "update"
  fi

  local branch upstream
  branch="$(git rev-parse --abbrev-ref HEAD)"

  # If upstream exists: normal push. Else set upstream once.
  if upstream="$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)"; then
    git push
  else
    git push -u origin "$branch"
  fi
}

main() {
  ./change-version.sh
  get_mirrorlist
  run_git_workflow

  echo
  tput setaf 6 || true
  echo "##############################################################"
  echo "###################  $(basename "$0") done"
  echo "##############################################################"
  tput sgr0 || true
  echo
}

main "$@"
