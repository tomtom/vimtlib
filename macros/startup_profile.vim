" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-04.
" @Last Change: 2010-04-18.
" @Revision:    25
" GetLatestVimScripts: 0 0 startup_profile.vim

let s:save_cpo = &cpo
set cpo&vim

if !has('float')
    echom 'startup_profile required +float support'
    finish
endif


if !exists('g:startup_profile_csv')
    " The filename of the CSV file.
    let g:startup_profile_csv = split(&rtp, ',')[0] .'/vim_startup_log.csv' "{{{2
endif

if !exists('g:startup_profile_comma')
    " Comma in floating point numbers.
    let g:startup_profile_comma = '.'   "{{{2
endif

let s:size = 0
let s:lines = 0
let s:time = reltimestr(reltime())
let s:time0 = s:time
let s:scripts = []

function! s:LogScript(filename) "{{{3
    let time = reltimestr(reltime())
    call add(s:scripts, [a:filename, time, s:time])
    let s:time = time
endf

function! s:LogEnd() "{{{3
    let time_all = reltimestr(reltime())
    let timediff_last = s:FloatAsString(str2float(time_all) - str2float(s:time))
    let timediff_all = s:FloatAsString(str2float(time_all) - str2float(s:time0))

    let output = ['No;Filename;Lines;Bytes;Time;TimeDiff']
    for [filename, time, time0] in s:scripts
        let timediff = s:FloatAsString(str2float(time) - str2float(time0))
        if len(output) > 1
            let output[-1] .= timediff
        endif
        let item = len(output) .';'. filename
        if filereadable(filename)
            let lines = len(readfile(filename))
            let s:lines += lines
            let size = getfsize(filename)
            let s:size += size
            let item .= ';'. lines .';'. size .';'. time .';'
        else
            let item .= ' (not readable);;;'. time .';'
        endif
        call add(output, item)
    endfor

    let output[-1] .= timediff_last
    call add(output, ';Total size;'. s:lines .';'. s:size .';'. time_all .';'. timediff_all)
    call writefile(output, g:startup_profile_csv)
    autocmd! StartupLog
    unlet s:size s:lines s:time s:time0 s:scripts
endf

function! s:FloatAsString(num) "{{{3
    return substitute(string(a:num), '[,.]', g:startup_profile_comma, '')
endf

call s:LogScript(expand("<sfile>"))

augroup StartupLog
    autocmd!
    autocmd SourcePre * call s:LogScript(expand('<afile>:p'))
    autocmd VimEnter * call s:LogEnd()
    autocmd VimEnter * delfunction s:LogScript
    autocmd VimEnter * delfunction s:LogEnd
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release

0.2
- Add size data on VimEnter, minimize impact of script logging on 
startup time

