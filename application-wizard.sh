#!/usr/bin/env bash

set -e  # Exit on any error
set -u  # Exit on undefined variable

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

log_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
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
    log_error "This application wizard currently only supports Fedora."
    log_error "Detected OS: $OS"
    exit 1
fi

# ============================================================
# Application Installation Functions
# ============================================================

install_surfshark() {
    log_step "Installing Surfshark VPN..."

    if command -v flatpak &> /dev/null; then
        # Check if Flathub is configured
        if ! flatpak remotes | grep -q flathub; then
            log_info "Adding Flathub repository..."
            flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        fi

        # Check if Surfshark is already installed
        if flatpak list | grep -q "com.surfshark.Surfshark"; then
            log_info "Surfshark is already installed. Skipping."
        else
            log_info "Installing Surfshark from Flathub..."
            flatpak install -y flathub com.surfshark.Surfshark
            log_info "Surfshark installed successfully!"
            log_info "You can start it with: flatpak run com.surfshark.Surfshark"
            log_info "Or search for 'Surfshark' in your application menu."
        fi
    else
        log_error "Flatpak is not installed. Please install Flatpak first."
        log_warn "Install with: sudo dnf install flatpak"
        return 1
    fi
}

install_vscode() {
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
}

install_jetbrains_toolbox() {
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
}

install_meld() {
    log_step "Installing Meld..."
    if command -v meld &> /dev/null; then
        log_info "Meld is already installed: $(meld --version)"
    else
        log_info "Installing Meld..."
        sudo dnf install -y meld
        log_info "Meld installed successfully"
    fi
}

install_discord() {
    log_step "Installing Discord..."
    if command -v discord &> /dev/null || [ -f /usr/bin/discord ]; then
        log_info "Discord is already installed. Skipping."
    else
        log_info "Installing Discord..."
        sudo dnf install -y discord
        log_info "Discord installed successfully"
    fi
}

install_expandrive() {
    log_step "Installing ExpanDrive..."
    if command -v expandrive &> /dev/null || [ -f /usr/bin/expandrive ]; then
        log_info "ExpanDrive is already installed. Skipping."
    else
        log_info "Downloading and installing ExpanDrive..."
        ORIGINAL_DIR=$(pwd)
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"

        if wget -q --show-progress -O expandrive.rpm "https://www.expandrive.com/api/download/expandrive?platform=linux&ext=rpm"; then
            log_info "Installing ExpanDrive..."
            sudo dnf install -y ./expandrive.rpm
            log_info "ExpanDrive installed successfully"
        else
            log_error "Failed to download ExpanDrive"
            log_warn "Please download manually from: https://www.expandrive.com/desktop/linux/"
        fi

        cd "$ORIGINAL_DIR"
        rm -rf "$TEMP_DIR"
    fi
}

install_freelens() {
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
}

install_ghostty() {
    log_step "Installing Ghostty Terminal..."
    local ghostty_newly_installed=false

    if command -v ghostty &> /dev/null; then
        log_info "Ghostty is already installed: $(ghostty --version 2>/dev/null || echo 'version unknown')"
    else
        log_info "Installing Ghostty from Copr repository..."

        # Enable Copr repository for Ghostty
        if ! dnf copr list | grep -q "pgdev/ghostty"; then
            log_info "Enabling Copr repository pgdev/ghostty..."
            sudo dnf copr enable -y pgdev/ghostty
        fi

        log_info "Installing Ghostty..."
        sudo dnf install -y ghostty
        log_info "Ghostty installed successfully"
        ghostty_newly_installed=true
    fi

    # Ask to set as default terminal (for new installs)
    if [ "$ghostty_newly_installed" = true ]; then
        echo ""
        read -p "Set Ghostty as default terminal? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            configure_ghostty_default
        fi
    fi
}

configure_ghostty_default() {
    log_info "Configuring Ghostty as default terminal..."

    # Detect desktop environment
    DESKTOP_ENV="${XDG_CURRENT_DESKTOP:-unknown}"
    log_info "Detected desktop environment: $DESKTOP_ENV"

    case "$DESKTOP_ENV" in
        *KDE*|*Plasma*)
            # Set Ghostty as default terminal emulator for KDE
            KDEGLOBALS="$HOME/.config/kdeglobals"
            if [ -f "$KDEGLOBALS" ]; then
                if grep -q "^\[General\]" "$KDEGLOBALS"; then
                    if grep -q "^TerminalApplication=" "$KDEGLOBALS"; then
                        sed -i 's/^TerminalApplication=.*/TerminalApplication=ghostty/' "$KDEGLOBALS"
                    else
                        sed -i '/^\[General\]/a TerminalApplication=ghostty' "$KDEGLOBALS"
                    fi
                else
                    echo -e "\n[General]\nTerminalApplication=ghostty" >> "$KDEGLOBALS"
                fi
            else
                mkdir -p "$(dirname "$KDEGLOBALS")"
                echo -e "[General]\nTerminalApplication=ghostty" > "$KDEGLOBALS"
            fi
            log_info "Ghostty set as default terminal in KDE"
            ;;
        *GNOME*)
            # For GNOME, set via gsettings if available
            if command -v gsettings &> /dev/null; then
                gsettings set org.gnome.desktop.default-applications.terminal exec 'ghostty' 2>/dev/null || true
                gsettings set org.gnome.desktop.default-applications.terminal exec-arg '' 2>/dev/null || true
                log_info "Ghostty set as default terminal in GNOME"
            else
                log_warn "gsettings not found - please set default terminal manually"
            fi
            ;;
        *)
            log_warn "Unknown desktop environment: $DESKTOP_ENV"
            log_info "Please set Ghostty as default terminal manually in your system settings"
            ;;
    esac
}

