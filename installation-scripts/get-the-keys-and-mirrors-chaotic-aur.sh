#!/bin/bash

######################################################################################################################

sudo pacman -Sy
sudo pacman -S wget --noconfirm --needed
sudo pacman -S jq --noconfirm --needed

# Set base URL
BASE_URL="https://builds.garudalinux.org/repos/chaotic-aur/x86_64/"

# Function to fetch latest package URL
fetch_package_url() {
    local package_name="$1"
    local package_url=$(curl -s "$BASE_URL" | grep -oP "${package_name}-[0-9][^\"]+\.pkg\.tar\.zst" | sort -V | tail -n 1)
    echo "$BASE_URL$package_url"
}

# Fetch latest versions of the required packages
KEYRING_URL=$(fetch_package_url "chaotic-keyring")
MIRRORLIST_URL=$(fetch_package_url "chaotic-mirrorlist")

# Check if the URLs were found
if [[ -z "$KEYRING_URL" || -z "$MIRRORLIST_URL" ]]; then
    echo "Error: Failed to retrieve package URLs. Check the website structure."
    exit 1
fi

# Download the packages
wget -q "$KEYRING_URL" -O chaotic-keyring.pkg.tar.zst
wget -q "$MIRRORLIST_URL" -O chaotic-mirrorlist.pkg.tar.zst

# Install the packages with pacman
sudo pacman -U --noconfirm --needed chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst

# Cleanup downloaded files
rm -f chaotic-keyring.pkg.tar.zst chaotic-mirrorlist.pkg.tar.zst

echo "Chaotic-AUR keyring and mirrorlist installed successfully."