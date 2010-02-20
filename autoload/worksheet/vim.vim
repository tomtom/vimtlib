" vim.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-15.
" @Last Change: 2010-02-20.
" @Revision:    0.0.54

if &cp || exists("loaded_worksheet_vim_autoload")
    finish
endif
let loaded_worksheet_vim_autoload = 1
let s:save_cpo = &cpo
set cpo&vim


let s:prototype = {'syntax': 'vim'}


" If the first character is "|", the input string will be processed with 
" |:execute|. Otherwise |eval()| will be used.
function! s:prototype.Evaluate(lines) dict "{{{3
    let vim = join(a:lines, "\n")
    if vim[0] == '|'
        exec vim[1 : -1]
        return ''
    else
        return string(eval(vim))
    endif
endf


function! worksheet#vim#InitializeInterpreter(worksheet) "{{{3
endf


function! worksheet#vim#InitializeBuffer(worksheet) "{{{3
    call extend(a:worksheet, s:prototype)
    runtime indent/vim.vim
    runtime ftplugin/vim.vim
endf


let &cpo = s:save_cpo
unlet s:save_cpo
