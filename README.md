# Single-install-script

This script automatically installs my favourite Linux applications I use every day such as:
[Docker](https://www.docker.com/), [zsh, oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) and [neovim](https://neovim.io/). This uses the [shelly-cli](https://github.com/Seafoam-Labs/Shelly-ALPM) package manager. You can choose what sections to install with the [gum](https://github.com/charmbracelet/gum) menu.

This script will automatically install [shelly-cli](https://github.com/Seafoam-Labs/Shelly-ALPM) if it is not already present.

Most of this script is intended for Arch Linux with some Debian compatibility on the zsh, bat and LazyVim install scripts.

It also installs custom configuration for zsh and it's plugins.

If you don't like the configurations fork this and edit to you liking.

Please consider staring this project. It helps me see how important this is for everyone.

## Usage

> **Warning:** Run this script with **bash**, not fish (or another shell). It uses bash-only syntax and will fail if run under fish. Keep `bash` in the commands below — do not replace it with `fish` or `source` the script. If fish is your default shell, a warning (a `gum confirm` dialog if gum is installed, otherwise a text prompt) will remind you before anything is installed.

To use this script paste the following in the Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/install.sh | bash
```

For installing zsh and themes (also works on Debian based systems):

```bash
curl -fsSL https://raw.githubusercontent.com/alvinlollo/Single-install-script/refs/heads/main/zsh.sh | bash
```

> **Note:** on Debian-based systems the installer runs `apt full-upgrade -y` as part of its prerequisites. On Arch it installs prerequisites through shelly without upgrading the whole system.

## Scripts

| Script         | Purpose                                                                 |
| -------------- | ----------------------------------------------------------------------- |
| `install.sh`   | Main menu (gum) that dispatches to the scripts below.                    |
| `installbeta.sh` | Same menu, but logs every step and records failures instead of aborting, then exits non-zero if anything failed. This is the next `install.sh` — once tested it replaces it. |
| `zsh.sh`       | zsh + oh-my-zsh + plugins and my config (also works on Debian).         |
| `fish.sh`      | fish + Fisher plugins + end-4 dotfiles config.                          |
| `LazyVim.sh`   | My LazyVim neovim config.                                               |
| `bat.sh`       | bat + Catppuccin Mocha theme + MANPAGER setup.                          |
| `SecureBoot.sh`| **Not in the menu** (intentional): manual UEFI-only Secure Boot setup with `sbctl`. It verifies every sign target and asks before enrolling keys — read it before running. |

## Development

Enable the pre-push gate once per clone (runs `bash -n` and `shellcheck` on every tracked `*.sh`):

```bash
git config core.hooksPath hooks
```

There is also a manual end-to-end smoke test that runs the installers in a throwaway Arch container (needs docker or podman, network access; **not** part of the hook):

```bash
tests/smoke.sh                 # bat.sh, zsh.sh, fish.sh
tests/smoke.sh LazyVim.sh      # opt in to the heavy LazyVim run
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
