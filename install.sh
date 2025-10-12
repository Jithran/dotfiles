#!/usr/bin/env bash

INSTALLDIR="${1-$HOME}"

sudo apt update && sudo apt upgrade -y

sudo apt -y install curl ncdu make automake autoconf libtool pkg-config libevent liblevent-dev libncurses-dev bison mlocate tree neofetch ripgrep tar bpytop

# Install tmux
wget https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz
tar -zsf tmux-3.5a.tar-gz
cd tmux-3.5a
./configure && make
sudo make install
cd ..
rm -rf tmux-3.5*

# Install neovim
wget https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage
chmod u+x nvim-linux-x86_64.appimage
sudo mv nvim-linux-arm64.appimage /usr/bin/nvim


# Use stow to symlink all config files
stow bash nvim tmux
