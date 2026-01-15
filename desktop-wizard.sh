#!/usr/bin/env bash

set -e  # Exit on any error
set -u  # Exit on undefined variable

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
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

# Check if running on Fedora
detect_os
if [ "$OS" != "fedora" ]; then
    log_error "This desktop wizard currently only supports Fedora."
    log_error "Detected OS: $OS"
    exit 1
fi

log_info "Starting Desktop Development Environment Wizard..."
echo ""

# ============================================================
# RPM Fusion Repository
# ============================================================
log_step "Installing RPM Fusion repositories..."
if rpm -qa | grep -q "rpmfusion-free-release"; then
    log_info "RPM Fusion (free) is already installed. Skipping."
else
    log_info "Installing RPM Fusion free repository..."
    sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
fi

if rpm -qa | grep -q "rpmfusion-nonfree-release"; then
    log_info "RPM Fusion (nonfree) is already installed. Skipping."
else
    log_info "Installing RPM Fusion nonfree repository..."
    sudo dnf install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
fi

# ============================================================
# System Settings - inotify limits
# ============================================================
log_step "Configuring inotify limits..."
SYSCTL_CONF="/etc/sysctl.d/99-inotify.conf"
if [ -f "$SYSCTL_CONF" ]; then
    log_info "inotify limits are already configured in $SYSCTL_CONF"
else
    log_info "Setting inotify limits permanently..."
    echo "fs.inotify.max_user_instances=524288" | sudo tee "$SYSCTL_CONF" > /dev/null
    echo "fs.inotify.max_user_watches=524288" | sudo tee -a "$SYSCTL_CONF" > /dev/null
    sudo sysctl -p "$SYSCTL_CONF"
    log_info "inotify limits configured successfully"
fi

# ============================================================
# Docker Installation
# ============================================================
log_step "Installing Docker..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    log_info "Docker is already installed: $DOCKER_VERSION"
    read -p "Do you want to reinstall Docker? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping Docker installation."
    else
        REINSTALL_DOCKER=true
    fi
fi

if [ ! -f /usr/bin/docker ] || [ "${REINSTALL_DOCKER:-false}" = true ]; then
    log_info "Removing any existing Docker installations..."
    sudo dnf remove -y docker docker-client docker-client-latest docker-common \
        docker-latest docker-latest-logrotate docker-logrotate docker-selinux \
        docker-engine-selinux docker-engine 2>/dev/null || true

    log_info "Adding Docker repository..."
    sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo

    log_info "Installing Docker..."
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    log_info "Enabling and starting Docker service..."
    sudo systemctl enable --now docker

    log_info "Adding user to docker group..."
    sudo usermod -aG docker "$USER"

    log_warn "You need to log out and log back in for docker group membership to take effect!"
    log_info "Docker installed successfully"
fi

# ============================================================
# .NET SDK Installation
# ============================================================
log_step "Installing .NET SDKs..."
if rpm -qa | grep -q "dotnet-sdk-9.0"; then
    log_info ".NET SDK 9.0 is already installed. Skipping."
else
    log_info "Installing .NET SDK 9.0..."
    sudo dnf install -y dotnet-sdk-9.0
fi

if rpm -qa | grep -q "dotnet-sdk-10.0"; then
    log_info ".NET SDK 10.0 is already installed. Skipping."
else
    log_info "Installing .NET SDK 10.0..."
    sudo dnf install -y dotnet-sdk-10.0 || log_warn ".NET SDK 10.0 may not be available yet"
fi

# Install and configure linux-dev-certs
log_info "Installing linux development certificates..."

# Ensure .dotnet/tools is in PATH for this session
export PATH="$PATH:$HOME/.dotnet/tools"

if dotnet tool list -g | grep -q "linux-dev-certs"; then
    log_info "linux-dev-certs is already installed. Updating..."
    dotnet tool update -g linux-dev-certs
else
    dotnet tool install -g linux-dev-certs
fi
dotnet linux-dev-certs install

# ============================================================
# DisplayLink Driver (optional - for external monitors/docking stations)
# ============================================================
log_step "DisplayLink driver (for docking stations/external monitors)..."
if rpm -qa | grep -q "displaylink"; then
    log_info "DisplayLink is already installed. Skipping."
