# My dotfiles
This directory contains all the dotfiles for my personal configuration.

It is managed with stow symlinking.

The main packages I currently use are:
- bash (the previous dotfiles I used where build on zsh, but because with all other systems you ssh into you use mainly bash or sh, so switching got anoying)
- tmux with some styling and plugins
- neovim instead of vim. The default vim command is overwritten with the nvim version

## Supported Systems
This configuration supports:
- **Ubuntu/Debian** - using apt package manager
- **Fedora** - using dnf package manager

The install script automatically detects your OS and uses the appropriate package manager and package names.

## Requirements
Ensure you have git installed on your system. All other packages are installed when you run the install.sh file in the root of your dotfiles directory.

**Ubuntu/Debian:**
```
$ sudo apt install git
```

**Fedora:**
```
$ sudo dnf install git
```

## Installation
- First do a checkout of the dotfiles repo in your $HOME directory.
- Make sure the install script is executable
- run the installation script


```
$ git clone git@github.com/jithran/dotfiles.git ~/dotfiles
$ cd dotfiles
$ chmod +x install.sh
$ ./install.sh
```

This script will install all the needed packages, applications and run stow for the different application configurations

At the end of the installation, you'll be asked if you want to run the **Desktop Development Wizard** which installs additional development tools (Docker, .NET, VS Code, etc.). This wizard is currently only supported on Fedora.

## Desktop Development Wizard

The desktop wizard (`desktop-wizard.sh`) can be run separately to install additional development tools on Fedora systems:

```bash
$ ./desktop-wizard.sh
```

### Installed Tools
The wizard installs and configures:
- **RPM Fusion** repositories (free & nonfree)
- **Docker** with user permissions
- **.NET SDK** 9.0 & 10.0 with development certificates
- **Visual Studio Code**
- **JetBrains Toolbox**
- **Google Chrome**
- **Discord**
- **Meld** (visual diff and merge tool)
- **DisplayLink** drivers (for USB monitors)
- **NVIDIA** drivers (if NVIDIA GPU is detected)
- **Claude CLI** with token configuration
- **System configuration** (inotify limits for development)
- **GitHub CLI** authentication

The wizard checks if tools are already installed and skips them, making it safe to re-run.

## Keyboard Shortcuts

### Tmux
**Leader Key:** `Ctrl+b` (default tmux prefix)

#### Window & Pane Management
| Shortcut | Description |
|----------|-------------|
| `<leader> v` | Split window vertically |
| `<leader> s` | Split window horizontally |
| `<leader> h/j/k/l` | Navigate panes (vim-style) |
| `Alt+h/j/k/l` | Navigate panes (without prefix) |

#### Pane Resizing
| Shortcut | Description |
|----------|-------------|
| `<leader> H/J/K/L` | Resize pane (large steps: 25/5) |
| `<leader> Alt+h/j/k/l` | Resize pane (1 line at a time) |
| `Alt+y/u/i/o` | Resize pane height (2/10/40/70 lines) |
| `Alt+Y/U/I/O` | Resize pane width (50/107/140/180 columns) |

#### Popups
| Shortcut | Description |
|----------|-------------|
| `<leader> Ctrl+t` | Open terminal popup (80% screen) |
| `<leader> Ctrl+g` | Open lazygit popup (80% screen) |

### Neovim
**Leader Key:** ` ` [space]
**Local Leader Key:** `\`

#### General
| Shortcut | Description |
|----------|-------------|
| `<leader>\|` | Split window right |
| `<leader>-` | Split window bottom |
| `<leader>f` | Format file and restore cursor position |
| `<leader>lg` | Open lazygit neovim plugin |

#### File Navigation (Telescope)
| Shortcut | Description |
|----------|-------------|
| `Ctrl+p` | Find files |
| `Ctrl+g` | Find git files |
| `<leader>buf` | Browse buffers |
| `<leader>gp` | Live grep (search in files) |

#### File Tree (Neo-tree)
| Shortcut | Description |
|----------|-------------|
| `Ctrl+n` | Toggle Neo-tree |
| `<leader>bf` | Show buffers in floating Neo-tree |
| `o` (in Neo-tree) | Open file/folder |
