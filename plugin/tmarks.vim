" tmarks.vim -- A simple marks browser
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-08-23.
" @Last Change: 2009-02-15.
" @Revision:    0.0.26
" GetLatestVimScripts: <+SCRIPTID+> 1 tmarks.vim

if &cp || exists("loaded_tmarks")
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 11
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 11
        echoerr 'tlib >= 0.11 is required'
        finish
    endif
endif
let loaded_tmarks = 1
let s:save_cpo = &cpo
set cpo&vim

function! s:SNR() "{{{3
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
endf


if !exists('g:tmarks_handlers') "{{{2
    let g:tmarks_handlers = [
            \ {'key':  4, 'agent': s:SNR() .'AgentDeleteMark', 'key_name': '<c-d>', 'help': 'Delete mark'},
            \ ]
            " \ {'pick_last_item': 0},
endif


function! s:AgentDeleteMark(world, selected) "{{{3
    for l in a:selected
        let m = s:GetMark(l)
        exec 'delmarks '. escape(m, '"\')
    endfor
    let a:world.base  = s:GetList()
    let a:world.state = 'display'
    return a:world
endf


function! s:GetList() "{{{3
    return tlib#cmd#OutputAsList('marks')[1:-1]
endf


function! s:GetMark(line) "{{{3
    return matchstr(a:line, '^ \+\zs\S')
endf


function! TMarks() "{{{3
    keepjumps let m = tlib#input#List('s', 'Marks', s:GetList(), g:tmarks_handlers)
    if !empty(m)
        exec 'norm! `'. s:GetMark(m)
    endif
endf

command! TMarks call TMarks()



let &cpo = s:save_cpo
unlet s:save_cpo


finish
-----------------------------------------------------------------------

Command~

:Tmarks
    List marks

Keys~
    <c-d> ... Delete mark
    <cr>  ... Jump to mark

