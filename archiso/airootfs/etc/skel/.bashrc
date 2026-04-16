### EDU-SHELLS
### EXPORT ###
export EDITOR='nano'
export VISUAL='nano'
export HISTCONTROL=ignoreboth:erasedups
export PAGER='most'

#Ibus settings if you need them
#type ibus-setup in terminal to change settings and start the daemon
#delete the hashtags of the next lines and restart
#export GTK_IM_MODULE=ibus
#export XMODIFIERS=@im=dbus
#export QT_IM_MODULE=ibus

PS1='[\u@\h \W]\$ '

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [ -d "$HOME/.bin" ]; then
  case ":$PATH:" in
    *":$HOME/.bin:"*) ;;
    *) PATH="$HOME/.bin:$PATH" ;;
  esac
fi

if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi

#ignore upper and lowercase when TAB completion
bind "set completion-ignore-case on"

### ALIASES ###

#list
alias ls='ls --color=auto'
alias la='ls -a'
alias ll='ls -alFh'
alias l='ls'
alias l.="ls -A | egrep '^\.'"
alias listdir="ls -d */ > list"

#pacman
alias sps='sudo pacman -S'
alias spr='sudo pacman -R'
alias sprs='sudo pacman -Rs'
alias sprdd='sudo pacman -Rdd'
alias spqo='sudo pacman -Qo'
alias spsii='sudo pacman -Sii'

# show the list of packages that need this package - depends mpv as example
function_depends()  {
    search=$(echo "$1")
    sudo pacman -Sii $search | grep "Required" | sed -e "s/Required By     : //g" | sed -e "s/  /\n/g"
    }

alias depends='function_depends'

#fix obvious typo's
alias cd..='cd ..'
alias pdw='pwd'
alias udpate='sudo pacman -Syyu'
alias upate='sudo pacman -Syyu'
alias updte='sudo pacman -Syyu'
alias updqte='sudo pacman -Syyu'
alias upqll='paru -Syu --noconfirm'
alias upal='paru -Syu --noconfirm'
alias u="sudo pacman -Syu"

## Colorize the grep command output for ease of use (good for log files)##
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

#readable output
alias df='df -h'

#keyboard
alias give-me-azerty-be="sudo localectl set-x11-keymap be"
alias give-me-qwerty-us="sudo localectl set-x11-keymap us"

#setlocale
alias setlocale="sudo localectl set-locale LANG=en_US.UTF-8"
alias setlocales="sudo localectl set-x11-keymap be && sudo localectl set-locale LANG=en_US.UTF-8"

#pacman unlock
alias unlock="sudo rm /var/lib/pacman/db.lck"
alias rmpacmanlock="sudo rm /var/lib/pacman/db.lck"

#logout unlock
alias rmlogoutlock="sudo rm /tmp/arcologout.lock"

#which graphical card is working
alias whichvga="/usr/local/bin/edu-which-vga"

#free
alias free="free -mt"

#continue download
alias wget="wget -c"

#userlist
alias userlist="cut -d: -f1 /etc/passwd | sort"

#merge new settings
alias merge="xrdb -merge ~/.Xresources"

# Aliases for software managment
# pacman or pm
alias pacman='sudo pacman --color auto'
alias update='sudo pacman -Syyu'
alias upd='sudo pacman -Syyu'

# paru as aur helper - updates everything
alias pksyua="paru -Syu --noconfirm"
alias upall="paru -Syu --noconfirm"
alias upa="paru -Syu --noconfirm"

#ps
alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"

#grub update
alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias grub-update="sudo grub-mkconfig -o /boot/grub/grub.cfg"
#grub issue 08/2022
alias install-grub-efi="sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArcoLinux"

#add new fonts
alias update-fc='sudo fc-cache -fv'

#copy/paste all content of /etc/skel over to home folder - backup of config created - beware
#skel alias has been replaced with a script at /usr/local/bin/skel

