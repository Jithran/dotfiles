# My dotfiles
This directory contains all the dotfiles for my personal configuration.

It is managed with stow symlinking.

The main packages I currently use are:
- bash (the previous dotfiles I used where build on zsh, but because with all other systems you ssh into you use mainly bash or sh, so switching got anoying)
- tmux with some styling and plugins
- neovim instead of vim. The default vim command is overwritten with the nvim version

## Requirements
Ensure you have git installed on your system. All other packages are installed when you run the install.sh file in the root of your dotfiles directory.

```
$ sudo apt install git
```

## Installation
- First do a checkout of the dotfiles repo in your $HOME directory.
- Make sure the install script is executable
- run the installation script


```
$ git clone git@github.com/jithran/dotfiles.git dotfiles
$ cd dotfiles
$ chmod +x install.sh
$ ./install.sh
```

This script will install all the needed packages, applications and run stow for the different application configurations
