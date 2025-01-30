#!/usr/bin/bash

clear
echo -e "\e[0m\c"

# shellcheck disable=SC2016
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

# Install prequisites
sudo apt update
sudo apt upgrade
sudo apt install -y git-core zsh curl git build-essential

# Do not print commands
set +x

# Install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Print commands
set -x

echo >> ~/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Prequises from homebrew
brew update
brew upgrade
brew install eza fzf gcc thefuck gh

# Disable exit on error 
set +eux

# Install Oh-My-zsh if not installed
if [ ! -f ~/.zshrc ]; then
  sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# Enable exit on error
set -eux

# Remove old config file
rm -rf ~/.zshrc

# Replace config file
touch ~/.zshrc
echo "$(curl https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.zshrc)" >> ~/.zshrc

# [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search" ]; then
    git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
fi

# [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
fi

# [zsh-eza](https://github.com/z-shell/zsh-eza)
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza" ]; then
    git clone https://github.com/z-shell/zsh-eza.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza
fi

# [fzf-zsh-plugin](https://github.com/unixorn/fzf-zsh-plugin)
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin" ]; then
git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin
fi

# Setup fzf
mkdir ~/.fzf
mkdir ~/.fzf/shell
touch ~/.fzf/shell/key-bindings.zsh
source ~/.zshrc
source ~/.zshrc
source ~/.zshrc

# Do not print commands
set +x

# Install code server
curl -fsSL https://code-server.dev/install.sh | sh

# Install GEF
bash -c "$(curl -fsSL https://gef.blah.cat/sh)"

# Do not print commands
set -x

# Install personal apt packages
sudo apt install -y git htop golang hugo figlet irssi cmatrix neofetch cowsay fortune-mod tint tty-clock lolcat hugo libsass1 dpkg npm python3 docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin flatpak gnome-software-plugin-flatpak libcurl4-gnutls-dev bsd-mailx needrestart powermgmt-base accountsservice lynx wget curl evince zsh net-tools --fix-missing
sudo apt full-upgrade -y

# Add a update-all script
rm -rf /usr/local/bin/update-all | sudo bash
sudo touch /usr/local/bin/update-all
sudo chmod +x /usr/local/bin/update-all
echo "$(curl https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/extras/update-all%20script)" >> /usr/local/bin/update-all

# Done message :)
echo "Done installing"
#!/usr/bin/bash

clear
echo -e "\e[0m\c"

# shellcheck disable=SC2016
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

# Install prequisites
sudo apt update
sudo apt upgrade
sudo apt install -y git-core zsh curl git build-essential

# Do not print commands
set +x

# Install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Print commands
set -x

echo >> ~/.bashrc
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Prequises from homebrew
brew update
brew upgrade
brew install eza fzf gcc thefuck gh

# Disable exit on error 
set +eux

# Install Oh-My-zsh if not installed
if [ ! -f ~/.zshrc ]; then
  sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

# Enable exit on error
set -eux

# Remove old config file
rm -rf ~/.zshrc

# Replace config file
touch ~/.zshrc
echo "$(curl https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/configs/.zshrc)" >> ~/.zshrc

# [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search" ]; then
    git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
fi

# [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
fi

# [zsh-eza](https://github.com/z-shell/zsh-eza)
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza" ]; then
    git clone https://github.com/z-shell/zsh-eza.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-eza
fi

# [fzf-zsh-plugin](https://github.com/unixorn/fzf-zsh-plugin)
if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin" ]; then
git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin
fi

# Setup fzf
mkdir ~/.fzf
mkdir ~/.fzf/shell
touch ~/.fzf/shell/key-bindings.zsh
source ~/.zshrc
source ~/.zshrc
source ~/.zshrc

# Do not print commands
set +x

# Install code server
curl -fsSL https://code-server.dev/install.sh | sh

# Install GEF
bash -c "$(curl -fsSL https://gef.blah.cat/sh)"

# Do not print commands
set -x

# Install personal apt packages
sudo apt install -y git htop golang hugo figlet irssi cmatrix neofetch cowsay fortune-mod tint tty-clock lolcat hugo libsass1 dpkg npm python3 docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin flatpak gnome-software-plugin-flatpak libcurl4-gnutls-dev bsd-mailx needrestart powermgmt-base accountsservice lynx wget curl evince zsh net-tools --fix-missing
sudo apt full-upgrade -y

# Add a update-all script
rm -rf /usr/local/bin/update-all | sudo bash
sudo touch /usr/local/bin/update-all
sudo chmod +x /usr/local/bin/update-all
echo "$(curl https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/extras/update-all%20script)" >> /usr/local/bin/update-all

# Done message :)
echo "Done installing"
