# Install prerequisetes
sudo pacman -S --needed --noconfirm git curl wget python3 python-pip

# LazyVim Install
mv ~/.config/nvim{,.bak}

# optional but recommended
cp ~/.local/share/nvim{,.bak} -r
cp ~/.local/state/nvim{,.bak} -r
cp ~/.cache/nvim{,.bak} -r

git clone https://github.com/alvinlollo/LazyVim ~/.config/nvim

# Dependencys for Gdoc.vim
wget https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/requirements.txt
pip3 install -r requirements.txt --break-system-packages

echo "pip3 install -r requirements.txt"
