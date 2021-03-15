# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

#Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="spaceship"

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
ENABLE_CORRECTION="false"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

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
plugins=(osx git)

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

SPACESHIP_KUBECTL_SHOW=true
SPACESHIP_KUBECTL_VERSION_SHOW=false

# Easier navigation: .., ..., ...., ....., ~ and -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~" # `cd` is probably faster to type though
alias -- -="cd -"

# Shortcuts
alias wk="cd ~/Workspace"
alias cmy="cd ~/Workspace/cloudmobility"
alias cmyp="cd ~/Workspace/cloudmobility/projects"

# Enable aliases to be sudo’ed
alias sudo='sudo '

# Docker shortcuts
alias d="docker "
alias ds="docker ps"
alias di="docker inspect "
alias dc="docker-compose "
alias dcb="docker-compose build"
alias dcu="docker-compose up"
alias dsall="docker stop $(docker ps -a -q)"
alias drall="docker rm $(docker ps -a -q)" 
alias drimgall="docker rm $(docker images -q)" 

# Make shortcuts
alias m="make "

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

# Export AWS Profile
export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/usr/local/share/zsh-syntax-highlighting/highlighters
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#Go
export GO111MODULE=auto
export GOPATH=$HOME/.go
export PATH=$GOPATH/bin:$PATH

#nvm
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh
export PATH="/usr/local/opt/helm@2/bin:$PATH"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

################################################################
#                 K8S
################################################################

# Set the default kube context if present
DEFAULT_KUBE_CONTEXTS="$HOME/.kube/config"
if test -f "${DEFAULT_KUBE_CONTEXTS}"
then
  export KUBECONFIG="$DEFAULT_KUBE_CONTEXTS"
fi

# Additional contexts should be in ~/.kube/custom-contexts/ 
CUSTOM_KUBE_CONTEXTS="$HOME/.kube/contexts"
mkdir -p "${CUSTOM_KUBE_CONTEXTS}"

OIFS="$IFS"
IFS=$'\n'
for contextFile in `find "${CUSTOM_KUBE_CONTEXTS}" -type f -name "*kube.config"`  
do
    export KUBECONFIG="$contextFile:$KUBECONFIG"
done
IFS="$OIFS"

#alias 
alias k="kubectl "
alias kx="kubectx "
alias kns="kubens"

# Deployment management.
alias kdp='kubectl get deployment'
alias kdpa='kubectl get deployment --all-namespaces'

# Logs
alias kl='kubectl logs'

# Tools for accessing all information
alias ka='kubectl get all'
alias kaa='kubectl get all --all-namespaces'

alias kca='kubectl get configmaps --all-namespaces'

# Apply a YML file
alias kaf='kubectl apply -f'

# Drop into an interactive terminal on a container
alias keti='kubectl exec -ti'

# Describe
alias kd='kubectl describe'

# Get Pods
alias kp='kubectl get pods'

# Get svc
alias ks='kubectl get svc'

# Get ingress
alias ki='kubectl get ingress'

# Get Config Maps
alias kc='kubectl get cm'

# kubectl completion
source <(kubectl completion zsh)
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/joni/workspace/.google-cloud-sdk/path.zsh.inc' ]; then . '/Users/joni/workspace/.google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/joni/workspace/.google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/joni/workspace/.google-cloud-sdk/completion.zsh.inc'; fi