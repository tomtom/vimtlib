" sh.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-15.
" @Last Change: 2010-02-20.
" @Revision:    0.0.13

if &cp || exists("loaded_worksheet_sh_autoload")
    finish
endif
let loaded_worksheet_sh_autoload = 1
let s:save_cpo = &cpo
set cpo&vim


let s:prototype = {'syntax': 'sh'}


function! s:prototype.Evaluate(lines) dict "{{{3
    return system(join(a:lines, "\n"))
endf


function! worksheet#sh#InitializeInterpreter(worksheet) "{{{3
endf


function! worksheet#sh#InitializeBuffer(worksheet) "{{{3
    call extend(a:worksheet, s:prototype)
    runtime indent/sh.vim
    runtime ftplugin/sh.vim
endf


let &cpo = s:save_cpo
unlet s:save_cpo
