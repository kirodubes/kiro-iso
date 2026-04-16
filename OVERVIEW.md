# KIRO ISO - Project Overview

## What is KIRO?

**KIRO** is a customizable Arch Linux ISO builder that enables users to create personalized installation media with pre-configured packages, settings, and desktop environments. It's based on ArchISO and provides a comprehensive, reproducible build system for creating your own Arch-based distribution.

## Project Structure

```
kiro-iso/
├── archiso/                      # Core ISO build configuration
│   ├── airootfs/                # Root filesystem overlay
│   │   ├── etc/                 # System configuration files
│   │   ├── usr/                 # User-space binaries and data
│   │   └── root/                # Root user scripts and configs
│   ├── packages.x86_64          # Package list for x86_64 architecture
│   ├── profiledef.sh            # ISO profile definition
│   ├── pacman.conf              # Package manager configuration
│   └── grub/efiboot/syslinux/   # Boot loader configurations
├── build-scripts/               # Build automation scripts
├── personal_repo/               # Local package repository
├── enable-oomd.sh              # Out-of-Memory daemon setup script
├── change-version.sh           # Version management utility
└── up.sh                        # Update and maintenance script
```

## Key Components

### 1. **ISO Base**
- **Foundation**: Official Arch Linux tools (ArchISO)
- **Architecture**: x86_64
- **Boot Methods**: UEFI with systemd-boot and GRUB support
- **Init System**: systemd
- **Filesystem**: ext4 (default)
- **Display Manager**: SDDM with custom theming

### 2. **Desktop Environments**
- **Primary**: XFCE4 with extensive customization
- **Window Managers**: Ohmychadwm (modern tiling window manager with built-in menu system)
- Pre-configured themes, icons, and cursors
- Custom panel and taskbar configurations

### 3. **Package Categories**

#### System Utilities
- `base`, `base-devel` - Development tools and core utilities
- `archiso` - Live system components
- Boot loaders: `grub`, `refind`, `syslinux`
- Filesystem tools: `btrfs-progs`, `ntfs-3g`, `exfatprogs`, etc.
- System monitoring: `btop`, `glances`, `inxi`, `lm_sensors`

#### Installation & Recovery
- **Calamares**: User-friendly graphical installer
- `kiro-calamares-config`: Custom Calamares module configuration
- Live system tools: `clonezilla`, `fsarchiver`, `partclone`, `gparted`
- Disk utilities: `parted`, `gptfdisk`, `fdisk`, `testdisk`

#### Network & Connectivity
- **NetworkManager**: Network management suite
- VPN support: `openconnect`, `openvpn`, `networkmanager-vpnc`, `networkmanager-pptp`
- DNS/DHCP: `bind`, `dnsmasq`, `nss-mdns`, `avahi`
- Wireless: `iwd`, `wpa_supplicant`, `wireless-regdb`
- SSH: `openssh`, `wvdial`

#### Desktop Applications
- **Web Browsers**: Firefox, Chromium, Vivaldi (Brave for later builds)
- **Media**: VLC, FFmpeg, GStreamer (audio/video plugins)
- **Graphics**: GIMP, Inkscape, ImageMagick, Nomacs
- **Development**: VSCode, Sublime Text, Git, meld
- **Communication**: Signal Desktop, Shortwave (radio)
- **Utilities**: qBittorrent, yt-dlp, Simple Scan, File-roller

#### Audio & Video
- **Audio**: PulseAudio, ALSA, pavucontrol
- **Bluetooth**: Bluez, Blueberry (Bluetooth manager)
- **Video Drivers**: NVIDIA (open-source), Mesa
- **Codecs**: gst-libav, libdvdcss, all GStreamer plugins

#### Fonts & Icons
- **Fonts**: 
  - Noto Fonts, DejaVu, Ubuntu, Roboto, Hack
  - Material Design, JetBrains Mono, Meslo Nerd Font
  - Adobe Han Sans (Japanese, Korean, Chinese)
- **Icons**: Numix, Sardi, Surfn, Candy Icons
- **Cursors**: Bibata, Vimix, Beautyline

#### AUR & Custom Repositories
- **Chaotic AUR**: Precompiled packages from AUR
- **Nemesis Repo** (custom): Educational customizations
  - `edu-dot-files-git`: Configuration and dotfiles management
  - `edu-xfce-git`: XFCE customizations
  - `edu-shells-git`: Custom shell configurations
  - `edu-rofi-git`, `edu-rofi-themes-git`: Application launcher
  - `edu-polybar-git`: Custom statusbar
  - `ohmychadwm-git`: Modern tiling window manager with integrated menu and keybindings
  - `edu-variety-config-git`: Wallpaper manager presets
- **Package managers**: `paru-git`, `yay-git` (AUR helpers)
- **Downgrade**: Safely downgrade packages if needed

