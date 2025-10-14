if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# initialize zoxide
eval "$(zoxide init bash)"
