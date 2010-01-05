" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-04.
" @Last Change: 2010-01-04.
" @Revision:    5
" GetLatestVimScripts: 0 0 startup_profile.vim

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:startup_profile_csv')
    " The filename of the CSV file.
    let g:startup_profile_csv = split(&rtp, ',')[0] .'/vim_startup_log.csv' "{{{2
endif

let s:size = 0
let s:lines = 0
let s:time = reltimestr(reltime())
let s:time0 = s:time
let s:output = ['No;Filename;Lines;Bytes;Time;TimeDiff']

function! s:LogScript(filename) "{{{3
    let time = reltimestr(reltime())
    let timediff = string(str2float(time) - str2float(s:time))
    if len(s:output) > 1
        let s:output[-1] .= timediff
    endif
    let item = len(s:output) .';'. a:filename
    if filereadable(a:filename)
        let lines = len(readfile(a:filename))
        let s:lines += lines
        let size = getfsize(a:filename)
        let s:size += size
        let item .= ';'. lines .';'. size .';'. time .';'
    else
        let item .= ' (not readable);;;'. time .';'
    endif
    let s:time = time
    call add(s:output, item)
endf

function! s:LogEnd() "{{{3
    let time = reltimestr(reltime())
    let timediff = string(str2float(time) - str2float(s:time))
    let s:output[-1] .= timediff
    let timediff0 = string(str2float(time) - str2float(s:time0))
    call add(s:output, ';Total size;'. s:lines .';'. s:size .';'. time .';'. timediff0)
    call writefile(s:output, g:startup_profile_csv)
    autocmd! StartupLog
    unlet s:size s:lines s:output
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

