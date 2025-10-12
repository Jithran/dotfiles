# Application renaming
alias vim="nvim"
alias bat="batcat"

# Helpers
alias myip="curl http://ipecho.net/plain; echo"
alias release="lsb_release -a "

# Git aliases for ease use
alias gitclean="git reset --hard && git clean -fd"

alias masta=" \
    tmux split-pane -h -p 35; \
    tmux split-pane -v -p 50; \
    tmux select-pane -t 0; \
    tmux rename-window \$(basename \$(pwd)); \
    "

