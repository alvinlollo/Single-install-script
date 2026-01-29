# If you come from bash, you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
  export ZSH=~/.oh-my-zsh

# Set the name of the theme to load. If you set this to "random"
# It'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
  ZSH_THEME="gnzh"

# Set the list of themes to load
# Setting this variable when ZSH_THEME=random
# cause zsh to load the theme from this variable instead of
# looking in ~/.oh-my-zsh/themes/
# An empty array has no effect
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
  CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often auto-update (in days) is used.
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colours in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting the terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status checks for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Uncomment the following to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	git
	zsh-history-substring-search
	zsh-autosuggestions
#	zsh-eza
	fzf-zsh-plugin
 	zsh-syntax-highlighting
	
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to set your language environment manually
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='vim'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

update () { 

	echo "Update script by alvinlollo"
	# Update arch based systems with yay AUR helper
	if command -v pacman >/dev/null && command -v yay >/dev/null; then
	    echo "✅ 'pacman' and 'yay' found. Updating."
	    sudo pacman -Syu --noconfirm
	    yay -S --needed --save --answerclean None --answerdiff None - --noconfirm
	fi

	# Update on debian based systems
	if command -v apt >/dev/null; then
		echo "✅ 'apt' found. Updating."
	    sudo apt update
		sudo apt full-upgrade -y
	fi

	# Update Hyprland
	if command -v hyprpm >/dev/null; then
		echo "✅ 'hyprpm' found. Updating."
		hyprpm reload && sleep 2
		hyprpm update
	fi

	# Update Flatpak
	if command -v flatpak >/dev/null; then
		echo "✅ 'flatpak' found. Updating."
	    flatpak update
	fi

}

# Sudo last command with control + u

zle -N sudo-last-command-execute
sudo-last-command-execute() {

  zle -U $'sudo !!\n'

}

# Bind the widget to Control+U
bindkey '^U' sudo-last-command-execute

# Ydotool
export YDOTOOL_SOCKET=/tmp/.ydotool_socket

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Eza (Better ls)
#alias ls="eza --long --no-time --git --icons=never --no-permissions"

