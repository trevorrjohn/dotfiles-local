call plug#begin()


Plug 'flazz/vim-colorschemes'
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }

" :MasonUpdate updates registry contents
Plug 'williamboman/mason.nvim', { 'do': ':MasonUpdate' }


call plug#end()

" Color scheme
colorscheme Tomorrow-Night-Eighties

" enable mouse
set mouse=a

"let mapleader = ","

set hlsearch
hi SpellBad       term=reverse ctermbg=240 gui=undercurl guisp=Red
hi SpellCap       term=reverse ctermbg=240 gui=undercurl guisp=Blue
hi SpellRare      term=reverse ctermbg=240 gui=undercurl guisp=Magenta
hi SpellLocal     term=underline ctermbg=240 gui=undercurl guisp=DarkCyan

nnoremap <C-c> :noh<ESC>

imap bp<tab> binding.pry<ESC>
imap <c-l> <space>=><space>

nnoremap [<space> :put! _<ESC>j
nnoremap ]<space> :put _<ESC>k

set nowrap

nnoremap \ :NERDTreeToggle<CR>
map \| :NERDTreeFind<CR>

let $FZF_DEFAULT_OPTS = '--bind ctrl-a:select-all'
function! s:build_quickfix_list(lines)
  call setqflist(map(copy(a:lines), '{ "filename": v:val }'))
  copen
  cc
endfunction

let g:fzf_history_dir = '~/.local/share/fzf-history'

let g:fzf_action = {
  \ 'ctrl-q': function('s:build_quickfix_list'),
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

let g:rg_command = '
  \ rg --column --line-number --no-heading --fixed-strings --ignore-case --hidden --follow --color "always"
  \ -g "*.{js,json,php,md,styl,jade,html,config,py,cpp,c,go,hs,rb,conf}"
  \ -g "!{.git,node_modules,vendor}/*" '

" make test commands execute using vimux
let test#strategy = "dispatch"

map frz<tab> ggO<ESC>ggO# frozen_string_literal: true<ESC><S-g>i
imap frz<tab> # frozen_string_literal: true<ESC>

command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview('up:60%')
  \           : fzf#vim#with_preview('right:50%:hidden', '?'),
  \   <bang>0)

" Likewise, Files command with preview window
command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

noremap <c-p> :History<cr>
noremap <Leader>f :GFiles<cr>
noremap <Leader>F :Files<cr>

autocmd BufWritePre * %s/\s\+$//e

" Auto save when buffer lose focus
autocmd FocusLost,BufLeave * silent! wa

" enable AutoSave on Vim startup
let g:auto_save = 1
" disable auto save on insert mode because it jumps to beginning of line
let g:auto_save_in_insert_mode = 0

" auto fmt of jsonnet
let g:jsonnet_fmt_on_save = 1

imap fd <ESC>

set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
