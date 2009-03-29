" tmarks.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-29.
" @Last Change: 2009-03-29.
" @Revision:    0.0.24

let s:save_cpo = &cpo
set cpo&vim


function! tmarks#AgentDeleteMark(world, selected) "{{{3
    for l in a:selected
        call s:DelMark(s:GetMark(l))
    endfor
    let a:world.base  = s:GetList()
    let a:world.state = 'display'
    return a:world
endf


function! s:DelMark(m) "{{{3
    exec 'delmarks '. escape(a:m, '"\')
endf


function! s:GetList() "{{{3
    return tlib#cmd#OutputAsList('marks')[1:-1]
endf


function! s:GetLocalList() "{{{3
    let local_marks = s:GetList()
    call filter(local_marks, 'v:val =~ '' \l ''')
    return local_marks
endf


function! s:GetMark(line) "{{{3
    return matchstr(a:line, '^ \+\zs\S')
endf


" Delete all (lower-case) marks at the specified line.
" :display: tmarks#DeleteInRange(?line1=line('.'), ?line2=line('.'))
function! tmarks#DeleteInRange(...) "{{{3
    TVarArg ['line1', line('.')], ['line2', line('.')]
    let local_marks = s:GetLocalList()
    call filter(local_marks, 'matchstr(v:val, ''\l \+\zs\d\+'') >= line1 && matchstr(v:val, ''\l \+\zs\d\+'') <= line2')
    for mark in local_marks
        call s:DelMark(s:GetMark(mark))
    endfor
endf


" Delete all (lower-case) marks for the current buffer.
function! tmarks#DeleteAllMarks() "{{{3
    let local_marks = s:GetLocalList()
    for mark in local_marks
        call s:DelMark(s:GetMark(mark))
    endfor
endf


let s:local_marks = split('abcdefghijklmnopqrstuvwxyz', '\zs')

function! tmarks#PlaceNextMarkAtLine(...) "{{{3
    TVarArg ['line', line('.')]
    let local_marks = s:GetLocalList()
    let i = 0
    for mark in local_marks
        let this = s:GetMark(mark)
        let that = s:local_marks[i]
        if this !=# that
            exec line .'mark '. that
            return
        endif
        let i += 1
    endfor
    echohl Error
    echom 'TMarks: No mark available'
    echohl None
endf


function! tmarks#List() "{{{3
    keepjumps let m = tlib#input#List('s', 'Marks', s:GetList(), g:tmarks_handlers)
    if !empty(m)
        exec 'norm! `'. s:GetMark(m)
    endif
endf

let &cpo = s:save_cpo
unlet s:save_cpo