else
    read -p "Install DisplayLink driver? (Only needed for DisplayLink docking stations, skip on VMs) (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Enabling DisplayLink COPR repository..."
        sudo dnf copr enable -y crashdummy/Displaylink
        sudo dnf update -y
        log_info "Installing DisplayLink..."
        sudo dnf install -y displaylink
    else
        log_info "Skipping DisplayLink installation."
    fi
fi

# ============================================================
# NVIDIA Driver (if NVIDIA GPU detected)
# ============================================================
log_step "Checking for NVIDIA graphics card..."
if lspci | grep -i nvidia &> /dev/null; then
    log_info "NVIDIA GPU detected!"

    if rpm -qa | grep -q "akmod-nvidia"; then
        log_info "NVIDIA drivers are already installed. Skipping."
    else
        read -p "Install NVIDIA proprietary drivers? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installing NVIDIA drivers..."
            sudo dnf update -y
            sudo dnf install -y akmod-nvidia
            log_warn "NVIDIA drivers installed. Please reboot after installation completes!"
        else
            log_info "Skipping NVIDIA driver installation."
        fi
    fi
else
    log_info "No NVIDIA GPU detected. Skipping NVIDIA driver installation."
fi

# ============================================================
# Google Chrome (installed early for browser-based authentication)
# ============================================================
log_step "Installing Google Chrome..."
if command -v google-chrome &> /dev/null; then
    log_info "Google Chrome is already installed: $(google-chrome --version)"
else
    log_info "Adding Google Chrome repository..."
    sudo tee /etc/yum.repos.d/google-chrome.repo > /dev/null <<EOF
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

    log_info "Installing Google Chrome..."
    sudo dnf install -y google-chrome-stable
    log_info "Google Chrome installed successfully"
fi

# Set Chrome as default browser if installed
if command -v google-chrome &> /dev/null; then
    CURRENT_BROWSER=$(xdg-settings get default-web-browser 2>/dev/null || echo "")
    if [ "$CURRENT_BROWSER" != "google-chrome.desktop" ]; then
        read -p "Set Google Chrome as default browser? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            xdg-settings set default-web-browser google-chrome.desktop
            log_info "Google Chrome set as default browser"
        fi
    else
        log_info "Google Chrome is already the default browser"
    fi
fi

# ============================================================
# Claude CLI
# ============================================================
log_step "Installing Claude CLI..."
if command -v claude &> /dev/null; then
    log_info "Claude CLI is already installed: $(claude --version 2>/dev/null || echo 'installed')"
    read -p "Do you want to reconfigure the Claude token? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        claude setup-token
    fi
else
    log_info "Installing Claude CLI..."
    curl -fsSL https://claude.ai/install.sh | bash
    log_info "Claude CLI installed. Please configure your token:"
    claude setup-token || log_warn "Token setup can be done later with: claude setup-token"
fi

# ============================================================
# Visual Studio Code
# ============================================================
log_step "Installing Visual Studio Code..."
if command -v code &> /dev/null; then
    log_info "Visual Studio Code is already installed: $(code --version | head -n1)"
else
    log_info "Adding Microsoft repository..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

    log_info "Installing Visual Studio Code..."
    sudo dnf check-update || true
    sudo dnf install -y code
    log_info "Visual Studio Code installed successfully"
fi

# ============================================================
# JetBrains Toolbox
# ============================================================
log_step "Installing JetBrains Toolbox..."
if [ -f ~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox ]; then
    log_info "JetBrains Toolbox is already installed. Skipping."
