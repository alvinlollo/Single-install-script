# Single-install-script

This script automatically installs my favourite Linux applications i use everyday such as:
Docker, zsh, oh-my-zsh and neovim. This uses pacman and yay AUR helper. You can choose what sections to install with the whiptail menu

Most of this script is intended for arch linux with some debian compatablity on the zsh install script only.

It also installs custom configuration for zsh and it's plugins.

If you don't like the configurations fork this and edit to you liking.

Please consider staring this project. It helps me see how important this is for everyone.

## Usage

To use this script paste the following in the Terminal:

```sh
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/install.sh | bash
```

For installing zsh and themes (also works on debian based systems):

```sh
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/zsh.sh | bash
```

If you have any issues please add one in the issues tab.
