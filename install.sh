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

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        log_error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi
    log_info "Detected OS: $OS $OS_VERSION"
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

log_info "Starting installation..."

# Detect OS first
detect_os

# Update system and install dependencies based on OS
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    log_info "Updating system packages..."
    sudo apt update && sudo apt upgrade -y

    log_info "Installing dependencies..."
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash - # for nodejs 24
    sudo apt install -y \
        gh curl ncdu make automake autoconf libtool pkg-config \
        libevent-dev libncurses-dev bison plocate tree neofetch \
        ripgrep tar bpytop stow git build-essential \
        wget software-properties-common bat \
        htop nodejs unzip

elif [ "$OS" = "fedora" ]; then
    log_info "Updating packages for Fedora..."
    sudo dnf check-update || true
    sudo dnf upgrade -y --skip-broken || log_warn "Some packages could not be upgraded"

    # Install Node.js 24 on Fedora
    log_info "Setting up Node.js repository..."
    sudo dnf install -y nodejs npm || log_warn "Node.js may already be installed"

    # Install dependencies
    log_info "Installing dependencies..."
    sudo dnf install -y --skip-unavailable \
        gh curl ncdu make automake autoconf libtool pkg-config \
        libevent-devel ncurses-devel bison plocate tree fastfetch \
        ripgrep tar stow git \
        wget bat htop nodejs unzip python3-pip \
        @development-tools

    # Install bpytop via pip since it's not in Fedora repos
    if ! command -v bpytop &> /dev/null; then
        log_info "Installing bpytop via pip..."
        pip3 install bpytop --user || log_warn "Failed to install bpytop"
    fi
else
    log_error "Unsupported OS: $OS"
    log_error "This script supports Ubuntu and Fedora only."
    exit 1
fi

# Install fzf
if command -v fzf &> /dev/null; then
    log_info "fzf is already installed: $(fzf --version). Skipping installation"
else
    log_info "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
    log_info "fzf installed successfully"
fi

# Install tmux
if command -v tmux &> /dev/null
then
    log_info "Tmux is already installed: $(tmux -V). Skipping installation"
else
    log_info "Installing tmux..."
    cd "$TEMP_BUILD_DIR"
    TMUX_VERSION="3.5a"
    wget "https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz"
    tar -xzf "tmux-${TMUX_VERSION}.tar.gz"
    cd "tmux-${TMUX_VERSION}"
    ./configure && make
    sudo make install
    log_info "tmux installed successfully: $(tmux -V)"
fi

if command -v nvim &> /dev/null
then
    log_info "Nvim is already installed: $(nvim --version | head -n1), skipping installation"
else
    # Install neovim
    log_info "Installing neovim..."
    cd "$TEMP_BUILD_DIR"
    wget https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz
    sudo tar -xzf nvim-linux-x86_64.tar.gz -C /opt
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    log_info "neovim installed successfully: $(nvim --version | head -n1)"
fi

# Install starship
if command -v starship &> /dev/null; then
    log_info "Starship is already installed: $(starship --version). Skipping installation"
else
    log_info "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh
    log_info "Starship installed successfully"
fi

# Install lazygit for git management
if command -v lazygit &> /dev/null; then
    log_info "lazygit is already installed: $(lazygit --version | head -n1). Skipping installation"
else
    log_info "Installing lazygit..."
    cd "$TEMP_BUILD_DIR"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit -D -t /usr/local/bin/
    log_info "lazygit installed successfully"
fi

# Setup config files with stow
cd "$HOME/dotfiles" || { log_error "~/dotfiles not found"; exit 1; }
log_info "Stowing configs from ~/dotfiles..."
stow bash nvim tmux bpytop starship 2>&1 || log_warn "Stow had conflicts - backup existing configs if needed"

# Install the nerdfont I like to use in the gnome terminal
if fc-list | grep -qi "Mononoki"; then
    log_info "Mononoki Nerd Font is already installed. Skipping installation"
else
    log_info "Installing Mononoki Nerd Font..."
    cd "$TEMP_BUILD_DIR"
    mkdir -p ~/.local/share/fonts
    wget -q --show-progress -O $FONT_ZIP $FONT_URL
    unzip -q $FONT_ZIP -d ~/.local/share/fonts/
    fc-cache -fv
    log_info "Mononoki Nerd Font installed successfully"