else
    log_info "Downloading and installing JetBrains Toolbox..."
    ORIGINAL_DIR=$(pwd)
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Get the latest version URL - improved parsing
    TOOLBOX_JSON=$(curl -s 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release')

    # Try to extract URL using python if available, otherwise use sed
    if command -v python3 &> /dev/null; then
        TOOLBOX_URL=$(echo "$TOOLBOX_JSON" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data['TBA'][0]['downloads']['linux']['link'])" 2>/dev/null)
    else
        # Fallback to sed/grep
        TOOLBOX_URL=$(echo "$TOOLBOX_JSON" | grep -o '"linux"[[:space:]]*:[[:space:]]*{[^}]*"link"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o 'https://[^"]*')
    fi

    if [ -z "$TOOLBOX_URL" ]; then
        log_error "Failed to fetch JetBrains Toolbox download URL"
        log_warn "Please download manually from: https://www.jetbrains.com/toolbox-app/"
    else
        log_info "Downloading from: $TOOLBOX_URL"
        wget -q --show-progress -O jetbrains-toolbox.tar.gz "$TOOLBOX_URL"
        tar -xzf jetbrains-toolbox.tar.gz

        # Find the extracted directory containing jetbrains-toolbox
        TOOLBOX_DIR=$(find . -maxdepth 1 -type d -name 'jetbrains-toolbox-*' | head -n1)

        if [ -n "$TOOLBOX_DIR" ] && [ -f "$TOOLBOX_DIR/bin/jetbrains-toolbox" ]; then
            # Copy entire directory contents (includes JRE and other required files)
            mkdir -p ~/.local/share/JetBrains/Toolbox/bin
            cp -r "$TOOLBOX_DIR"/bin/* ~/.local/share/JetBrains/Toolbox/bin/
            chmod +x ~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox

            # Create .desktop file for application menu
            mkdir -p ~/.local/share/applications
            cat > ~/.local/share/applications/jetbrains-toolbox.desktop << 'DESKTOP'
[Desktop Entry]
Name=JetBrains Toolbox
Exec=$HOME/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox %u
Icon=$HOME/.local/share/JetBrains/Toolbox/bin/toolbox-tray-color.png
Type=Application
Categories=Development;IDE;
Terminal=false
StartupNotify=true
StartupWMClass=jetbrains-toolbox
Comment=Manage JetBrains IDEs
DESKTOP
            # Replace $HOME with actual path
            sed -i "s|\$HOME|$HOME|g" ~/.local/share/applications/jetbrains-toolbox.desktop

            log_info "JetBrains Toolbox installed successfully"
            log_info "Starting JetBrains Toolbox..."
            nohup ~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox &> /dev/null &
        else
            log_error "Failed to find JetBrains Toolbox directory after extraction"
            log_warn "Contents of extracted archive:"
            ls -la
        fi
    fi

    cd "$ORIGINAL_DIR"
    rm -rf "$TEMP_DIR"
fi

# ============================================================
# Meld (visual diff and merge tool)
# ============================================================
log_step "Installing Meld..."
if command -v meld &> /dev/null; then
    log_info "Meld is already installed: $(meld --version)"
else
    log_info "Installing Meld..."
    sudo dnf install -y meld
    log_info "Meld installed successfully"
fi

# ============================================================
# Discord
# ============================================================
log_step "Installing Discord..."
if command -v discord &> /dev/null || [ -f /usr/bin/discord ]; then
    log_info "Discord is already installed. Skipping."
else
    log_info "Installing Discord..."
    sudo dnf install -y discord
    log_info "Discord installed successfully"
fi

# ============================================================
# ExpanDrive
# ============================================================
log_step "Installing ExpanDrive..."
if command -v expandrive &> /dev/null || [ -f /usr/bin/expandrive ]; then
    log_info "ExpanDrive is already installed. Skipping."
else
    log_info "ExpanDrive requires manual download from https://www.expandrive.com/desktop/linux/"
    log_warn "Please download the RPM package and install with: sudo dnf install ./expandrive-*.rpm"
    read -p "Press Enter to continue..."
fi

# ============================================================
# kubectl (Kubernetes CLI)
# ============================================================
log_step "Installing kubectl..."
if command -v kubectl &> /dev/null; then
    log_info "kubectl is already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
else
    log_info "Adding Kubernetes repository..."
    cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.31/rpm/repodata/repomd.xml.key
EOF

    log_info "Installing kubectl..."
    sudo dnf install -y kubectl
    log_info "kubectl installed successfully"
    kubectl version --client
fi

# ============================================================
# Freelens (Kubernetes IDE)
# ============================================================
log_step "Installing Freelens..."
if command -v freelens &> /dev/null; then
    log_info "Freelens is already installed. Skipping."
else
    log_info "Downloading and installing Freelens..."
    ORIGINAL_DIR=$(pwd)
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Get the latest Freelens release RPM for amd64
    FREELENS_URL=$(curl -s https://api.github.com/repos/freelensapp/freelens/releases/latest | grep "browser_download_url.*amd64.rpm" | grep -v "sha256" | cut -d '"' -f 4)

    if [ -z "$FREELENS_URL" ]; then
        log_error "Failed to fetch Freelens download URL"
        log_warn "Please download manually from: https://github.com/freelensapp/freelens/releases"
    else
        log_info "Downloading from: $FREELENS_URL"
        wget -q --show-progress -O freelens.rpm "$FREELENS_URL"

        log_info "Installing Freelens..."
        sudo dnf install -y ./freelens.rpm
        log_info "Freelens installed successfully"
    fi

    cd "$ORIGINAL_DIR"
    rm -rf "$TEMP_DIR"
fi

# ============================================================
# GitHub CLI Authentication
# ============================================================
log_step "GitHub CLI Authentication..."
if command -v gh &> /dev/null; then
    if gh auth status &> /dev/null; then
        log_info "GitHub CLI is already authenticated."
        read -p "Do you want to re-authenticate? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh auth login
        fi
    else
        log_info "GitHub CLI is installed but not authenticated."
        read -p "Do you want to authenticate now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh auth login
        else
            log_info "You can authenticate later with: gh auth login"
        fi
    fi
else
    log_warn "GitHub CLI (gh) is not installed. Install it first with the main install.sh script."
fi

# ============================================================
# Git Global Configuration
# ============================================================
log_step "Git Global Configuration..."
GIT_USER_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
    log_info "Git global user configuration is not complete."
    [ -z "$GIT_USER_NAME" ] && log_info "  - user.name is not set"
    [ -z "$GIT_USER_EMAIL" ] && log_info "  - user.email is not set"

    read -p "Do you want to configure git user settings now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -z "$GIT_USER_NAME" ]; then
            read -p "Enter your name for git commits: " GIT_NAME
            if [ -n "$GIT_NAME" ]; then
                git config --global user.name "$GIT_NAME"
                log_info "Set user.name to: $GIT_NAME"
            fi
        fi

        if [ -z "$GIT_USER_EMAIL" ]; then
            read -p "Enter your email for git commits: " GIT_EMAIL
            if [ -n "$GIT_EMAIL" ]; then
                git config --global user.email "$GIT_EMAIL"
                log_info "Set user.email to: $GIT_EMAIL"
            fi
        fi
    else
        log_info "You can configure later with:"
        log_info "  git config --global user.name \"Your Name\""
        log_info "  git config --global user.email \"your@email.com\""
    fi
else
    log_info "Git global user configuration is already set:"
    log_info "  user.name: $GIT_USER_NAME"
    log_info "  user.email: $GIT_USER_EMAIL"
fi

# ============================================================
# Final Summary
# ============================================================
echo ""
log_info "========================================="
log_info "Desktop Development Environment Setup Complete!"
log_info "========================================="
echo ""
log_info "Installed components:"
echo "  ✓ RPM Fusion repositories"
echo "  ✓ Docker (if installed)"
echo "  ✓ .NET SDK 9.0 & 10.0"
echo "  ✓ DisplayLink driver (if selected)"
echo "  ✓ NVIDIA drivers (if applicable)"
echo "  ✓ Google Chrome"
echo "  ✓ Claude CLI"
echo "  ✓ Visual Studio Code"
echo "  ✓ JetBrains Toolbox"
echo "  ✓ Meld"
echo "  ✓ Discord"
echo "  ✓ kubectl"
echo "  ✓ Freelens"
echo ""
log_warn "IMPORTANT NOTES:"
echo "  • If Docker was installed, log out and back in for group changes"
echo "  • If NVIDIA drivers were installed, reboot your system"
echo "  • ExpanDrive requires manual download if needed"
echo ""
log_info "Happy coding! 🚀"
