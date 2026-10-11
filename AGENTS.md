# AGENTS.md

## Environment & Constraints
* **Shell**: All scripts are written in `bash` and must be executed using `bash`. Do not attempt to run or source these scripts using `fish`, `zsh`, or other shells.
* **Platforms**: Primarily targeted at **Arch Linux**. Partial compatibility exists for Debian-based systems (specifically `zsh`, `bat`, `LazyVim` install scripts).
* **UI**: Expect interactive prompts using [`gum`](https://github.com/charmbracelet/gum) for selection menus.

## Repository Structure
* **`install.sh`**: The main entrypoint.
* **`zsh.sh`, `bat.sh`, `LazyVim.sh`, etc.**: Modular installation scripts for specific tools.
* **`configs/`**: Contains configuration files applied by the install scripts (e.g., `shelly-*.toml`).

## Developer Notes
* **Package Management**: Uses `shelly-cli` (Seafoam-Labs/Shelly-ALPM) for Arch Linux.
* **Debian Prerequisite**: On Debian-based systems, install scripts may trigger `apt full-upgrade -y`.
* **Testing**: If modifying scripts, verify behavior locally by sourcing or running in `bash`, ensuring `gum` is available for menu testing.
