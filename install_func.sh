#!/bin/bash

# Colors
red='\e[31m'
green='\e[32m'
blue='\e[34m'
clear='\e[0m'

# Improved Color Functions
echo_red() { echo -e "${red}$1${clear}"; }
echo_green() { echo -e "${green}$1${clear}"; }
echo_blue() { echo -e "${blue}$1${clear}"; }

# Alert Function
alert() {
    echo_red "\n\n\t###########################################################\n"
    echo_red "\t#### $1 \n"
    echo_red "\t###########################################################\n\n"
}

# Check Command Existence
command_exists() {
    command -v "$1" &> /dev/null
}

# Apt Update and Upgrade
apt_update_upgrade() {
    sudo apt update && sudo apt -y upgrade
}

# Menu Function
menu() {
    echo -ne "
    Do you want to install vim or NeoVim?
    $(echo_green '1)') Vim
    $(echo_green '2)') NeoVim
    $(echo_green '3)') PHP 8.1 & Composer
    $(echo_green '4)') GitHub CLI (gh)
    $(echo_green '5)') ZSH shell
    $(echo_green '6)') Docker installation
    $(echo_green '7)') Install Snap & packages
    $(echo_green '9)') Install all (with NeoVim)
    $(echo_green '10)') Install all (with Vim)
    $(echo_green '0)') Cancel and Exit
    Choose your option: "
    read -r editor
}

# Error Check Wrapper
check_error() {
    if [ $? -ne 0 ]; then
        alert "$1"
        exit 1
    fi
}

install_complete() {
    install_generic
    install_php
    install_gh
    install_zsh
    install_docker
    install_snap
    # Ensure you call each function that performs an installation
    # Consider adding checks to see if the user wants to proceed with each installation
}

# Note: For brevity, only the install_vim function has been fully refactored.
# You should refactor other installation functions (`install_neovim`, `install_php`, etc.)
# following the same pattern:
# - Use `command_exists` to check for existing installations.
# - Use `apt_update_upgrade` to ensure system packages are up to date.
# - Use `check_error` after commands that can fail to ensure errors are handled properly.
# - Properly quote all variable expansions and paths.

install_vim() {
    if command_exists vim; then
        alert "Vim is already installed."
        return
    fi

    echo "Installing Vim..."
    apt_update_upgrade
    sudo add-apt-repository ppa:jonathonf/vim -y
    sudo apt update
    sudo apt -y install vim fonts-powerline
    check_error "Vim installation failed."

    # Configure vim
    # Assuming .vimrc and .vim are in the same directory as this script
    ln -s "$PWD/.vimrc" "$INSTALLDIR/.vimrc" 2> /dev/null || alert "Failed to link .vimrc"
    ln -s "$PWD/.vim" "$INSTALLDIR/.vim" 2> /dev/null || alert "Failed to link .vim directory"

    if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
        git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
        check_error "Failed to clone Vundle."
    fi

    vim +PluginInstall +qall
}


# Function for installing NeoVim
install_neovim() {
    if command_exists nvim; then
        alert "NeoVim is already installed."
        return
    fi

    alert "Installing NeoVim..."
    apt_update_upgrade

    # Install dependencies
    sudo apt-get -y install ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen
    check_error "Failed to install NeoVim dependencies."

    # Clone NeoVim and compile it
    git clone https://github.com/neovim/neovim
    check_error "Failed to clone NeoVim repository."

    pushd neovim
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    check_error "Failed to compile NeoVim."
    sudo make install
    check_error "Failed to install NeoVim."
    popd

    rm -rf neovim
    check_error "Failed to clean up after NeoVim installation."

    # Install vim-plug for NeoVim
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    check_error "Failed to install vim-plug for NeoVim."

    # Setup AstroNvim configuration
    if [ ! -d "$HOME/.config/nvim" ]; then
        mkdir -p "$HOME/.config/nvim"
        git clone https://github.com/AstroNvim/AstroNvim ~/.config/nvim
        check_error "Failed to setup AstroNvim."

        nvim +PackerSync +qall
        check_error "Failed to synchronize AstroNvim packages."
    else
        alert "AstroNvim configuration already exists. Skipping..."
    fi

    echo_green "Neovim successfully installed"
}



install_gh() {
    if command_exists gh; then
        echo 'GitHub CLI (gh) is already installed.'
        return
    fi

    echo 'Installing GitHub CLI (gh)...'

    # Import the GitHub CLI repository GPG key and add the repository.
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    check_error "Failed to import GitHub CLI GPG key."

    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    check_error "Failed to change permissions for GitHub CLI GPG key."

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    check_error "Failed to add GitHub CLI to the sources list."

    # Update the package list and install gh.
    apt_update_upgrade
    sudo apt -y install gh
    check_error "GitHub CLI (gh) installation failed."

    echo_green 'GitHub CLI (gh) installed successfully.'
}


install_php() {
    if command_exists php; then
        echo 'PHP is already installed.'
        return
    fi

    echo 'Installing the latest version of PHP...'

    # PHP version to install
    php_version="8.2"

    # Update and install PHP
    apt_update_upgrade
    sudo apt -y install --no-install-recommends "php$php_version"
    check_error "Failed to install PHP $php_version."

    # Install common extensions
    sudo apt-get install -y "php${php_version}-cli" "php${php_version}-common" "php${php_version}-mysql" \
    "php${php_version}-zip" "php${php_version}-gd" "php${php_version}-mbstring" "php${php_version}-curl" \
    "php${php_version}-xml" "php${php_version}-bcmath"
    check_error "Failed to install PHP $php_version extensions."

    # Install Composer
    echo 'Installing Composer...'
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    sudo mv composer.phar /usr/local/bin/composer
    check_error "Composer installation failed."

    echo_green 'PHP and Composer installed successfully.'
}


