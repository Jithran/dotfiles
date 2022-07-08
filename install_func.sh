# Colors
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

# Menu function
menu() {
	echo -ne "
	Do you want to install vim or NeoVim?
	$(ColorGreen '1)') Vim
	$(ColorGreen '2)') NeoVim
	$(ColorGreen '3)') PHP 8.1 & Composer
	$(ColorGreen '4)') Github CLI (gh)
	$(ColorGreen '0)') Cancel and Exit
	$(ColorBlue 'Choose your editor: ')"

	read editor
}

install_vim() {
	echo 'installing vim'
	install_generic

	sudo add-apt-repository ppa:jonathonf/vim
	sudo apt update && sudo apt -y upgrade
	sudo apt -y install vim font-powerline

	ln -s $PWD/.vimrc $INSTALLDIR/.vimrc 2> /dev/null
	ln -s $PWD/.vim $INSTALLDIR/.vim 2> /dev/null

	if [ ! -d "~/.vim/bundle/Vundle.vim" ]; then
		git submodule add -f https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
	fi

	vim +PluginInstall +qall

	# git settings
	git config --global core.editor "vim"

}

install_neovim() {
	echo 'installing neovim'
	install_generic

	sudo apt -y install neovim exuberant-ctags
	sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
	mkdir ~/.config
	mkdir ~/.config/nvim
	ln -s $PWD/init.vim $INSTALLDIR/.config/nvim/init.vim 2> /dev/null

	nvim +PlugInstall +qall
}

install_gh() {
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	sudo apt update
	sudo apt -y install gh
}

install_php() {

	sudo apt -y install --no-install-recommends php8.1
	sudo apt-get install -y php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring php8.1-curl php8.1-xml php8.1-bcmath

	php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
	php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
	php composer-setup.php
	php -r "unlink('composer-setup.php');"
	sudo mv composer.phar /usr/local/bin/composer
}

install_generic() {
	sudo apt update && sudo apt -y upgrade
	# install dependencies
	sudo apt-get -y install git curl tmux ncdu

	curl -sL https://deb.nodesource.com/setup_18.x | sudo bash -
	sudo apt install nodejs npm
}
