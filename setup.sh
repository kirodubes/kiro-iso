#!/bin/bash
set -euo pipefail
############################################################
# Author    : Erik Dubois
# Website   : https://www.erikdubois.be
############################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
############################################################

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

############################################################
# Colors
############################################################
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

############################################################
# Logging
############################################################
log_section() {
    echo
    echo "${GREEN}############################################################${RESET}"
    echo "$1"
    echo "${GREEN}############################################################${RESET}"
    echo
}

log_info() {
    echo
    echo "${BLUE}############################################################${RESET}"
    echo "$1"
    echo "${BLUE}############################################################${RESET}"
    echo
}

log_warn() {
    echo
    echo "${YELLOW}############################################################${RESET}"
    echo "$1"
    echo "${YELLOW}############################################################${RESET}"
    echo
}

log_error() {
    echo
    echo "${RED}############################################################${RESET}"
    echo "$1"
    echo "${RED}############################################################${RESET}"
    echo
}

log_success() {
    echo
    echo "${GREEN}############################################################${RESET}"
    echo "$1"
    echo "${GREEN}############################################################${RESET}"
    echo
}

############################################################
# Error handling
############################################################
on_error() {
    local lineno="$1"
    local cmd="$2"
    echo
    echo "${RED}ERROR on line ${lineno}: ${cmd}${RESET}"
    echo
    sleep 10
}

trap 'on_error "$LINENO" "$BASH_COMMAND"' ERR

############################################################
# Functions
############################################################
configure_git() {
    local project
    project="$(basename "${SCRIPT_DIR}")"

    log_section "Configuring git for project: ${project}"
    log_info "https://github.com/kirodubes/${project}"

    git config --global pull.rebase false
    git config --global user.name "Kiro Dubes"
    git config --global user.email "kirodubes@gmail.com"
    sudo git config --system core.editor nano
    git config --global push.default simple

    git -C "${SCRIPT_DIR}" remote set-url origin "git@github.com-edu:kirodubes/${project}"

    log_success "Git configured — remote set to git@github.com-edu:kirodubes/${project}"
}

############################################################
# Main
############################################################
main() {
    configure_git

    log_success "$(basename "$0") done"
}

main "$@"
