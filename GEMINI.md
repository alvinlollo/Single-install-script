# Project Overview

This project consists of a collection of shell scripts designed to automate the installation and configuration of a development environment on Arch Linux-based systems. It uses `pacman` for system packages and `yay` for AUR packages.

The main components are:
- **`install.sh`**: The primary script that runs through the entire installation process.
- **`installbeta.sh`**: A newer, interactive version of the installation script that uses `whiptail` to provide a menu-driven interface.
- **`zsh.sh`**: A script dedicated to setting up Zsh, Oh My Zsh, and several useful plugins.
- **`LazyVim.sh`**: A script for setting up a LazyVim configuration for Neovim.
- **`configs/`**: A directory containing configuration files, including `.zshrc` and lists of packages to be installed (`PackagesPacman.txt`, `PackagesYay.txt`).

# Building and Running

These are shell scripts and do not require a build process. They can be executed directly.

**Running the main installation:**

```bash
./install.sh
```

**Running the interactive installation:**

```bash
./installbeta.sh
```

**Running individual setup scripts:**

```bash
./zsh.sh
./LazyVim.sh
```

# Development Conventions

- The scripts are written in `bash`.
- They are designed to be run on Arch Linux and may have some compatibility with other systems (e.g., `zsh.sh` has checks for `apt`).
- The scripts use `set -eux pipefail` to ensure that they exit on any error and print commands as they are executed, which is good for debugging. This is toggled off for specific commands that might fail without being critical.
- The scripts frequently use `curl` to download other scripts or configuration files from the associated GitHub repository.
- Package lists are maintained in `configs/PackagesPacman.txt` and `configs/PackagesYay.txt`.
- Python dependencies for some tools are listed in `requirements.txt` and installed via `pip`.
