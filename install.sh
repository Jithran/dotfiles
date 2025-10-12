#!/usr/bin/env bash

set -e  # Exit on any error
set -u  # Exit on undefined variable

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
    libevent-dev libncurses-dev bison mlocate tree neofetch \
    ripgrep tar bpytop stow git build-essential \
    wget software-properties-common bat

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

# Setup config files with stow
cd "$HOME/dotfiles" || { log_error "~/dotfiles not found"; exit 1; }
log_info "Stowing configs from ~/dotfiles..."
stow bash nvim tmux 2>&1 || log_warn "Stow had conflicts - backup existing configs if needed"

# Update mlocate database
log_info "Updating mlocate database..."
sudo updatedb || log_warn "Failed to update mlocate database"

log_info "Installation complete!"
log_info "Please restart your terminal or run: source ~/.bashrc"
