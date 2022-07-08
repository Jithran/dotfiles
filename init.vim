:set number
:set relativenumber
:set autoindent
:set tabstop=4
:set shiftwidth=4
:set smarttab
:set softtabstop=4
:set mouse=a

call plug#begin()

Plug 'https://github.com/vim-airline/vim-airline' " Airline
Plug 'vim-airline/vim-airline-themes'
Plug 'https://github.com/preservim/nerdtree' " NerdTree
Plug 'https://github.com/mbbill/undotree' " UndoTree
Plug 'https://github.com/tpope/vim-commentary' " For Commenting gcc & gc
Plug 'https://github.com/ap/vim-css-color' " CSS Color Preview
Plug 'https://github.com/rafi/awesome-vim-colorschemes' " Retro Scheme
Plug 'https://github.com/ryanoasis/vim-devicons' " Developer Icons
Plug 'https://github.com/tc50cal/vim-terminal' " Vim Terminal
Plug 'https://github.com/terryma/vim-multiple-cursors' " CTRL + N for multiple cursors
Plug 'https://github.com/preservim/tagbar' " Tagbar for code navigation
" Plug 'neoclide/coc.nvim', {'branch': 'master', 'do': 'yarn install --frozen-lockfile'}
Plug 'airblade/vim-gitgutter'
Plug 'ctrlpvim/ctrlp.vim'
" Plug 'junegunn/fzf.vim'
" Plug 'glepnir/dashboard-nvim'

call plug#end()

" Plugin mappings
" Nerdtree
nmap <C-j> :NERDTreeFind<CR>
nmap <C-t> :NERDTreeToggle<CR>
" UndoTree
nnoremap <F5> :UndotreeToggle<CR>
" Tagbar
nnoremap <F8> :TagbarToggle<CR>
" Colorscheme
:colorscheme space-vim-dark
" Coc autocomplete
" inoremap <silent><expr> <c-space> coc#refresh()


" center after navigating
nmap G Gzz
nmap n nzz
nmap N Nzz
nmap { {zz
nmap } }zz

" override defaults
nmap <C-s> :w<CR>
imap jk <Esc>
imap kj <Esc>

let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
 let g:airline_symbols = {}
endif
let g:airline_symbols.space = "\ua0"
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 0
let g:airline_theme = 'deus'

let g:ctrlp_show_hidden = 1