# ============================================================
# Add more application installation functions here
# ============================================================
# Example template for adding new applications:
#
# install_appname() {
#     log_step "Installing AppName..."
#     if command -v appname &> /dev/null; then
#         log_info "AppName is already installed. Skipping."
#     else
#         log_info "Installing AppName..."
#         # Installation commands here
#         log_info "AppName installed successfully!"
#     fi
# }

# ============================================================
# Interactive Menu System
# ============================================================

show_menu() {
    log_header "Application Installation Wizard"
    echo ""
    echo "Select applications to install (enter numbers separated by spaces):"
    echo ""
    echo "  1) Visual Studio Code - Code editor by Microsoft"
    echo "  2) JetBrains Toolbox - Manage JetBrains IDEs"
    echo "  3) Meld - Visual diff and merge tool"
    echo "  4) Discord - Voice, video and text communication"
    echo "  5) ExpanDrive - Mount cloud storage as local drives"
    echo "  6) Freelens - Kubernetes IDE"
    echo "  7) Surfshark VPN - Secure VPN service"
    echo "  8) Ghostty - Fast, feature-rich terminal emulator"
    echo ""
    echo "  a) Install ALL applications"
    echo "  q) Quit without installing"
    echo ""
    echo -n "Your choice: "
}

# Parse user selection and return array of selected apps
parse_selection() {
    local selection="$1"
    local -a apps=()

    # Convert to lowercase for easier comparison
    selection=$(echo "$selection" | tr '[:upper:]' '[:lower:]')

    if [[ "$selection" == "a" ]]; then
        apps=("vscode" "jetbrains_toolbox" "meld" "discord" "expandrive" "freelens" "surfshark" "ghostty")
    else
        # Parse individual selections
        for num in $selection; do
            case $num in
                1) apps+=("vscode") ;;
                2) apps+=("jetbrains_toolbox") ;;
                3) apps+=("meld") ;;
                4) apps+=("discord") ;;
                5) apps+=("expandrive") ;;
                6) apps+=("freelens") ;;
                7) apps+=("surfshark") ;;
                8) apps+=("ghostty") ;;
                *) log_warn "Invalid selection: $num" >&2 ;;
            esac
        done
    fi

    # Only echo if we have apps to return
    if [ ${#apps[@]} -gt 0 ]; then
        echo "${apps[@]}"
    fi
}

# Install selected applications
install_selected_apps() {
    local -a apps=("$@")

    if [ ${#apps[@]} -eq 0 ]; then
        log_warn "No valid applications selected."
        exit 0
    fi

    echo ""
    log_header "Starting Installation"
    log_info "Will install: ${apps[*]}"
    echo ""

    read -p "Continue with installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "Installation cancelled."
        exit 0
    fi

    echo ""

    # Install each selected application
    for app in "${apps[@]}"; do
        case $app in
            vscode)
                install_vscode
                ;;
            jetbrains_toolbox)
                install_jetbrains_toolbox
                ;;
            meld)
                install_meld
                ;;
            discord)
                install_discord
                ;;
            expandrive)
                install_expandrive
                ;;
            freelens)
                install_freelens
                ;;
            surfshark)
                install_surfshark
                ;;
            ghostty)
                install_ghostty
                ;;
            # Add more cases here for new applications
            *)
                log_warn "Unknown application: $app"
                ;;
        esac
        echo ""
    done

    # Installation summary
    log_header "Installation Complete!"
    echo ""
    log_info "Successfully processed ${#apps[@]} application(s):"
    for app in "${apps[@]}"; do
        echo "  ✓ $app"
    done
    echo ""
    log_info "Enjoy your new applications! 🚀"
}

# ============================================================
# Main Program Flow
# ============================================================

main() {
    clear

    # Show menu and get selection
    show_menu
    read -r user_selection

    # Convert to lowercase for quit check
    user_selection_lower=$(echo "$user_selection" | tr '[:upper:]' '[:lower:]')

    # Check for quit
    if [[ "$user_selection_lower" == "q" ]]; then
        echo ""
        log_info "Exiting without installing anything."
        exit 0
    fi

    # Parse selection into array of apps
    selected_apps=($(parse_selection "$user_selection"))

    # Install selected apps
    install_selected_apps "${selected_apps[@]}"
}

# Run main program
main
