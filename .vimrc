set nocompatible              " be iMproved, required
set number relativenumber
syntax on
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" The following are examples of different formats supported.
" Keep Plugin commands between vundle#begin/end.
" plugin on GitHub repo
Plugin 'tpope/vim-fugitive'

" Install fonts for airline and tmuxline
" sudo apt-get install fonts-powerline
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'edkolev/tmuxline.vim'

Plugin 'scrooloose/nerdtree'
Plugin 'shawncplus/phpcomplete.vim'

Plugin 'airblade/vim-gitgutter'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

colo molokai
"let g:airline_pwerline_fonts = 1
let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif
let g:airline_symbols.space = "\ua0"
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline_theme = 'dark'

let NERDTreeMinimalUI = 1

imap jk <Esc>

"remap arrow keys
no <up> ddkP
no <down> ddp
no <left> <Nop>
no <right> <Nop>
ino <up> ddkP
ino <down> ddp
ino <left> <Nop>
ino <right> <Nop>
vno <up> <Nop>
vno <down> <Nop>
vno <left> <Nop>
vno <right> <Nop>

"After we navigate in file, center arround the pointer
nmap G Gzz
nmap n nzz
nmap N Nzz
nmap { {zz
nmap } }zz

map <C-n> :NERDTree<CR>

inoremap <expr> <C-K> ShowDiagraphs()

function! ShowDiagraphs()
	digraphs
	call getchar()
	return "\<C-K>"
endfunction