#backup contents of /etc/skel to hidden backup folder in home/user
alias bupskel='cp -Rf /etc/skel ~/.skel-backup-$(date +%Y.%m.%d-%H.%M.%S)'

#copy shell configs
alias cb='cp /etc/skel/.bashrc ~/.bashrc && exec bash'
alias cz='cp /etc/skel/.zshrc ~/.zshrc && echo "Copied."'
alias cf='cp /etc/skel/.config/fish/config.fish ~/.config/fish/config.fish && echo "Copied."'

#switch between bash and zsh
alias tobash="sudo chsh $USER -s /bin/bash && echo 'Now log out.'"
alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Now log out.'"
alias tofish="sudo chsh $USER -s /bin/fish && echo 'Now log out.'"

#switch between displaymanager or bootsystem
alias tolightdm="sudo pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings --noconfirm --needed ; sudo systemctl enable lightdm.service -f ; echo 'Lightm is active - reboot now'"
alias tosddm="sudo pacman -S sddm --noconfirm --needed ; sudo systemctl enable sddm.service -f ; echo 'Sddm is active - reboot now'"
alias toly="sudo pacman -S ly --noconfirm --needed ; sudo systemctl enable ly.service -f ; echo 'Ly is active - reboot now'"
alias togdm="sudo pacman -S gdm --noconfirm --needed ; sudo systemctl enable gdm.service -f ; echo 'Gdm is active - reboot now'"
alias tolxdm="sudo pacman -S lxdm --noconfirm --needed ; sudo systemctl enable lxdm.service -f ; echo 'Lxdm is active - reboot now'"
alias toemptty="sudo pacman -S emptty --noconfirm --needed ; sudo systemctl enable emptty.service -f ; echo 'Emptty is active - reboot now'"

# kill commands
# quickly kill conkies
alias kc='killall conky'
# quickly kill polybar
alias kp='killall polybar'
# quickly kill picom
alias kpi='killall picom'

# hardware info --short
alias hw="hwinfo --short"

# fastfetch --short
alias ff="fastfetch"
alias neo="neofetch"

# audio check pulseaudio or pipewire
alias audio="pactl info | grep 'Server Name'"

# skip integrity check
alias paruskip='paru -S --mflags --skipinteg'
alias yayskip='yay -S --mflags --skipinteg'
alias trizenskip='trizen -S --skipinteg'

# check vulnerabilities microcode
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'

#approximation of how old your hardware is
alias howold="sudo lshw | grep -B 3 -A 8 BIOS"

#check cpu
alias cpu="cpuid -i | grep uarch | head -n 1"

#get fastest mirrors in your neighborhood
alias mirror="sudo reflector -f 30 -l 30 --number 10 --verbose --save /etc/pacman.d/mirrorlist"
alias mirrord="sudo reflector --latest 30 --number 10 --sort delay --save /etc/pacman.d/mirrorlist"
alias mirrors="sudo reflector --latest 30 --number 10 --sort score --save /etc/pacman.d/mirrorlist"
alias mirrora="sudo reflector --latest 30 --number 10 --sort age --save /etc/pacman.d/mirrorlist"
#our experimental - best option for the moment
alias mirrorx="sudo reflector --age 6 --latest 20  --fastest 20 --threads 5 --sort rate --protocol https --save /etc/pacman.d/mirrorlist"
alias mirrorxx="sudo reflector --age 6 --latest 20  --fastest 20 --threads 20 --sort rate --protocol https --save /etc/pacman.d/mirrorlist"
alias ram='rate-mirrors --allow-root --disable-comments arch | sudo tee /etc/pacman.d/mirrorlist'
alias rams='rate-mirrors --allow-root --disable-comments --protocol https arch  | sudo tee /etc/pacman.d/mirrorlist'

