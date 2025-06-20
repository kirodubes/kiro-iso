#!/bin/bash

# Create the new version
year=$(date +%y)   # last two digits of the year
month=$(date +%m)  # month number
day=$(date +%d)    # day of the month
extra="01"         # You can manually bump this if needed

newversion="v${year}.${month}.${day}.${extra}"
echo "New Version: $newversion"

# Detect old versions in each file separately
old_devrel=$(grep -oP 'v\d{2}\.\d{2}\.\d{2}' archiso/airootfs/etc/dev-rel | head -1)
old_buildiso=$(grep -oP "kiroVersion='v\d{2}\.\d{2}\.\d{2}'" installation-scripts/build-the-iso.sh | grep -oP 'v\d{2}\.\d{2}\.\d{2}' | head -1)
old_profiledef=$(grep -oP 'kiro-v\d{2}\.\d{2}\.\d{2}' archiso/profiledef.sh | grep -oP 'v\d{2}\.\d{2}\.\d{2}' | head -1)
old_isoversion=$(grep -oP 'iso_version="v\d{2}\.\d{2}\.\d{2}"' archiso/profiledef.sh | grep -oP 'v\d{2}\.\d{2}\.\d{2}' | head -1)

# Debug output
echo "Old version in dev-rel     : $old_devrel"
#echo "Old version in build-the-iso: $old_buildiso"
echo "Old version in profiledef  : $old_profiledef"
#echo "Old iso_version in profiledef: $old_isoversion"

# Replace entire ISO_RELEASE=... line
sed -i "s|^ISO_RELEASE=.*|ISO_RELEASE=$newversion|" archiso/airootfs/etc/dev-rel

# Replace entire kiroVersion='...' line
sed -i "s|\(.*kiroVersion='\)[^']*\('.*\)|\1$newversion\2|" installation-scripts/build-the-iso.sh

# Replace entire iso_label="kiro-..." line
sed -i "s|^iso_label=\"kiro-.*\"|iso_label=\"kiro-$newversion\"|" archiso/profiledef.sh

# Replace entire iso_version="..." line
sed -i "s|^iso_version=\"v.*\"|iso_version=\"$newversion\"|" archiso/profiledef.sh

# Final message
echo "#############################################################################################"
echo "################  $(basename "$(pwd)") version updated to $newversion"
echo "#############################################################################################"