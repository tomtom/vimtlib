" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-14.
" @Last Change: 2009-03-15.
" @Revision:    45
" GetLatestVimScripts: 0 0 :AutoInstall: quickfixsigns.vim
" Mark quickfix & location list items with signs

if &cp || exists("loaded_quickfixsigns") || !has('signs')
    finish
endif
let loaded_quickfixsigns = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:quickfixsigns_lists')
    " A list of list definitions whose items should be marked with signs.
    "
    " A list definition is a |Dictionary| with the following fields:
    "
    "   sign: The name of the sign, which has to be defined
    "   get:  A vim script expression that returns a list compatible with 
    "         |getqflist()|.
    " :read: let g:quickfixsigns_lists = [...] "{{{2
    let g:quickfixsigns_lists = [
                \ {'sign': 'QFS_QFL', 'get': 'getqflist()', 'event': 'BufEnter'},
                \ {'sign': 'QFS_LOC', 'get': 'getloclist(winnr())', 'event': 'BufEnter'},
                \ ]
endif

if !exists('g:quickfixsigns_show_marks') || g:quickfixsigns_show_marks
    " If non-null, also display signs for the marks a-zA-Z.
    let g:quickfixsigns_show_marks = 1 "{{{2
    call add(g:quickfixsigns_lists, {'sign': '*quickfixsigns#MarkSign', 'get': 'quickfixsigns#Marks()', 'event': 'any', 'id': 'quickfixsigns#MarkId'})
endif


if !exists('g:quickfixsigns_balloon')
    " If non-null, display a balloon when hovering with the mouse over 
    " the sign.
    " buffer-local or global
    let g:quickfixsigns_balloon = 1   "{{{2
endif

augroup QuickFixSigns
    autocmd!
    autocmd BufEnter * call quickfixsigns#Set('BufEnter')
    " autocmd CursorMoved,CursorMovedI * call quickfixsigns#Set('')
    if g:quickfixsigns_show_marks
        " autocmd BufEnter,CursorHold,CursorHoldI,InsertEnter,InsertChange,WinEnter * call quickfixsigns#Set('')
        autocmd BufEnter,CursorHold,CursorHoldI,InsertEnter,InsertChange * call quickfixsigns#Set('any')
    endif
    unlet g:quickfixsigns_show_marks
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release

