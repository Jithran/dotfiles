set nocompatible              " be iMproved, required
set number relativenumber
syntax on
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-fugitive'
" Install fonts for airline and tmuxline
" sudo apt-get install fonts-powerline
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'edkolev/tmuxline.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'shawncplus/phpcomplete.vim'
Plugin 'airblade/vim-gitgutter'
Plugin 'ctrlp.vim'
call vundle#end()            " required
filetype plugin indent on    " required
set tabstop=4
set shiftwidth=4
set expandtab

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

let g:ctrlp_show_hidden = 1

let NERDTreeMinimalUI = 1

imap jk <Esc>

"remap arrow keys
no <up> ddkP
no <down> ddp
no <left> <Nop>
no <right> <Nop>
ino <up> <Esc>ddkPi
ino <down> <Esc>ddpi
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

map <F7> gg=G<C-o><C-o>

map <C-n> :NERDTree<CR>

inoremap <expr> <C-K> ShowDiagraphs()

function! ShowDiagraphs()
	digraphs
	call getchar()
	return "\<C-K>"
endfunction
