#!/usr/bin/env bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten directory: replace $HOME with ~, keep last 3 segments
home="$HOME"
short_cwd="${cwd/#$home/~}"
IFS='/' read -ra parts <<< "$short_cwd"
count=${#parts[@]}
if [ "$count" -gt 3 ]; then
    short_cwd="…/${parts[$count-3]}/${parts[$count-2]}/${parts[$count-1]}"
fi

# Git info (skip optional locks to avoid contention)
git_info=""
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    status_flags=""
    if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then
        status_flags="*"
    fi
    ahead=$(git -C "$cwd" rev-list --count @{u}..HEAD 2>/dev/null || echo "")
    behind=$(git -C "$cwd" rev-list --count HEAD..@{u} 2>/dev/null || echo "")
    [ -n "$ahead" ] && [ "$ahead" -gt 0 ] 2>/dev/null && status_flags="${status_flags}↑${ahead}"
    [ -n "$behind" ] && [ "$behind" -gt 0 ] 2>/dev/null && status_flags="${status_flags}↓${behind}"
    git_info=" | ${branch}${status_flags}"
fi

# Context usage indicator
ctx_info=""
if [ -n "$used" ]; then
    printf -v used_int "%.0f" "$used"
    ctx_info=" | ctx:${used_int}%"
fi

account_info=""
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
account=$(python3 -c "import json,sys; d=json.load(open('${config_dir}/.claude.json')); print(d.get('oauthAccount',{}).get('emailAddress',''))" 2>/dev/null)
if [ -n "$account" ]; then
    account_info=" | ${account}"
fi

printf "\033[38;5;111m%s\033[0m\033[38;5;245m%s\033[0m\033[38;5;245m%s\033[0m\033[38;5;245m%s\033[0m\033[38;5;139m %s\033[0m" \
    "$short_cwd" "$git_info" "$ctx_info" "$account_info" "$model"