#enabling vmware services
alias start-vmware="sudo systemctl enable --now vmtoolsd.service"
alias vmware-start="sudo systemctl enable --now vmtoolsd.service"
alias sv="sudo systemctl enable --now vmtoolsd.service"

#shopt
shopt -s autocd # change to named directory
shopt -s cdspell # autocorrects cd misspellings
shopt -s cmdhist # save multi-line commands in history as single line
shopt -s dotglob
shopt -s histappend # do not overwrite history
shopt -s expand_aliases # expand aliases

#youtube download
alias yta-aac="yt-dlp --extract-audio --audio-format aac "
alias yta-best="yt-dlp --extract-audio --audio-format best "
alias yta-flac="yt-dlp --extract-audio --audio-format flac "
alias yta-mp3="yt-dlp --extract-audio --audio-format mp3 "
alias ytv-best="yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio' --merge-output-format mp4 "

#Recent Installed Packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
alias riplong="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -3000 | nl"

#Cleanup orphaned packages
alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'

# This will generate a list of explicitly installed packages
alias list="sudo pacman -Qqe"
#This will generate a list of explicitly installed packages without dependencies
alias listt="sudo pacman -Qqet"
# list of AUR packages
alias listaur="sudo pacman -Qqem"
# add > list at the end to write to a file

# install packages from list
# pacman -S --needed - < my-list-of-packages.txt

#clear
alias clean="clear; seq 1 $(tput cols) | sort -R | sparklines | lolcat"
alias cls="clear; seq 1 $(tput cols) | sort -R | sparklines | lolcat"

#search content with ripgrep
alias rg="rg --sort path"

#get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"

#nano for important configuration files
#know what you do in these files
alias nlxdm="sudo $EDITOR /etc/lxdm/lxdm.conf"
alias nlightdm="sudo $EDITOR /etc/lightdm/lightdm.conf"
alias npacman="sudo $EDITOR /etc/pacman.conf"
alias ngrub="sudo $EDITOR /etc/default/grub"
alias nconfgrub="sudo $EDITOR /boot/grub/grub.cfg"
alias nmakepkg="sudo $EDITOR /etc/makepkg.conf"
alias nmkinitcpio="sudo $EDITOR /etc/mkinitcpio.conf"
alias nmirrorlist="sudo $EDITOR /etc/pacman.d/mirrorlist"
alias nchaoticmirrorlist="sudo $EDITOR /etc/pacman.d/chaotic-mirrorlist"
alias nsddm="sudo $EDITOR /etc/sddm.conf"
alias nsddmk="sudo $EDITOR /etc/sddm.conf.d/kde_settings.conf"
alias nsddmd="sudo $EDITOR /usr/lib/sddm/sddm.conf.d/default.conf"
alias nfstab="sudo $EDITOR /etc/fstab"
alias nnsswitch="sudo $EDITOR /etc/nsswitch.conf"
alias nsamba="sudo $EDITOR /etc/samba/smb.conf"
alias ngnupgconf="sudo $EDITOR /etc/pacman.d/gnupg/gpg.conf"
alias nhosts="sudo $EDITOR /etc/hosts"
alias nhostname="sudo $EDITOR /etc/hostname"
alias nresolv="sudo $EDITOR /etc/resolv.conf"
alias nb="$EDITOR ~/.bashrc"
alias nz="$EDITOR ~/.zshrc"
alias nf="$EDITOR ~/.config/fish/config.fish"
alias nneofetch="$EDITOR ~/.config/neofetch/config.conf"
alias nfastfetch="$EDITOR ~/.config/fastfetch/config.jsonc"
alias nplymouth="sudo $EDITOR /etc/plymouth/plymouthd.conf"
alias nvconsole="sudo $EDITOR /etc/vconsole.conf"
alias nenvironment="sudo $EDITOR /etc/environment"
alias nloader="sudo $EDITOR /boot/efi/loader/loader.conf"
alias nrefind="sudo $EDITOR /boot/refind_linux.conf"
alias nalacritty="nano /home/$USER/.config/alacritty/alacritty.toml"
alias nemptty="sudo $EDITOR /etc/emptty/conf"
alias nkitty="$EDITOR ~/.config/kitty/kitty.conf"
alias npicom="$EDITOR ~/.config/arco-chadwm/picom/picom.conf"

