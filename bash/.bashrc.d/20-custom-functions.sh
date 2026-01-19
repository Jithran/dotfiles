# Function for directory lister whilst cd-ing
function cd {
    builtin cd "$@" && ls -hal -F
}

# Function for highlighted tail
# Usage: batf /path/to/file [row=200] [syntax=log]
batf() {
    local file="$1"
    local lines="${2:-200}"
    local lang="${3:-log}"
    tail -n "$lines" -f -- "$file" | batcat --paging=never -l "$lang"
}

nf() {
    local file
    file=$(fzf --preview='bat {}') || return
    "${EDITOR:-vim}" "$file"
}
