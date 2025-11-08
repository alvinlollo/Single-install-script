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
sudo pacman -Syu git zsh curl git --noconfirm --needed

# Do not exit on fail
set +eux

curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/zsh.sh | bash

curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/LazyVim.sh | bash

# Do not print commands
set +x
echo '
    --------------- Docker install  ---------------

'
set -x

# Do not fail (in case the OS is not supported)
set +eux

if ! command -v docker >/dev/null; then
  echo "docker is NOT installed. Running installation commands..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker $USER
fi

# Do not print commands
set +x
echo '
    --------------- Packages Install  ---------------

'
set -x
# Install personal Packages

curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/PackagesPacman.txt | sudo pacman -S - --needed --noconfirm

sudo pacman -S --needed -noconfirm efibootmgr sbsigntools mokutil sbctl

if ! command -v yay >/dev/null; then
  echo "yay is NOT installed. Running installation commands..."
  git clone https://aur.archlinux.org/yay.git
  makepkg -si ./yay
fi

curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/PackagesPacman.txt | yay -S --needed --save --answerclean All --answerdiff All -

# Do not print commands
set +x

# Done message :)
echo "Done installing please star my repo: https://github.com/alvinlollo/Single-install-script"
echo "Reboot reccommended, run zsh a few times to fix configurations"
