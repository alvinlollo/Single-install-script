# Single-install-script

This script automatically installs my favourite Linux applications I use every day such as:
[Docker](https://www.docker.com/), [zsh, oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) and [neovim](https://neovim.io/). This uses pacman and [yay AUR helper](https://github.com/Jguer/yay). You can choose what sections to install with the whiptail menu.

This script will use aim to use the [shelly-cli](https://github.com/Seafoam-Labs/Shelly-ALPM) installer.

Most of this script is intended for Arch Linux with some Debian compatibility on the zsh install script only.

It also installs custom configuration for zsh and it's plugins.

If you don't like the configurations fork this and edit to you liking.

Please consider staring this project. It helps me see how important this is for everyone.

## Usage

To use this script paste the following in the Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/install.sh | bash
```

For installing zsh and themes (also works on Debian based systems):

```bash
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/zsh.sh | bash
```

## Zsh configuration

My Zsh configuration includes the following plugins run through [oh-my-zsh](https://ohmyz.sh/): git, [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search), [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), [zsh-autocomplete](https://github.com/marlonrichert/zsh-autocomplete), [fzf-zsh-plugin](https://github.com/unixorn/fzf-zsh-plugin) and [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting.git)

Running the ``update`` function will update all your package managers if the command exists without confirmation. (Please use shelly-cli if you are on Arch Linux)

Using the key bind ALT + S will add the sudo command before your previously run command e.g.
```sh
╭─alvin@Alvin ~
╰─➤  nano /etc/fstab
# Pressed CTRL + U
╭─alvin@Alvin ~
╰─➤  sudo !!
╭─alvin@Alvin ~
╰─➤  sudo nano /etc/fstab
```

If you have any issues please add one in the issues tab.
