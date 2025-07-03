set nocompatible              " be iMproved, required
set number relativenumber
set path+=**                  " Default search into subfolders with :find ...
set wildmenu                  " Display all matching files with tab complete
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
" Plugin 'edkolev/tmuxline.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'shawncplus/phpcomplete.vim'
Plugin 'airblade/vim-gitgutter'
Plugin 'ctrlp.vim'
" Plugin 'valloric/YouCompleteMe'
Plugin 'mbbill/undotree'
Plugin 'prettier/vim-prettier'
Plugin 'zefei/vim-wintabs'
Plugin 'zefei/vim-wintabs-powerline'
call vundle#end()            " required
filetype plugin indent on    " required
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set noswapfile
set autoindent
set smartindent
set incsearch
set term=screen-256color

" File Browsing, Tweaks for browsing
let g:netrw_banner=0        " Disable banner
let g:netrw_browse_split=4  " open in prior window
let g:netrw_altv=1          " open splits to the right
let g:netrw_liststyle=3     " tree view
let g:netrw_list_hide=netrw_gitignore#Hide()
let g:netrw_list_hide.=',\(^|\s\s\)\zs\.\S\+'

hi Normal guibg=NONE ctermbg=NONE

color molokai
set background=dark

let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
 let g:airline_symbols = {}
endif
let g:airline_symbols.space = "\ua0"
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline_theme = 'deus'

let g:ctrlp_show_hidden = 1

let NERDTreeMinimalUI = 1

imap jk <Esc>
imap kj <Esc>

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

nmap <C-s> :w<CR>
vmap <C-s> <Esc><C-s>gv
imap <C-s> <Esc><C-s>

"After we navigate in file, center arround the pointer
nmap G Gzz
nmap n nzz
nmap N Nzz
nmap { {zz
nmap } }zz

"wintabs plugin mapping
map <C-H> <Plug>(wintabs_previous)
map <C-L> <Plug>(wintabs_next)

map <F7> gg=G<C-o><C-o>
map <F4> :set wrap!<CR>

map <C-n> :NERDTree<CR>
nmap <C-j> :NERDTreeFind<CR>
nmap <C-k> :buffers<CR>:buffer<Space>
"map <C-w> :set wrap!<CR>
nnoremap <F5> :UndotreeToggle<CR>

inoremap <expr> <C-K> ShowDiagraphs()

function! ShowDiagraphs()
	digraphs
	call getchar()
	return "\<C-K>"
endfunction
