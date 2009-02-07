" tEchoPair.vim
" @Author:      Thomas Link (micathom AT gmail com?subject=vim-tEchoPair)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-03-24.
" @Last Change: 2008-12-05.
" @Revision:    0.2.307

if &cp || exists("loaded_techopair")
    finish
endif
let loaded_techopair = 2

" if !exists('g:tEchoPairStyle') | let g:tEchoPairStyle = 'inner' | endif
if !exists('g:tEchoPairStyle')   | let g:tEchoPairStyle = 'indicate' | endif
if !exists('g:tEchoPairInstall') | let g:tEchoPairInstall = [] | endif

if !exists('g:tEchoPairIndicateOpen')   | let g:tEchoPairIndicateOpen = ' <<<&'       | endif
if !exists('g:tEchoPairIndicateClose')  | let g:tEchoPairIndicateClose = '&>>> '      | endif
if !exists('g:tEchoPairIndicateCursor') | let g:tEchoPairIndicateCursor = ' <<<&>>> ' | endif

if !exists('g:tEchoPairs')
    " Format:
    " &filetype : args
    " where args is one of:
    " ['fold', ?lineshiftOpen, ?lineshiftClose]
    " ['rx'|'string', open, close]
    " ['rx'|'string', open, middle, close, ?skipfunction ...]
    let g:tEchoPairs = {
                \ 'ruby': [
                    \ ['string', '(', ')'],
                    \ ['string', '{', '}'],
                    \ ['string', '[', ']'],
                \ ],
                \ 'vim': [
                    \ ['string', '(', ')'],
                    \ ['string', '{', '}'],
                    \ ['string', '[', ']'],
                    \ ['rx', '\<for\>', '', '\<endfor\?\>'],
                    \ ['rx', '\<wh\%[ile]\>', '\<endw\%[ile]\>'],
                    \ ['rx', '\<if\>', '\<end\%[if]\>'],
                    \ ['rx', '\<try\>', '\<endt\%[try]\>'],
                    \ ['rx', '\<fu\%[nction]\>', '\<endf\%[nction]\>'],
                \ ],
            \ }
                " \ 'ruby': [
                    " \ ['rx', '\<\(module\|class\|def\|begin\|do\|if\|unless\|while\)\>.*$', '\<\(elsif\|else\)\>.*$', '\<end\>'],
    " \ 'vim': [
                    " \ ['rx', '\<aug\%[roup]\>', '', '\<aug\%[roup] END\>'],
    " \ 'viki': [
    "     \ ['fold', -1],
    " \ ], 
endif

if !exists('g:tEchoPairStyle_inner')
    let g:tEchoPairStyle_inner = ['lisp', 'scheme']
endif

if !exists('g:tEchoPairStyle_indicate')
    let g:tEchoPairStyle_indicate = []
endif


" A convenience command. Users should not need to call it.
command! -nargs=+ -bar TEchoPair call tEchoPair#Echo(<args>)


" Use the  skip expression in |searchpair()|.
" If a 'filetype' specific function named TEchoSkip_{&filetype}() 
" exists, it will take precedence.
fun! TEchoSkip()
    let n = synIDattr(synID(line('.'), col('.'), 1), 'name')
    return (n =~ '\(Comment\|String\)$')
endf


" fun! TEchoSkip_ruby()
"     return TEchoSkip()
" endf
" 
" fun! TEchoSkip_vim()
"     return TEchoSkip()
" endf


" Enable tEchoPair for the current buffer.
command! TEchoPairInstallBuffer call tEchoPair#Install('')
" command! TEchoPairInstallGlobal call tEchoPair#Install('*')
" command! TEchoPairInstallBuffer call tEchoPair#Install(expand('%:p'))


augroup TEchoPair
    autocmd!
augroup END


for ft in g:tEchoPairInstall
    exec 'au TEchoPair Filetype '. ft .' TEchoPairInstallBuffer'
endfor


finish
____________________________________________________________________
CHANGES

0.1:
Initial release

0.2:
- If a function TEchoSkip_{&filetype}() is defined use this as skip 
expression. Use TEchoSkip() as default.
- Keep jumps.
- Format of g:tEchoPairs and arguments to tEchoPair#Echo() have changed.

