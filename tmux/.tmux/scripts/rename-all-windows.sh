#!/usr/bin/env bash

# Rename all tmux windows to show directory > app (panes)
tmux list-windows -F "#{window_index}" | while read -r window_index; do
    dir=$(tmux list-panes -t "$window_index" -F "#{pane_current_path}" | head -n 1)
    app=$(tmux list-panes -t "$window_index" -F "#{pane_current_command}" | head -n 1)
    panes=$(tmux list-panes -t "$window_index" | wc -l)
    dir_name=$(basename "$dir")

    if [ "$panes" -gt 1 ]; then
        tmux rename-window -t "$window_index" "${dir_name} > ${app} ($panes)"
    else
        tmux rename-window -t "$window_index" "${dir_name} > ${app}"
    fi
done