install_zsh() {
    if command_exists zsh; then
        echo 'ZSH is already installed.'
        return
    fi

    echo 'Installing ZSH and setting it up...'

    # Install ZSH
    sudo apt -y install zsh
    check_error "ZSH installation failed."

    # Install powerline and fonts-powerline
    sudo apt-get -y install powerline fonts-powerline
    check_error "Powerline and fonts-powerline installation failed."

    # Clone oh-my-zsh
    git clone https://github.com/robbyrussell/oh-my-zsh.git "$HOME/.oh-my-zsh"
    check_error "Cloning oh-my-zsh failed."

    # Copy the zsh template configuration
    cp "$HOME/.oh-my-zsh/templates/zshrc.zsh-template" "$HOME/.zshrc"
    check_error "Copying .zshrc template failed."

    # Change default ZSH theme to agnoster
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' "$HOME/.zshrc"
    check_error "Setting ZSH theme to agnoster failed."

    # Change the default shell to zsh
    chsh -s $(which zsh)
    check_error "Changing default shell to ZSH failed."

    # Install zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" --depth 1
    check_error "Cloning zsh-syntax-highlighting failed."

    # Append zsh-syntax-highlighting to .zshrc
    echo "source ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$HOME/.zshrc"
    check_error "Appending zsh-syntax-highlighting to .zshrc failed."

    echo_blue "Appending config to .zshrc file"
    cat "$PWD/.zshrc_post" >> "$INSTALLDIR/.zshrc"

    echo_green 'ZSH installed and configured successfully.'
}


install_docker() {
    if command_exists docker; then
        echo 'Docker is already installed.'
        return
    fi

    echo 'Installing Docker...'

    sudo apt -y install apt-transport-https ca-certificates curl software-properties-common
    check_error "Package installation for Docker failed."

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    check_error "Adding Docker's official GPG key failed."

    sudo add-apt-repository "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    check_error "Adding Docker repository failed."

    apt_update_upgrade

    sudo apt -y install docker-ce docker-compose
    check_error "Docker installation failed."

    sudo groupadd docker
    sudo usermod -aG docker $USER
    check_error "Adding user to the Docker group failed."

    echo 'Docker installed successfully. You might need to log out and back in for this to take effect.'
}


install_snap() {
    echo 'Installing Snap and some snap packages...'

    if ! command_exists snap; then
        sudo apt -y install snapd
        check_error "Snapd installation failed."
    fi

    sudo snap install snap-store
    check_error "Snap Store installation failed."

	sudo snap install bpytop
	sudo snap connect bpytop:mount-14observe
	sudo snap connect bpytop:network-control
	sudo snap connect bpytop:hardware-observe
	sudo snap connect bpytop:system-observe
	sudo snap connect bpytop:process-control
	sudo snap connect bpytop:physical-memory-observe

    sudo snap install emote #install Emote snap package 🤞
    check_error "emote snap installation failed."

    sudo snap install --classic code
    check_error "Visual Studio Code snap installation failed."

    echo 'Snap and initial packages installed successfully.'
}


install_generic() {
    echo 'Running generic installations and configurations...'

    # Update and upgrade packages
    apt_update_upgrade

    # Install basic dependencies
    sudo apt-get -y install git curl tmux ncdu nodejs
    check_error "Failed to install basic dependencies."

    # Install Node.js (Example: Using NodeSource for the latest versions)
    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    check_error "Setting up NodeSource repository failed."
    sudo apt-get install -y nodejs
    check_error "Node.js installation failed."

    # Configuration file linking and copying
    # It's a good practice to check if the target files already exist to prevent unintended overwrites.
    # For symbolic links (ln -s), the -f option can force the link, but careful handling is advisable.

    # .bash_aliases
    if [ ! -f "$INSTALLDIR/.bash_aliases" ]; then
        ln -s "$PWD/.bash_aliases" "$INSTALLDIR/.bash_aliases"
        check_error "Linking .bash_aliases failed."
    else
        echo ".bash_aliases already exists. Skipping..."
    fi

    # .bashrc
    # Appending custom settings to .bashrc. Consider checking for existing settings to avoid duplicates.
    if ! grep -q 'Custom bashrc settings' "$INSTALLDIR/.bashrc"; then
        cat "$PWD/.bashrc_post" >> "$INSTALLDIR/.bashrc"
        check_error "Appending to .bashrc failed."
    else
        echo "Custom .bashrc settings already exist. Skipping..."
    fi

    # .tmux.conf
    if [ ! -f "$INSTALLDIR/.tmux.conf" ]; then
        ln -s "$PWD/.tmux.conf" "$INSTALLDIR/.tmux.conf"
        check_error "Linking .tmux.conf failed."
    else
        echo ".tmux.conf already exists. Skipping..."
    fi

    # Tmux Plugin Manager (TPM)
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        check_error "Cloning Tmux Plugin Manager (TPM) failed."
    else
        echo "Tmux Plugin Manager (TPM) already installed. Skipping..."
    fi

    # Install TPM plugins
    "$HOME/.tmux/plugins/tpm/bin/install_plugins"
    check_error "TPM plugin installation failed."

    echo 'Generic installations and configurations completed successfully.'
}


