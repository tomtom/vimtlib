" glark.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=vim-glark)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     07-Feb-2006.
" @Last Change: 2007-08-27.
" @Revision:    0.1.16

noremap  <silent> <buffer> <cr> :call GlarkJump('')<cr>
inoremap <silent> <buffer> <cr> <c-o>:call GlarkJump('')<cr>
noremap  <silent> <buffer> <2-leftmouse> :call GlarkJump('')<cr>
inoremap <silent> <buffer> <2-leftmouse> <c-o>:call GlarkJump('')<cr>
noremap  <silent> <buffer> o :call GlarkJump('')<cr>
inoremap <silent> <buffer> o <c-o>:call GlarkJump('')<cr>
noremap  <silent> <buffer> p :call GlarkJump('p')<cr>
inoremap <silent> <buffer> p <c-o>:call GlarkJump('p')<cr>
noremap  <silent> <buffer> r :call GlarkJump('r')<cr>
inoremap <silent> <buffer> r <c-o>:call GlarkJump('r')<cr>
noremap  <silent> <buffer> f :call GlarkJump('f')<cr>
inoremap <silent> <buffer> f <c-o>:call GlarkJump('f')<cr>
noremap  <silent> <buffer> u :call GlarkUpdate()<cr>
inoremap <silent> <buffer> u <c-o>:call GlarkUpdate()<cr>
noremap  <silent> <buffer> q :wincmd c<cr>
inoremap <silent> <buffer> q <c-o>:wincmd c<cr>
" noremap  <silent> <buffer> <esc> :wincmd c<cr>
" inoremap <silent> <buffer> <esc> <c-o>:wincmd c<cr>
setlocal nomodifiable

if (exists("b:did_ftplugin"))
  finish
endif

" setlocal foldmethod=indent
" setlocal shiftwidth=1
setlocal foldmethod=expr
setlocal foldexpr=GlarkFoldLevel(v:lnum)

if exists('*GlarkFoldLevel')
    finish
endif

fun! GlarkFoldLevel(lnum)
    let li = getline(a:lnum)
    if li =~ '^\S'
        return 0
    elseif li =~ '^[[:space:][:digit:]]\+ [+-] '
        return 2
    else
        return 1
    endif
endf

