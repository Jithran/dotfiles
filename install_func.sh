# Colors
red='\e[31m'
green='\e[32m'
blue='\e[34m'
clear='\e[0m'

# Color functions
ColorGreen(){
	echo -ne $green$1$clear
}
ColorBlue(){
	echo -ne $blue$1$clear
}
ColorRed(){
	echo -ne $red$1$clear
}

Alert() {
		ColorRed "\n\n\t###########################################################\n"
		ColorRed "\t#### $1 \n"
		ColorRed "\t###########################################################\n\n"
}

# Menu function
menu() {
	echo -ne "
	Do you want to install vim or NeoVim?
	$(ColorGreen '1)') Vim
	$(ColorGreen '2)') NeoVim
	$(ColorGreen '3)') PHP 8.1 & Composer
	$(ColorGreen '4)') Github CLI (gh)
	$(ColorGreen '5)') ZSH shell
	$(ColorGreen '6)') Docker installation
	$(ColorGreen '7)') Install Snap & packages
	$(ColorGreen '9)') Install all (with NeoVim)
	$(ColorGreen '0)') Cancel and Exit
	$(ColorBlue 'Choose your option: ')"

	read editor
}


install_complete() {
	install_neovim
	install_php
	install_zsh
	install_gh
	install_docker
	install_snap
}

install_vim() {
	if ! command -v vim &> /dev/null
	then
		alias vim="nvim"
		echo 'installing vim'
		install_generic

		sudo add-apt-repository ppa:jonathonf/vim
		sudo apt update && sudo apt -y upgrade
		sudo apt -y install vim fonts-powerline

		ln -s $PWD/.vimrc $INSTALLDIR/.vimrc 2> /dev/null
		ln -s $PWD/.vim $INSTALLDIR/.vim 2> /dev/null

		if [ ! -d "~/.vim/bundle/Vundle.vim" ]; then
			git submodule add -f https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
		fi

		vim +PluginInstall +qall

		# git settings
		git config --global core.editor "vim"
	else
		clear
		Alert 'Command vim already installed'
	fi
}

install_neovim() {
	if ! command -v nvim &> /dev/null
	then
		echo 'installing neovim'
		install_generic

		sudo apt-get -y install ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen
		git clone https://github.com/neovim/neovim
		cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo
		sudo make install
		cd ..
		rm -rf neovim
		
		sudo apt -y install exuberant-ctags
		sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
			https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

		if [[ ! -d "$HOME/.config/" ]]; then
			mkdir -p "$HOME/.config/"
		fi

		if [[ ! -d "$HOME/.config/nvim/" ]]; then
			mkdir -p "$HOME/.config/nvim/"
		fi

		ln -s $PWD/init.vim $INSTALLDIR/.config/nvim/init.vim 2> /dev/null

		nvim +PlugInstall +qall
	else
		clear
		Alert 'Command nvim already installed'
	fi
}

install_gh() {
	if ! command -v gh &> /dev/null
	then
		curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
		sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
		sudo apt update
		sudo apt -y install gh
	else
		clear
		Alert 'Command gh already installed'
	fi
}

install_php() {
	if ! command -v php &> /dev/null
	then
		sudo apt -y install --no-install-recommends php8.1
		sudo apt-get install -y php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath

		php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
		php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
		php composer-setup.php
		php -r "unlink('composer-setup.php');"
		sudo mv composer.phar /usr/local/bin/composer
	else
		clear
		Alert 'Command PHP already installed'
	fi
}

install_zsh() {
	if ! command -v zsh &> /dev/null
	then
		#installing ZSH
		sudo apt -y install zsh
		sudo apt-get -y install powerline fonts-powerline

		git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh

		cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
		sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/g' ~/.zshrc

		chsh -s /bin/zsh

		#zsh higlighter 
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh-syntax-highlighting" --depth 1
		cat $PWD/.zshrc_post >> $INSTALLDIR/.zshrc
	else
		clear
		Alert 'Command zsh already installed'
	fi
}

install_docker() {
	if ! command -v docker &> /dev/null
	then
		#install docker support
		sudo apt -y install apt-transport-https ca-certificates curl software-properties-common
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
		sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
		sudo apt update
		sudo apt -y install docker-ce docker-compose
		sudo groupadd docker
		sudo usermod -aG docker $USER
	else
		echo 'Command docker already installed'
	fi
}

install_snap() {
	if ! command -v snap &> /dev/null
	then
		#install Snap packages
		sudo apt -y install snapd
		sudo snap install snap-store
		sudo snap install hi
		sudo snap install bpytop
		sudo snap connect bpytop:mount-observe
		sudo snap connect bpytop:network-control
		sudo snap connect bpytop:hardware-observe
		sudo snap connect bpytop:system-observe
		sudo snap connect bpytop:process-control
		sudo snap connect bpytop:physical-memory-observe
		sudo snap install emote #install Emote snap package 🤞
	else
		echo 'Command snap already installed'
	fi
}

install_generic() {
	sudo apt update && sudo apt -y upgrade
	curl -sL https://deb.nodesource.com/setup_18.x | sudo bash -

	# install dependencies
	sudo apt-get -y install git curl tmux ncdu nodejs npm

	ln -s $PWD/.bash_aliases $INSTALLDIR/.bash_aliases 2> /dev/null
	cat $PWD/.bashrc_post >> $INSTALLDIR/.bashrc

	ln -s $PWD/.tmux.conf $INSTALLDIR/.tmux.conf 2> /dev/null
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	$HOME/.tmux/plugins/tpm/bin/install_plugins
}