#### System Optimization & Performance
- **Scheduling**: `ananicy-cpp` with `cachyos-ananicy-rules-git` (intelligent task scheduling)
- **Power Management**: `irqbalance`, `tuned` (performance profile manager)
- **Memory**: `zram-generator` (compressed RAM swap)
- **DKMS Support**: `nvidia-open-dkms` for dynamic kernel module support
- **System Tuning**: `archlinux-tweak-tool-gtk4-git`
- **System Monitoring**: `glances`, `resources`, `sysz` (system information tools)

#### File Management
- **Virtual Filesystems**: `gvfs` with SMB, NFS, MTP, AFC support
- **Disk Management**: `udisks2`, `udiskie` (automounting)
- **Archive Tools**: `p7zip`, `unrar`, `unace`, `file-roller`

### 4. **Customization & Configuration**

#### Live System Scripts
- `root/.automated_script.sh` - Automated setup during live boot
- `etc/profile.d/userbin.sh` - Custom user PATH and environment

#### System Configuration
- **systemd-oomd**: Out-of-Memory daemon for proactive OOM management
  - 20-second reaction time with 60% memory pressure threshold
  - Memory pressure monitoring enabled
  - Swap-based killing disabled (graceful overflow)
- **Calamares modules**: Custom installation workflows
- **Pacman hooks**: Kernel installation automation

#### Display & Themes
- Multiple SDDM themes with simplicity variant
- Arc GTK theme and variants (Dawn, Mint)
- Neo-Candy theme collection
- Custom shell prompts and configurations

### 5. **Build System**

#### Build Scripts
- `build-scripts/` - Automated build processes
- `up.sh` - Update and rebuild utilities
- `change-version.sh` - Version management
- `enable-oomd.sh` - Post-installation OOM daemon setup (includes tuned parameters)

#### Configuration Files
- `archiso/profiledef.sh` - ISO metadata and build settings
- `archiso/pacman.conf` - Repository and signing configuration
- `archiso/bootstrap_packages` - Minimal bootstrap package set

#### Boot Configuration
- **GRUB**: Legacy BIOS boot
- **EFI Boot**: systemd-boot (preferred) and EFI shell
- **Syslinux**: Alternative boot option
- Custom boot splash screens

## Key Features

✅ **Reproducible Builds** - Consistent, script-driven ISO creation  
✅ **Highly Customizable** - Easy to add/remove packages and modify configs  
✅ **Modern Defaults** - UEFI, systemd, cgroups-v2 support  
✅ **Multiple DEs** - XFCE4 + Ohmychadwm (modern tiling window manager)  
✅ **Pre-configured** - Ready-to-use after installation with Calamares  
✅ **Performance Tuned** - Includes optimization tools and scheduler rules  
✅ **Educational Focus** - Comprehensive customization examples from Nemesis repo  
✅ **Community Repos** - Access to Chaotic AUR and custom repositories  

## Build Requirements

- **Host System**: Arch Linux or Arch-based distribution
- **Package**: `archiso` (for mkarchiso)
- **Permissions**: Root access for chroot operations
- **Space**: ~10-15GB for build environment
- **Knowledge**: Bash scripting, package management, ISO building concepts

## Usage Flow

1. **Configure** → Edit `packages.x86_64`
2. **Build** → Run build script from `build-scripts/`
3. **Test** → Boot live ISO in VM or on hardware
4. **Install** → Users run Calamares installer with your configuration
5. **Maintain** → Use `up.sh` and version scripts for updates

## Development Notes

### Recent Changes
- Calamares migrated from GitHub to Codeberg
- Deprecated `kiro-system-installation` package (functionality moved to Calamares modules)
- Enhanced `kiro-calamares-config` with modular approach
- Optimized systemd-oomd configuration for stability and performance

### Supported Architectures
- **Primary**: x86_64 (Intel/AMD)
- Extensible to other architectures via `packages.*` files

### Repository Integration
```ini
[kiro_repo]
SigLevel = Never
Server = https://kirodubes.github.io/$repo/$arch
```

---

## Integration with edu-dot-files

**`edu-dot-files-git`** is a foundational package in the KIRO ISO build process that provides:

- **Dotfiles Framework**: Pre-configured hidden configuration files for shells, editors, and applications
- **Environment Setup**: Consistent environment variables and PATH management
- **Profile Customization**: Templates for user configuration inheritance
- **Installation Integration**: Automatically deployed during Calamares installation
- **Educational Value**: Demonstrates best practices for Linux configuration management

The `edu-dot-files-git` package from the Nemesis repo is **integrated into the ISO build process** at the package level and is installed during installation via Calamares modules. This ensures that all users start with a well-configured system environment out of the box, maintaining consistency across different installations while remaining fully customizable.

---

**For more information**: See [README.md](README.md) and the YouTube tutorials referenced in the project documentation.
