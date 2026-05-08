# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end
    
    # Colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end

set -gx PATH $HOME/.local/bin $HOME/bin /usr/local/bin /usr/bin $PATH
export WAYLAND_DISPLAY=$WAYLAND_DISPLAY
export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR

# Homebrew (If installed)
if test -f "/home/linusbrew/.linuxbrew/bin/brew"
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
end

# Ydotool
if test -f "/tmp/.ydotool_socket"
	set -gx YDOTOOL_SOCKET /tmp/.ydotool_socket
end

