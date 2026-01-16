# Application renaming
alias vim="nvim"

# File listing
alias ls="ls -hal --color=auto"

# On Ubuntu/Debian, bat is installed as batcat
# On Fedora, it's just bat
if command -v batcat &> /dev/null; then
    alias bat="batcat"
fi

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

# Tmux helpers
alias tmux-reindex="tmux move-window -r"

# Rename current tmux window to show directory > app (panes)
tmux-pwd() {
    local dir=$(tmux display-message -p "#{pane_current_path}")
    local app=$(tmux display-message -p "#{pane_current_command}")
    local panes=$(tmux display-message -p "#{window_panes}")
    local dir_name=$(basename "$dir")

    if [ "$panes" -gt 1 ]; then
        tmux rename-window "${dir_name} > ${app} (${panes})"
    else
        tmux rename-window "${dir_name} > ${app}"
    fi
}

# Rename all tmux windows to show directory > app (panes)
tmux-pwd-all() {
    tmux list-windows -F "#{window_index}" | while read -r window_index; do
        local dir=$(tmux list-panes -t "$window_index" -F "#{pane_current_path}" | head -n 1)
        local app=$(tmux list-panes -t "$window_index" -F "#{pane_current_command}" | head -n 1)
        local panes=$(tmux list-panes -t "$window_index" | wc -l)
        local dir_name=$(basename "$dir")

        if [ "$panes" -gt 1 ]; then
            tmux rename-window -t "$window_index" "${dir_name} > ${app} (${panes})"
        else
            tmux rename-window -t "$window_index" "${dir_name} > ${app}"
        fi
    done
}

