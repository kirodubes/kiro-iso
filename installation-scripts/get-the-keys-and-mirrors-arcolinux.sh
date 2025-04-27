#!/bin/bash

######################################################################################################################

sudo pacman -Sy
sudo pacman -S wget --noconfirm --needed
sudo pacman -S jq --noconfirm --needed

# old code

# echo "Getting the ArcoLinux keys from the ArcoLinux repo - report if link is broken"
# sudo wget https://github.com/arcolinux/arcolinux_repo/raw/main/x86_64/arcolinux-keyring-20251209-3-any.pkg.tar.zst -O /tmp/arcolinux-keyring-20251209-3-any.pkg.tar.zst
# sudo pacman -U --noconfirm /tmp/arcolinux-keyring-20251209-3-any.pkg.tar.zst

# echo "Getting the latest arcolinux mirrors file - report if link is broken"
# sudo wget https://github.com/arcolinux/arcolinux_repo/raw/main/x86_64/arcolinux-mirrorlist-git-24.03-12-any.pkg.tar.zst -O /tmp/arcolinux-mirrorlist-git-24.03-12-any.pkg.tar.zst
# sudo pacman -U --noconfirm /tmp/arcolinux-mirrorlist-git-24.03-12-any.pkg.tar.zst

# New code

arco_repo_db=$(wget -qO- https://api.github.com/repos/arcolinux/arcolinux_repo/contents/x86_64)

echo "Getting the ArcoLinux keys"
sudo wget "$(echo "$arco_repo_db" | jq -r '[.[] | select(.name | contains("arcolinux-keyring")) | .name] | .[0] | sub("arcolinux-keyring-"; "https://github.com/arcolinux/arcolinux_repo/raw/main/x86_64/arcolinux-keyring-")')" -O /tmp/arcolinux-keyring-git-any.pkg.tar.zst
sudo pacman -U --noconfirm --needed /tmp/arcolinux-keyring-git-any.pkg.tar.zst

echo "Getting the ArcoLinux mirrors"
sudo wget "$(echo "$arco_repo_db" | jq -r '[.[] | select(.name | contains("arcolinux-mirrorlist-git-")) | .name] | .[0] | sub("arcolinux-mirrorlist-git-"; "https://github.com/arcolinux/arcolinux_repo/raw/main/x86_64/arcolinux-mirrorlist-git-")')" -O /tmp/arcolinux-mirrorlist-git-any.pkg.tar.zst
sudo pacman -U --noconfirm --needed /tmp/arcolinux-mirrorlist-git-any.pkg.tar.zst

