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
# VM Guest Tools (if running in a virtual machine)
# ============================================================
log_step "Checking for virtual machine environment..."
VIRT_TYPE=$(systemd-detect-virt 2>/dev/null || echo "none")

if [ "$VIRT_TYPE" != "none" ]; then
    log_info "Virtual machine detected: $VIRT_TYPE"

    case "$VIRT_TYPE" in
        vmware)
            if rpm -qa | grep -q "open-vm-tools"; then
                log_info "VMware guest tools are already installed. Skipping."
            else
                log_info "Installing VMware guest tools..."
                sudo dnf install -y open-vm-tools open-vm-tools-desktop
                sudo systemctl enable --now vmtoolsd.service
                log_info "VMware guest tools installed successfully"
            fi
            ;;
        oracle)
            if rpm -qa | grep -q "virtualbox-guest-additions"; then
                log_info "VirtualBox guest additions are already installed. Skipping."
            else
                log_info "Installing VirtualBox guest additions..."
                sudo dnf install -y virtualbox-guest-additions
                log_info "VirtualBox guest additions installed successfully"
            fi
            ;;
        kvm|qemu)
            QEMU_INSTALLED=false
            if rpm -qa | grep -q "qemu-guest-agent"; then
                log_info "QEMU guest agent is already installed."
                QEMU_INSTALLED=true
            fi
            if rpm -qa | grep -q "spice-vdagent"; then
                log_info "SPICE agent is already installed."
            elif [ "$QEMU_INSTALLED" = true ]; then
                log_info "Skipping SPICE agent (QEMU tools already present)."
            else
                log_info "Installing KVM/QEMU guest tools..."
                sudo dnf install -y qemu-guest-agent spice-vdagent
                sudo systemctl enable --now qemu-guest-agent.service
                sudo systemctl enable --now spice-vdagentd.service
                log_info "KVM/QEMU guest tools installed successfully"
            fi
            ;;
        microsoft)
            if rpm -qa | grep -q "hyperv-daemons"; then
                log_info "Hyper-V daemons are already installed. Skipping."
            else
                log_info "Installing Hyper-V guest tools..."
                sudo dnf install -y hyperv-daemons
                sudo systemctl enable --now hypervkvpd.service
                sudo systemctl enable --now hypervvssd.service
                log_info "Hyper-V guest tools installed successfully"
            fi
            ;;
        *)
            log_info "Unknown virtualization type: $VIRT_TYPE. Skipping guest tools."
            ;;
    esac
else
    log_info "Not running in a virtual machine. Skipping guest tools."
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
        # DisplayLink's post-install script may fail with a non-critical warning
        # about systemd unit files. We handle this gracefully.
        if sudo dnf install -y displaylink; then
            log_info "DisplayLink installed successfully"
        else
            log_warn "DisplayLink installation completed with warnings"
            log_info "Running systemctl daemon-reload to resolve unit file warnings..."
            sudo systemctl daemon-reload
            log_info "DisplayLink driver should now be functional"
        fi
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
            xdg-settings set default-web-browser google-chrome.desktop 2>/dev/null
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
# Optional Applications
# ============================================================
# NOTE: Visual Studio Code, JetBrains Toolbox, Meld, Discord,
# ExpanDrive, and Freelens have been moved to application-wizard.sh
# Run ./application-wizard.sh to install optional applications
# ============================================================

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
echo "  ✓ VM guest tools (if in VM)"
echo "  ✓ Docker (if installed)"
echo "  ✓ .NET SDK 9.0 & 10.0"
echo "  ✓ DisplayLink driver (if selected)"
echo "  ✓ NVIDIA drivers (if applicable)"
echo "  ✓ Google Chrome"
echo "  ✓ Claude CLI"
echo "  ✓ kubectl"
echo ""
log_warn "IMPORTANT NOTES:"
echo "  • If Docker was installed, log out and back in for group changes"
echo "  • If NVIDIA drivers were installed, reboot your system"
echo ""
log_info "NEXT STEP:"
echo "  • Run ./application-wizard.sh to install optional applications:"
echo "    - Visual Studio Code"
echo "    - JetBrains Toolbox"
echo "    - Meld"
echo "    - Discord"
echo "    - ExpanDrive"
echo "    - Freelens"
echo "    - Surfshark VPN"
echo ""
log_info "Happy coding! 🚀"
