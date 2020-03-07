# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/jonioliveira/.oh-my-zsh"

 #Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(osx zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Easier navigation: .., ..., ...., ....., ~ and -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~" # `cd` is probably faster to type though
alias -- -="cd -"

# Shortcuts
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias p="cd ~/Projects"
alias g="git"
alias egli="cd ~/Projects/eagle-eye"
alias eglietls="cd ~/Projects/eagle-eye/workspaces/etls"
alias eglidata="cd ~/Projects/eagle-eye/workspaces/data-collector"
alias egliview="cd ~/Projects/eagle-eye/workspaces/view"
alias egliweb="cd ~/Projects/eagle-eye/workspaces/data-collector-web"
alias wk="cd ~/Workspace"
alias ccp="cd ~/Projects/ccp"
alias ccptr="cd ~/Projects/ccp/training"

# Enable aliases to be sudo’ed
alias sudo='sudo '

# Docker shortcuts
alias d="docker "
alias ds="docker ps"
alias di="docker inspect "
alias dc="docker-compose "
alias dcb="docker-compose build"
alias dcu="docker-compose up"
alias dsa="docker stop $(docker ps -a -q)"
alias dra="docker rm $(docker ps -a -q)" 

# Make shortcuts
alias m="make "
alias ml="make lint"
alias mu="make up"
alias md="make down"
alias mt="make test" 
alias mr="make run"

# Git shortcuts
alias ga="git add "
alias gaa="git add ."
alias gcz="git cz"
alias gco="git checkout "
alias gcb="git checkout -b "
alias gcm="git commit -m "
alias gph="git push"
alias gpl="git pull" 
alias gst="git status"

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

# Export AWS Profile
export AWS_PROFILE="eagle-eye"
export GOPATH="/Users/jonioliveira/.go"

export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/usr/local/share/zsh-syntax-highlighting/highlighters
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#Export Java
export PATH=/Library/Java/JavaVirtualMachines/graalvm-ce-19.2.0.1/Contents/Home/bin:$PATH:$GOPATH/bin
export JAVA_HOME=/Library/Java/JavaVirtualMachines/graalvm-ce-19.2.0.1/Contents/Home

#GO
export GO111MODULE=on

#nvm
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh
export PATH="/usr/local/opt/helm@2/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#K8S
export KUBECONFIG=$KUBECONFIG:$HOME/.kube/config:$HOME/.kube/kubecfg_ccp
source <(kubectl completion zsh)
echo 'alias k=kubectl' >>~/.zshrc
echo 'complete -F __start_kubectl k' >>~/.zshrc
alias k=kubectl
complete -F __start_kubectl k
alias k=kubectl
complete -F __start_kubectl k
alias k=kubectl
complete -F __start_kubectl k
alias k=kubectl
complete -F __start_kubectl k
alias k=kubectl
complete -F __start_kubectl k
alias k=kubectl
complete -F __start_kubectl k
alias k=kubectl
complete -F __start_kubectl k
alias k=kubectl
complete -F __start_kubectl k
alias k=kubectl
complete -F __start_kubectl k
