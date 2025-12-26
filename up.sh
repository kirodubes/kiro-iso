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

USE_MIRRORLIST_FETCH=true

# Network / fetch tuning
CONNECT_TIMEOUT=5     # seconds
MAX_TIME=20           # seconds total
RETRIES=3

cleanup() {
  [[ -n "${tmpfile:-}" && -f "${tmpfile:-}" ]] && rm -f "$tmpfile"
}
trap cleanup EXIT

die() {
  echo "ERROR: $*" >&2
  exit 1
}

info() {
  echo "==> $*"
}

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

fetch_official_mirrorlist() {
  local url="https://archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4&ip_version=6"
  local out_file="$1"

  # Prefer curl (better timeouts); fallback to wget
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL \
      --connect-timeout "$CONNECT_TIMEOUT" \
      --max-time "$MAX_TIME" \
      --retry "$RETRIES" \
      --retry-all-errors \
      "$url" > "$out_file"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- \
      --timeout="$MAX_TIME" \
      --tries="$RETRIES" \
      "$url" > "$out_file"
  else
    return 127
  fi

  # Uncomment only the Server lines Arch provides (they come as "#Server = ...")
  sed -i 's/^#Server/Server/g' "$out_file"
}

get_mirrorlist() {
  ensure_paths
  tmpfile="$(mktemp)"

  info "getting mirrorlist (static)"
  write_static_mirrorlist > "$tmpfile"

  if [[ "$USE_MIRRORLIST_FETCH" == "true" ]]; then
    info "getting mirrorlist (official)"
    local official_tmp
    official_tmp="$(mktemp)"

    if fetch_official_mirrorlist "$official_tmp"; then
      echo >> "$tmpfile"
      cat "$official_tmp" >> "$tmpfile"
      rm -f "$official_tmp"
      info "official mirrorlist appended"
    else
      rm -f "$official_tmp" || true
      info "official mirrorlist fetch failed (keeping static list)"
    fi
  else
    info "Skipping mirrorlist fetch (USE_MIRRORLIST_FETCH=$USE_MIRRORLIST_FETCH)"
  fi

  # Atomically replace
  mv -f "$tmpfile" "$mirrorlist_path"
  unset tmpfile
  info "mirrorlist written to: $mirrorlist_path"
}

run_git_workflow() {
  git add --all .

  # Only commit if there are changes
  if git diff --cached --quiet; then
    info "No changes to commit"
  else
    git commit -m "update"
  fi

  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)"
  git push -u origin "$branch"
}

# --- main ---
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
