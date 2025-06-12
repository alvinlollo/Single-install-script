#!/usr/bin/bash

clear
echo '
     ____                _       _       _       _ _
    | __ ) _   _    __ _| |_   _(_)_ __ | | ___ | | | ___
    |  _ \| | | |  / _  | \ \ / / |  _ \| |/ _ \| | |/ _ \
    | |_) | |_| | | (_| | |\ V /| | | | | | (_) | | | (_) |
    |____/ \__  |  \__ _|_| \_/ |_|_| |_|_|\___/|_|_|\___/
            |___/

    --------------- Single Download script ---------------
'

# Fail on any command.
set -eux pipefail

# Install prerequisites
sudo pacman -Syu git zsh curl git build-essential whiptail uidmap --no-confirm

# Do not print commands
set +x
echo '

    --------------- Oh-My-zsh Install  ---------------

'
# Print commands
set -x

sudo pacman -S zsh fzf --no-confirm

# Installs Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # Install plugins
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/z-shell/zsh-eza ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza
git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Enable exit on error
set -eu
set +x
echo '

    --------------- Oh-My-zsh plugins  ---------------

'
set -x
# Backup old config file if it exists
cp .zshrc .zshrc.backup

# Download and replace config file
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.zshrc -o ~/.zshrc

# Setup fzf
mkdir -p ~/.fzf/shell
touch ~/.fzf/shell/key-bindings.zsh

# Do not print commands
set +x
echo '
    --------------- Docker install  ---------------

'
set -x

# Do not fail (in case the OS is not supported)
set +eux
curl -fsSL https://get.docker.com | sh

# Fail on any command.
set -eux

# Install rootless mode
sudo sh -eux <<EOF
# Install newuidmap & newgidmap binaries
apt-get install -y uidmap
EOF
dockerd-rootless-setuptool.sh install

# Do not print commands
set +x
echo '
    --------------- apt packages Install  ---------------

'
set -x
# Install personal apt packages
sudo pacman -S python3 python3-pip git htop golang figlet irssi cmatrix neofetch cowsay fortune-mod tint smartmontools udevil samba cifs-utils mergerfs tty-clock lolcat libsass1 dpkg npm python3 needrestart lynx wget curl zsh net-tools tmux

sudo pacman -S adobe-source-code-pro-fonts amd-ucode asciinema atomicparsley base bc bcachefs-tools blueman bluez-utils brightnessctl btop cava cliphist cowsay cuda-tools cython discord electron faac faad2 fastfetch firefox flatpak fzf gnome-2048 gnome-calculator gnome-chess  gnome-clocks gnome-disk-utility gnome-font-viewer gnome-online-accounts gnome-remote-desktop gnome-system-monitor gnome-weather gobject-introspection grub gst-plugins-base gst-plugins-ugly gst-python gtk-engine-murrine htop hypridle hyprland hyprlock hyprpolkitagent inxi jfsutils jq kdeconnect kitty kvantum libde265 libmp4v2 libmpcdec libreoffice-fresh libtorrent libva-nvidia-driver loupe lsd lutris lxc magic-wormhole mercurial micro mousepad mplayer mpv-mpris nano nvidia-dkms nvtop nwg-displays nwg-look obsidian pacman-contrib pamixer pavucontrol proton-pass-bin proton-vpn-gtk-app python-build python-hatchling python-installer python-pyquery python-wxpython qalculate-gtk qbittorrent qt5ct qt6ct rofi-wayland rust scdoc schroedinger screenfetch sddm sof-firmware swappy swaync swww syncthing ttf-fantasque-nerd ttf-fira-code ttf-jetbrains-mono ttf-jetbrains-mono-nerd typescript umockdev uriparser virtualbox waybar wayvnc wine yad zram-generator zsh-completions

sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

yay -S asciinema-agg asciinema-agg-debug celt celt-debug cloudflare-warp-bin cloudflare-warp-bin-debug davs2 davs2-debug lib32-blas lib32-lzo lib32-lzo-debug mingw-w64-tools mingw-w64-tools-debug proton-pass-bin proton-pass-bin-debug python-ufonormalizer steam-devices-git websockify websockify-debug xwaylandvideobridge xwaylandvideobridge-debug zen-browser-bin

# Do not print commands
set +x

# Done message :)
echo "Done installing please star my repo: https://github.com/alvinlollo/Single-install-script"
echo "Reboot reccommended, run zsh a few times to fix configurations"
