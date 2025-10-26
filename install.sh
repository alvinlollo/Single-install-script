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
sudo pacman -Syu git zsh curl git build-essential whiptail uidmap

# Do not exit on fail
set +eux

curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/zsh.sh | bash

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
pacman -S uidmap --no-confirm
EOF
dockerd-rootless-setuptool.sh install

# Do not print commands
set +x
echo '
    --------------- Homebrew Install  ---------------

'
set -x

# Do not print commands
set +x
echo '
    --------------- packages Install  ---------------

'
set -x
# Install personal packages
sudo pacman -S figlet irssi cmatrix neofetch cowsay fortune-mod samba cifs-utils tty-clock lolcat libsass1 dpkg npm lynx wget tmux asciinema cava btop micro obsidian syncthing wine neovim

sudo pacman -S adobe-source-code-pro-fonts amd-ucode asciinema atomicparsley base bc bcachefs-tools blueman bluez-utils brightnessctl btop cava cliphist cowsay cuda-tools cython discord electron faac faad2 fastfetch firefox flatpak fzf gnome-2048 gnome-calculator gnome-chess  gnome-clocks gnome-disk-utility gnome-font-viewer gnome-online-accounts gnome-remote-desktop gnome-system-monitor gnome-weather gobject-introspection grub gst-plugins-base gst-plugins-ugly gst-python gtk-engine-murrine htop hypridle hyprland hyprlock hyprpolkitagent inxi jfsutils jq kdeconnect kitty kvantum libde265 libmp4v2 libmpcdec libreoffice-fresh libtorrent libva-nvidia-driver loupe lsd lutris lxc magic-wormhole mercurial mousepad mplayer mpv-mpris nano nvidia-dkms nvtop nwg-displays nwg-look obsidian pacman-contrib pamixer pavucontrol proton-pass-bin proton-vpn-gtk-app python-build python-hatchling python-installer python-pyquery python-wxpython qalculate-gtk qbittorrent qt5ct qt6ct rofi-wayland rust scdoc schroedinger screenfetch sddm sof-firmware swappy swaync swww syncthing ttf-fantasque-nerd ttf-fira-code ttf-jetbrains-mono ttf-jetbrains-mono-nerd typescript umockdev uriparser virtualbox waybar wayvnc wine yad zram-generator zsh-completions

sudo pacman -S git base-devel --needed
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

yay -S asciinema-agg asciinema-agg-debug celt celt-debug cloudflare-warp-bin cloudflare-warp-bin-debug davs2 davs2-debug dirb lib32-blas lib32-lzo lib32-lzo-debug mingw-w64-tools mingw-w64-tools-debug proton-pass-bin proton-pass-bin-debug python-ufonormalizer steam-devices-git websockify websockify-debug xwaylandvideobridge xwaylandvideobridge-debug zen-browser-bin

# LazyVim Install
mv ~/.config/nvim{,.bak}

# optional but recommended
cp ~/.local/share/nvim{,.bak} -r
cp ~/.local/state/nvim{,.bak} -r
cp ~/.cache/nvim{,.bak} -r

git clone https://github.com/LazyVim/starter ~/.config/nvim

rm -rf ~/.config/nvim/.git

# Do not print commands
set +x

# Done message :)
echo "Done installing please star my repo: https://github.com/alvinlollo/Single-install-script"
echo "Reboot reccommended, run zsh a few times to fix configurations"
