# Install prerequisetes
sudo pacman -S --needed --noconfirm git curl wget python3 python-pip

# Show nvim config replacement
echo 'This script will move your old nvim config to ~/.local/share/nvim.bak'
sleep 20 && echo "Use CTRL+C within 20 secconds if you don't want these actions to be made"

# Remove old backups
if [ -e "~/.config/nvim.bak" ]; then
    # The path exists (it could be a file, a directory, a symlink, etc.)
    echo "Path ~/.config/nvim.bak exists. Running command..."
    rm -rf ~/.config/nvim.bak
fi

if [ -e "~/.local/share/nvim.bak" ]; then
    # The path exists (it could be a file, a directory, a symlink, etc.)
    echo "Path ~/.local/share/nvim.bak exists. Running command..."
    rm -rf ~/.local/share/nvim.bak
fi

if [ -e "~/.local/state/nvim.bak" ]; then
    # The path exists (it could be a file, a directory, a symlink, etc.)
    echo "Path ~/.local/state/nvim.bak exists. Running command..."
    rm -rf ~/.local/state/nvim.bak
fi

if [ -e "~/.cache/nvim.bak" ]; then
    # The path exists (it could be a file, a directory, a symlink, etc.)
    echo "Path ~/.cache/nvim.bak exists. Running command..."
    rm -rf ~/.cache/nvim.bak
fi

# LazyVim Backup
mv ~/.config/nvim{,.bak}

# optional but recommended
cp ~/.local/share/nvim{,.bak} -r
cp ~/.local/state/nvim{,.bak} -r
cp ~/.cache/nvim{,.bak} -r

git clone https://github.com/alvinlollo/LazyVim ~/.config/nvim

# Dependencys for Gdoc.vim
wget https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/requirements.txt
pip3 install -r requirements.txt --break-system-packages && rm requirements.txt

echo "pip3 install -r requirements.txt"