#removing packages
alias rvariety="edu-remove-variety"
alias rkmix="edu-remove-kmix"
alias rconky="edu-remove-conky"

#reading logs with bat
alias lcalamares="bat /var/log/Calamares.log"
alias lpacman="bat /var/log/pacman.log"
alias lxorg="bat /var/log/Xorg.0.log"
alias lxorgo="bat /var/log/Xorg.0.log.old"

#reading logs with sublime-text-4
alias scal="subl /var/log/Calamares.log"
alias spac="subl /etc/pacman.conf"

#gpg
#verify signature for isos
alias gpg-check="gpg2 --keyserver-options auto-key-retrieve --verify"
alias fix-gpg-check="gpg2 --keyserver-options auto-key-retrieve --verify"
#receive the key of a developer
alias gpg-retrieve="gpg2 --keyserver-options auto-key-retrieve --receive-keys"
alias fix-gpg-retrieve="gpg2 --keyserver-options auto-key-retrieve --receive-keys"
alias fix-keyserver="[ -d ~/.gnupg ] || mkdir ~/.gnupg ; cp /etc/pacman.d/gnupg/gpg.conf ~/.gnupg/ ; echo 'done'"

#fixes
alias fix-permissions="sudo chown -R $USER:$USER ~/.config ~/.local"
alias keyfix="/usr/local/bin/edu-fix-pacman-databases-and-keys"
alias key-fix="/usr/local/bin/edu-fix-pacman-databases-and-keys"
alias keys-fix="/usr/local/bin/edu-fix-pacman-databases-and-keys"
alias fixkey="/usr/local/bin/edu-fix-pacman-databases-and-keys"
alias fixkeys="/usr/local/bin/edu-fix-pacman-databases-and-keys"
alias fix-key="/usr/local/bin/edu-fix-pacman-databases-and-keys"
alias fix-keys="/usr/local/bin/edu-fix-pacman-databases-and-keys"
alias fix-pacman-conf="/usr/local/bin/edu-fix-pacman-conf"
alias fix-pacman-keyserver="/usr/local/bin/edu-fix-pacman-gpg-conf"
alias fix-archlinux-mirrors="/usr/local/bin/edu-fix-archlinux-servers"

#maintenance
alias big="expac -H M '%m\t%n' | sort -h | nl"

#hblock (stop tracking with hblock)
#use unhblock to stop using hblock
alias unhblock="hblock -S none -D none"

#systeminfo
alias probe="sudo edu-probe"
alias sysfailed="systemctl list-units --failed"

#shutdown or reboot
alias ssn="sudo shutdown now"
alias sr="reboot"

#give the list of all installed desktops - xsessions desktops
alias xd="ls /usr/share/xsessions"
alias xdw="ls /usr/share/wayland-sessions"

#give a list of the kernels installed
alias kernel="ls /usr/lib/modules"
alias kernels="ls /usr/lib/modules"

# # ex = EXtractor for all kinds of archives
# # usage: ex <file>
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *.deb)       ar x $1      ;;
      *.tar.xz)    tar xf $1    ;;
      *.tar.zst)   tar xf $1    ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}


#git
alias rmgitcache="rm -r ~/.cache/git"
alias grh="git reset --hard"

#pamac
alias pamac-unlock="sudo rm /var/tmp/pamac/dbs/db.lock"

#create a file called .bashrc-personal and put all your personal aliases
#in there. They will not be overwritten by skel.

[[ -f ~/.bashrc-personal ]] && . ~/.bashrc-personal

# reporting tools - leave this in for ATT
#fastfetch