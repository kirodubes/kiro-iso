#!/bin/bash
#set -e
# Color definitions
tput setaf 2 # green for info messages
tput setaf 3 # yellow for warnings
tput setaf 1 # red for errors

##################################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
##################################################################################################################

# Functions
clean_cache() {
    if [[ "$1" == "yes" ]]; then
        echo "##################################################################"
        tput setaf 2
        echo "Cleaning the cache from /var/cache/pacman/pkg/"
        tput sgr0
        echo "##################################################################"
        yes | sudo pacman -Scc
    elif [[ "$1" == "no" ]]; then
        echo "Skipping cache cleaning."
    else
        echo "Invalid option. Use: clean_cache yes | clean_cache no"
    fi
}

remove_buildfolder() {
    if [[ -z "$buildFolder" ]]; then
        tput setaf 1
        echo "Error: \$buildFolder is not set."
        tput sgr0
        return 1
    fi

    if [[ "$1" == "yes" ]]; then
        if [[ -d "$buildFolder" ]]; then
            echo "##################################################################"
            tput setaf 3
            echo "Deleting the build folder ($buildFolder)..."
            tput sgr0
            sudo rm -rf "$buildFolder"
            echo "##################################################################"
        else
            echo "No build folder found. Nothing to delete."
        fi
    elif [[ "$1" == "no" ]]; then
        echo "Skipping build folder removal."
    else
        echo "Invalid option. Use: remove_buildfolder yes | remove_buildfolder no"
    fi
}

# Initial setup
installed_dir=$(dirname $(readlink -f $(basename `pwd`)))

echo
echo "##################################################################"
tput setaf 3
echo "Important Notes:"
echo "1. Do not run as root"
echo "2. Btrfs users should make backups first"
echo "3. You can add local repos if needed"
tput sgr0
echo "##################################################################"
echo

sleep 3

# Btrfs warning
if lsblk -f | grep -q btrfs; then
    echo "##################################################################"
    tput setaf 3
    echo "Btrfs filesystem detected - use with caution!"
    echo "Press CTRL+C to cancel (10 second wait)"
    tput sgr0
    echo "##################################################################"
    for i in $(seq 10 -1 1); do
        echo -ne "Continuing in $i seconds... \r"
        sleep 1
    done
    echo
fi

##################################################################
# Phase 1: Set Parameters
##################################################################
echo
echo "##################################################################"
tput setaf 2
echo "Phase 1: Setting Parameters"
tput sgr0
echo "##################################################################"

# Prompt for custom distro name
echo
tput setaf 6
echo "Choose a name for your distro build (e.g., 'MyCustomDistro'):"
tput sgr0
read -p "Distro name (leave empty for default 'DacOS'): " customName

# Set default if empty
if [[ -z "$customName" ]]; then
    customName="DacOS"
else
    # Remove special characters and spaces, keep only alphanumeric and hyphen
    customName=$(echo "$customName" | tr -dc '[:alnum:]-')
fi

desktop="xfce"

# Version handling
current_year=$(date +'%y')
current_month=$(date +'%m')
current_day=$(date +'%d')

version_file="$HOME/.${customName,,}_version_counter"
if [[ -f "$version_file" ]]; then
    last_build_date=$(head -n1 "$version_file")
    counter=$(tail -n1 "$version_file")
    
    if [[ "$last_build_date" == "${current_year}${current_month}${current_day}" ]]; then
        ((counter++))
    else
        counter=1
    fi
else
    counter=1
fi

# Save new version info
echo "${current_year}${current_month}${current_day}" > "$version_file"
echo "$counter" >> "$version_file"

dacosVersion="v${current_year}.${current_month}.${current_day}.${counter}"
isoName="${customName}-${dacosVersion}-x86_64"
isoLabel="${isoName}.iso"

# General parameters
archisoRequiredVersion="archiso 83-1"
buildFolder="$HOME/dacos-build"
outFolder="$HOME/dacos-Out"

# Chaotic-AUR setup
chaoticsrepo=true
if [[ "$chaoticsrepo" == "true" ]]; then
    if ! pacman -Q chaotic-keyring &>/dev/null || ! pacman -Q chaotic-mirrorlist &>/dev/null; then
        if [[ -f "$installed_dir/get-the-keys-and-mirrors-chaotic-aur.sh" ]]; then
            echo "Installing Chaotic-AUR packages..."
            bash "$installed_dir/get-the-keys-and-mirrors-chaotic-aur.sh"
        else
            tput setaf 1
            echo "Error: Chaotic-AUR script not found!"
            tput sgr0
            exit 1
        fi
    fi
