#!/bin/bash

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Sync and install dependencies
echo -e "${YELLOW}Updating system and installing required tools...${NC}"
sudo pacman -Syu --needed --noconfirm wget jq curl

# Base URL for Chaotic-AUR
BASE_URL="https://builds.garudalinux.org/repos/chaotic-aur/x86_64/"

# Fetch the latest package URL function
fetch_package_url() {
    local package_name="$1"
    local package_url
    package_url=$(curl -s "$BASE_URL" | grep -oP "${package_name}-[0-9][^\"]+\.pkg\.tar\.zst" | sort -V | tail -n 1)
    echo "${BASE_URL}${package_url}"
}

# Retrieve package URLs
echo -e "${YELLOW}Fetching Chaotic-AUR keyring and mirrorlist package URLs...${NC}"
KEYRING_URL=$(fetch_package_url "chaotic-keyring")
MIRRORLIST_URL=$(fetch_package_url "chaotic-mirrorlist")

# Verify URL fetch success
if [[ -z "$KEYRING_URL" || -z "$MIRRORLIST_URL" ]]; then
    echo -e "${RED}Error: Failed to retrieve one or more package URLs.${NC}"
    exit 1
fi

# Download packages
echo -e "${YELLOW}Downloading packages...${NC}"
wget -q "$KEYRING_URL" -O chaotic-keyring.pkg.tar.zst
wget -q "$MIRRORLIST_URL" -O chaotic-mirrorlist.pkg.tar.zst

# Install packages
echo -e "${YELLOW}Installing keyring and mirrorlist...${NC}"
sudo pacman -U --noconfirm --needed chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst

# Cleanup
rm -f chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst
echo -e "${GREEN}Chaotic-AUR keyring and mirrorlist installed successfully.${NC}"

# Configure pacman.conf
backup_file="/etc/pacman.conf.kiro"
new_conf="pacman.conf"
target="/etc/pacman.conf"

if [ -e "$backup_file" ]; then
    echo -e "${YELLOW}Backup already exists at $backup_file. Skipping backup.${NC}"
else
    echo -e "${YELLOW}Creating backup of $target...${NC}"
    if sudo cp -v "$target" "$backup_file"; then
        echo -e "${GREEN}Backup created successfully.${NC}"
    else
        echo -e "${RED}Backup failed. Aborting.${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}Overwriting $target with $new_conf...${NC}"
if sudo cp -v "$new_conf" "$target"; then
    echo -e "${GREEN}pacman.conf updated successfully.${NC}"
else
    echo -e "${RED}Failed to overwrite pacman.conf.${NC}"
    exit 1
fi

echo -e "${GREEN}Repositories 'nemesis_repo' and 'chaotic_aur' should now be configured.${NC}"
