#!/bin/bash
set -eo pipefail
##################################################################################################################
# Author    : Erik Dubois
# Website   : https://www.erikdubois.be
# Youtube   : https://youtube.com/erikdubois
# Github    : https://github.com/erikdubois
# Github    : https://github.com/kirodubes
# Github    : https://github.com/buildra
# SF        : https://sourceforge.net/projects/kiro/files/
##################################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
##################################################################################################################
#tput setaf 0 = black
#tput setaf 1 = red
#tput setaf 2 = green
#tput setaf 3 = yellow
#tput setaf 4 = dark blue
#tput setaf 5 = purple
#tput setaf 6 = cyan
#tput setaf 7 = gray
#tput setaf 8 = light blue
##################################################################################################################

# variables and functions
workdir=$(pwd)

##################################################################################################################

./change-version.sh

##################################################################################################################
# Toggle mirrorlist fetch
USE_MIRRORLIST_FETCH=true

get_mirrorlist () {
    echo "getting mirrorlist (static)"
    rm -f "$workdir/archiso/airootfs/etc/pacman.d/mirrorlist"
    cat <<EOF > "$workdir/archiso/airootfs/etc/pacman.d/mirrorlist"
## Best Arch Linux servers worldwide

Server = https://mirror.osbeck.com/archlinux/\$repo/os/\$arch
Server = http://mirror.rackspace.com/archlinux/\$repo/os/\$arch
Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch
Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch
Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch
EOF

    echo
    echo "getting mirrorlist (official)"
    wget -q -O - "https://archlinux.org/mirrorlist/?ip_version=6" \
  | tee -a "$workdir/archiso/airootfs/etc/pacman.d/mirrorlist" >/dev/null
    sed -i "s/#Server/Server/g" "$workdir/archiso/airootfs/etc/pacman.d/mirrorlist"
}

##################################################################################################################
# Run mirrorlist fetch if enabled
if [ "$USE_MIRRORLIST_FETCH" = true ]; then
    get_mirrorlist
else
    echo "Skipping mirrorlist fetch (USE_MIRRORLIST_FETCH=$USE_MIRRORLIST_FETCH)"
fi

##################################################################################################################
# Git workflow
git add --all .
git commit -m "update"

branch=$(git rev-parse --abbrev-ref HEAD)
git push -u origin "$branch"

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename "$0") done"
echo "##############################################################"
tput sgr0
echo
