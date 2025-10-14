#!/usr/bin/env bash

set -e  # Exit on any error
set -u  # Exit on undefined variable

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Nerd font installation configuration
FONT_NAME="Mononoki Nerd Font 10"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Mononoki.zip"
FONT_ZIP="Mononoki.zip"
GNOME_TERMINAL_SCHEMA="org.gnome.Terminal.ProfilesList"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_gnome_terminal() {
    # check if we hava a gnome terminal for nerdfont installation
    if gsettings list-schemas | grep -q "$GNOME_TERMINAL_SCHEMA"; then
        return 0 # gnome found
    else
        return 1 # gnome 404
    fi
}

TEMP_BUILD_DIR=$(mktemp -d)

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$TEMP_BUILD_DIR"
}

trap cleanup EXIT

log_info "Starting installation..."

# Update system
log_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
log_info "Installing dependencies..."
sudo apt install -y \
    gh curl ncdu make automake autoconf libtool pkg-config \
    libevent-dev libncurses-dev bison plocate tree neofetch \
    ripgrep tar bpytop stow git build-essential \
    wget software-properties-common bat \
    htop fzf nodejs npm

# Install tmux
log_info "Installing tmux..."
cd "$TEMP_BUILD_DIR"
TMUX_VERSION="3.5a"
wget "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
tar -xzf "tmux-${TMUX_VERSION}.tar.gz"
cd "tmux-${TMUX_VERSION}"
./configure && make
sudo make install
log_info "tmux installed successfully: $(tmux -V)"

# Install neovim
log_info "Installing neovim..."
cd "$TEMP_BUILD_DIR"
wget https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz
sudo tar -xzf nvim-linux-x86_64.tar.gz -C /opt
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
log_info "neovim installed successfully: $(nvim --version | head -n1)"

# Install starship
curl -sS https://starship.rs/install.sh | sh

# Install lazygit for git management
cd "$TEMP_BUILD_DIR"
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/

# Setup config files with stow
cd "$HOME/dotfiles" || { log_error "~/dotfiles not found"; exit 1; }
log_info "Stowing configs from ~/dotfiles..."
stow bash nvim tmux bpytop starship 2>&1 || log_warn "Stow had conflicts - backup existing configs if needed"

# Install the nerdfont I like to use in the gnome terminal
cd "$TEMP_BUILD_DIR"
mkdir -p ~/.local/share/fonts
wget -q --show-progress -O $FONT_ZIP $FONT_URL
unzip -q $FONT_ZIP -d ~/.local/share/fonts/
rm /tmp/$FONT_ZIP
fc-cache -fv

if check_gnome_terminal; then
    PROFILE_ID=$(gsettings get "$GNOME_TERMINAL_SCHEMA" default 2>/dev/null | tr -d "'")
    if [ -z "$PROFILE_ID" ]; then
        log_warn "Cound't find a GNOME Terminal Id, font configuration halted"
    else
        gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ use-system-font false
        gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ font "'$FONT_NAAM'"
    fi
    log_info "Font installed into the GNOME profile"
fi

# tmux post stow installation
git clone https://github.com/tmux-plugins/tpm ~/dotfiles/tmux/.tmux/plugins/tpm
~/.tmux/plugins/tpm/bin/install_plugins

# Update mlocate database
log_info "Updating mlocate database..."
sudo updatedb || log_warn "Failed to update mlocate database"

log_info "Installation complete!"
log_info "Please restart your terminal or run: source ~/.bashrc"
