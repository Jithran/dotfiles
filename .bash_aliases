alias myip="curl http://ipecho.net/plain; echo"
alias ping="ping -O"        # show lost or late packages
alias psg="ps auwx | grep "

# List paths
alias path="echo -e ${PATH//:/\\n}"
alias fhere="find . -name "

alias ngrok="~/Apps/ngrok http -region eu "
alias cm="cmatrix -C blue -b -u 3 -s"
alias sail='bash vendor/bin/sail'
alias pa="php artisan "

alias ide="
    tmux split-window -v -p 20; \
    tmux split-window -h -p 66; \
    tmux split-window -h -p 50; \
    tmux select-pane -t 0; \
    tmux split-window -h -p 20; \
    tmux rename-window IDE; \
    tmux select-pane -t 0;  \
    vim ."
alias dashboard=" \
    tmux split-pane -v; \
    tmux split-pane -h -p 75; \
    tmux send-keys 'slack-term' C-m; \
    tmux split-pane -h -p 50; \
    tmux send-keys 'bpytop' C-m; \
    tmux select-pane -t 1; \
    tmux split-pane -v; \
    tmux select-pane -t 0; \
    tmux split-pane -h; \
    tmux send-keys 'dockly' C-m; \
    tmux select-pane -t 0; \
    tmux rename-window Dashboard; \
    tmux send-keys 'vim .' C-m; \
    "
alias masta=" \
    tmux split-pane -h -p 35; \
    tmux split-pane -v -p 75; \
    tmux split-pane -v -p 66; \
    tmux split-pane -v -p 50; \
    tmux select-pane -t 0; \
    tmux rename-window MaSta; \
    " 
