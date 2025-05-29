#!/bin/bash

# Colors
green=$(tput setaf 2)
red=$(tput setaf 1)
reset=$(tput sgr0)

# Sync and install dependencies
sudo pacman -Syu --needed --noconfirm wget jq curl

# Base URL
BASE_URL="https://builds.garudalinux.org/repos/chaotic-aur/x86_64/"

# Fetch the latest package URL function
fetch_package_url() {
    local package_name="$1"
    local package_url
    package_url=$(curl -s "$BASE_URL" | grep -oP "${package_name}-[0-9][^\"]+\.pkg\.tar\.zst" | sort -V | tail -n 1)
    echo "${BASE_URL}${package_url}"
}

# Retrieve URLs
KEYRING_URL=$(fetch_package_url "chaotic-keyring")
MIRRORLIST_URL=$(fetch_package_url "chaotic-mirrorlist")

# Verify URLs
if [[ -z "$KEYRING_URL" || -z "$MIRRORLIST_URL" ]]; then
    echo "${red}Error: Failed to retrieve package URLs.${reset}"
    exit 1
fi

# Download
wget -q "$KEYRING_URL" -O chaotic-keyring.pkg.tar.zst
wget -q "$MIRRORLIST_URL" -O chaotic-mirrorlist.pkg.tar.zst

# Install
sudo pacman -U --noconfirm --needed chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst

# Cleanup
rm -f chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst

echo "${green}Chaotic-AUR keyring and mirrorlist installed successfully.${reset}"
