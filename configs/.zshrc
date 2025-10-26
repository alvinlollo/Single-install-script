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

  export EDITOR=nvim
# export MANPATH="/usr/local/man:$MANPATH"

# You may need to set your language environment manually
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Define a helper function to check for a command's existence
_extract_check_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed. Skipping." >&2
        return 1
    fi
    return 0
}

# The main enhanced extract function
extract () {
    # Check if any arguments were provided
    if [ "$#" -eq 0 ]; then
        echo "Usage: extract <file> [<file>...]"
        echo "Supported file types: *.tar, *.tgz, *.tar.gz, *.tar.bz2, *.tar.xz, *.zip, *.rar, *.7z, *.bz2, *.gz, *.xz, *.Z"
        return 1
    fi

    local file_path extract_cmd status=0
    
    for file_path in "$@"; do
        # 1. File existence and type check
        if [ ! -f "$file_path" ]; then
            echo "Error: '$file_path' is not a valid file or does not exist. Skipping." >&2
            status=1
            continue
        fi

        echo "-> Attempting to extract '$file_path'..."
        
        extract_cmd="" # Reset command for the current file
        
        # 2. Determine the extraction command
        case "$file_path" in
            # Modern TAR: Uses -x for extract, -f for file, and -a (or -I) for auto-compression
            # Note: The -v (verbose) flag is useful but omitted here for a cleaner script.
            *.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz|*.tar.zst|*.tar)
                if _extract_check_cmd tar; then
                    # The 'tar xaf' command is often the modern, universal way to extract compressed/uncompressed tar files.
                    # 'a' (or --auto-compress) determines the compression type automatically.
                    extract_cmd="tar xaf '$file_path'"
                fi
                ;;

            # Standalone Compressed Files
            *.bz2) _extract_check_cmd bunzip2 && extract_cmd="bunzip2 '$file_path'" ;;
            *.gz)  _extract_check_cmd gunzip && extract_cmd="gunzip '$file_path'" ;;
            *.xz)  _extract_check_cmd unxz && extract_cmd="unxz '$file_path'" ;;
            *.Z)   _extract_check_cmd uncompress && extract_cmd="uncompress '$file_path'" ;;

            # Archives
            *.zip) _extract_check_cmd unzip && extract_cmd="unzip '$file_path'" ;;
            *.rar) _extract_check_cmd unrar && extract_cmd="unrar x '$file_path'" ;; # unrar x extracts to current directory
            *.7z)  _extract_check_cmd 7z && extract_cmd="7z x '$file_path'" ;;

            # Fallback
            *) 
                echo "Warning: '$file_path' cannot be extracted via extract() - Unsupported file type." >&2 
                status=1
                continue
                ;;
        esac

        # 3. Execute the command and check its exit status
        if [ -n "$extract_cmd" ]; then
            # Using eval to execute the dynamically constructed command string. 
            # This is safe here because '$file_path' has been wrapped in single quotes.
            if eval "$extract_cmd"; then
                echo "-> Successfully extracted '$file_path'."
            else
                echo "Error: Extraction failed for '$file_path' (Command: $extract_cmd)." >&2
                status=1
            fi
        fi
        
        echo "" # Add a newline for separation between files
    done
    
    return $status
}

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