fi

# install nemo if we need to
if ! command -v nemo &> /dev/null
then
    log_info "Installing nemo file manager..."
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        sudo apt update
        sudo apt install -y nemo
    elif [ "$OS" = "fedora" ]; then
        sudo dnf install -y nemo
    fi

    if [ $? -eq 0 ]; then
        log_info "Nemo is installed ✅"
    else
        log_error "There was an error installing nemo ❌"
    fi
fi

# make nemo the default file browser
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
DE=$(echo $XDG_CURRENT_DESKTOP | tr '[:upper:]' '[:lower:]')
if [[ "$DE" == *"gnome"* || "$DE" == *"budgie"* ]]; then
    gsettings set org.gnome.desktop.background show-desktop-icons false
    gsettings set org.nemo.desktop show-desktop-icons true
elif [[ "$DE" == *"cinnamon"* ]]; then
    gsettings set org.nemo.desktop show-desktop-icons true
elif [[ "$DE" == *"mate"* ]]; then
    gsettings set org.mate.background show-desktop-icons false 
    gsettings set org.nemo.desktop show-desktop-icons true
fi

if check_gnome_terminal; then
    PROFILE_ID=$(gsettings get "$GNOME_TERMINAL_SCHEMA" default 2>/dev/null | tr -d "'")
    if [ -z "$PROFILE_ID" ]; then
        log_warn "Cound't find a GNOME Terminal Id, font configuration halted"
    else
        gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ use-system-font false
        gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ font "'$FONT_NAME'"
        # Enable transparency and set the level
        gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ background-transparency-percent 10
        gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/ use-transparent-background true 
    fi
    log_info "Font installed into the GNOME profile"
fi

# Install zoxide
if command -v zoxide &> /dev/null; then
    log_info "zoxide is already installed: $(zoxide --version). Skipping installation"
else
    log_info "Installing zoxide..."
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    log_info "zoxide installed successfully"
fi

# tmux post stow installation
if [ -d ~/dotfiles/tmux/.tmux/plugins/tpm ]; then
    log_info "tmux plugin manager (tpm) is already installed. Skipping installation"
else
    log_info "Installing tmux plugin manager (tpm)..."
    git clone https://github.com/tmux-plugins/tpm ~/dotfiles/tmux/.tmux/plugins/tpm
    log_info "tpm installed successfully"
fi

if [ -f ~/.tmux/plugins/tpm/bin/install_plugins ]; then
    log_info "Installing tmux plugins..."
    ~/.tmux/plugins/tpm/bin/install_plugins || log_warn "Some tmux plugins failed to install - you can install them later with prefix + I"
else
    log_warn "tpm not found at ~/.tmux/plugins/tpm - plugins not installed. Run after stow is active."
fi

# Update mlocate database
log_info "Updating mlocate database..."
sudo updatedb || log_warn "Failed to update mlocate database"

log_info "Installation complete!"
log_info "Please restart your terminal or run: source ~/.bashrc"

# Ask if user wants to run the desktop development wizard
echo ""
echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}Desktop Development Environment Wizard${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo ""
echo "The desktop wizard can install additional development tools:"
echo "  • Docker"
echo "  • .NET SDK 9.0 & 10.0"
echo "  • Visual Studio Code"
echo "  • JetBrains Toolbox"
echo "  • Google Chrome"
echo "  • Discord"
echo "  • Meld (diff tool)"
echo "  • DisplayLink drivers"
echo "  • NVIDIA drivers (if applicable)"
echo "  • Claude CLI"
echo ""
echo -e "${YELLOW}Note: This wizard is currently only supported on Fedora${NC}"
echo ""

if [ "$OS" = "fedora" ]; then
    read -p "Would you like to run the desktop development wizard now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Starting desktop wizard..."
        if [ -f "$HOME/dotfiles/desktop-wizard.sh" ]; then
            "$HOME/dotfiles/desktop-wizard.sh"
        else
            log_error "Desktop wizard not found at $HOME/dotfiles/desktop-wizard.sh"
        fi
    else
        log_info "Skipping desktop wizard. You can run it later with: ~/dotfiles/desktop-wizard.sh"
    fi
else
    log_info "Desktop wizard is not available for $OS. You can run it manually on Fedora with: ~/dotfiles/desktop-wizard.sh"
fi
