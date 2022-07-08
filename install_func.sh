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
	curl -fsSL https://cli.github.compackages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	sudo apt update
	sudo apt -y install gh/
}

install_generic() {
	sudo apt update && sudo apt -y upgrade
	# install dependencies
	sudo apt-get -y install git curl tmux ncdu

	curl -sL https://deb.nodesource.com/setup_18.x | sudo bash -
	sudo apt install nodejs npm
}