fi

##################################################################
# Phase 2: Check Dependencies
##################################################################
echo
echo "##################################################################"
tput setaf 2
echo "Phase 2: Checking Dependencies"
tput sgr0
echo "##################################################################"

for package in archiso grub; do
    if ! pacman -Qi $package &>/dev/null; then
        echo "Installing $package..."
        sudo pacman -S --noconfirm $package || {
            tput setaf 1
            echo "Failed to install $package!"
            tput sgr0
            exit 1
        }
    else
        echo "$package is already installed"
    fi
done

# Show overview
echo
echo "##################################################################"
tput setaf 2
echo "Build Overview:"
tput sgr0
echo "Desktop:        $desktop"
echo "Version:        $dacosVersion"
echo "ISO Name:       $isoLabel"
echo "Build Folder:   $buildFolder"
echo "Output Folder:  $outFolder"
echo "##################################################################"
echo

##################################################################
# Phase 3-4: Prepare Build Environment
##################################################################
echo
echo "##################################################################"
tput setaf 2
echo "Phase 3-4: Preparing Build Environment"
tput sgr0
echo "##################################################################"

remove_buildfolder yes
mkdir -p "$buildFolder"
cp -r ../archiso "$buildFolder/archiso"

# Setup skel
rm -rf "$buildFolder/archiso/airootfs/etc/skel/.*" 2>/dev/null
wget https://raw.githubusercontent.com/erikdubois/edu-shells/main/etc/skel/.bashrc-latest \
     -O "$buildFolder/archiso/airootfs/etc/skel/.bashrc"

# Update packages list
rm -f "$buildFolder/archiso/packages.x86_64"
cp -f ../archiso/packages.x86_64 "$buildFolder/archiso/packages.x86_64"

##################################################################
# Phase 5: Final Build Prep
##################################################################
echo
echo "##################################################################"
tput setaf 2
echo "Phase 5: Final Preparation"
tput sgr0
echo "##################################################################"

date_build=$(date -d now)
sudo sed -i "s/\(^ISO_BUILD=\).*/\1$date_build/" "$buildFolder/archiso/airootfs/etc/dev-rel"
clean_cache no

##################################################################
# Phase 7: Build ISO
##################################################################
echo
echo "##################################################################"
tput setaf 2
echo "Phase 7: Building ISO This may take a while..."
tput sgr0
echo "##################################################################"

# Update the Archiso configuration with our custom name
echo "Updating Archiso configuration with custom name..."
sudo sed -i "s/^iso_name = .*/iso_name = ${customName}/" "$buildFolder/archiso/profiledef.sh"
sudo sed -i "s/^iso_label = .*/iso_label = ${isoName}/" "$buildFolder/archiso/profiledef.sh"
sudo sed -i "s/^iso_version = .*/iso_version = ${dacosVersion}/" "$buildFolder/archiso/profiledef.sh"

mkdir -p "$outFolder"
cd "$buildFolder/archiso/"
sudo mkarchiso -v -w "$buildFolder" -o "$outFolder" "$buildFolder/archiso/"

##################################################################
# Phase 8: Create Checksums and Metadata
##################################################################
echo
echo "##################################################################"
tput setaf 2
echo "Phase 8: Generating Checksums and Metadata"
tput sgr0
echo "##################################################################"

cd "$outFolder"

# Rename the ISO to match our naming convention
built_iso=$(ls *.iso 2>/dev/null)
if [[ -n "$built_iso" && "$built_iso" != "$isoLabel" ]]; then
    mv "$built_iso" "$isoLabel"
fi

# Generate checksums
for algo in sha1 sha256 md5; do
    ${algo}sum "$isoLabel" > "${isoName}.${algo}"
done

# Copy package list
cp "$buildFolder/iso/arch/pkglist.x86_64.txt" "${isoName}.pkglist.txt"

##################################################################
# Phase 9: Cleanup
##################################################################
echo
echo "##################################################################"
tput setaf 2
echo "Phase 9: Cleanup"
tput sgr0
echo "##################################################################"

remove_buildfolder no

##################################################################
# Completion
##################################################################
echo
echo "##################################################################"
tput setaf 2
echo "Build Complete!"
echo "Output files in: $outFolder"
ls -lh "$outFolder/$isoName".*
tput sgr0
echo "##################################################################"
