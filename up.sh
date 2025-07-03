#!/bin/bash
#set -e

workdir=$(pwd)

./change-version.sh

echo "getting mirrorlist"
rm $workdir/archiso/airootfs/etc/pacman.d/mirrorlist
touch $workdir/archiso/airootfs/etc/pacman.d/mirrorlist
echo "## Best Arch Linux servers worldwide

Server = http://mirror.rackspace.com/archlinux/\$repo/os/\$arch
Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch
Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch
Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch
" | tee $workdir/archiso/airootfs/etc/pacman.d/mirrorlist
echo
echo "getting mirrorlist"
wget "https://archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4&ip_version=6" -O ->> $workdir/archiso/airootfs/etc/pacman.d/mirrorlist
sed -i "s/#Server/Server/g" $workdir/archiso/airootfs/etc/pacman.d/mirrorlist

# Below command will backup everything inside the project folder
git add --all .

# Committing to the local repository with a message containing the time details and commit text

git commit -m "update"

# Push the local files to github

if grep -q main .git/config; then
	echo "Using main"
		git push -u origin main
fi

if grep -q master .git/config; then
	echo "Using master"
		git push -u origin master
fi

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
tput sgr0
echo
