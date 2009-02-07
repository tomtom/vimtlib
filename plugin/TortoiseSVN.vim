" TortoiseSVN.vim - Support for TortoiseSVN (a subversion client for Windows)
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=vim-TortoiseSVN)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     13-Mai-2005.
" @Last Change: 2007-08-27.
" @Revision:    0.4.216
" 
" http://www.vim.org/scripts/script.php?script_id=1284

if &cp || exists("loaded_tortoisesvn")
    finish
endif
let loaded_tortoisesvn = 3

if !exists('g:tortoiseSvnCmd')
    if &shell =~ 'sh'
        let g:tortoiseSvnCmd = '/cygdrive/c/Programme/TortoiseSVN/bin/TortoiseProc.exe'
    " elseif &shell =~ '\(cmd\|command|)'
    else
        let g:tortoiseSvnCmd = 'C:\Programme\TortoiseSVN\bin\TortoiseProc.exe'
    endif
    " let g:tortoiseSvnCmd = 'TortoiseProc.exe'
endif

if !exists('g:tortoiseSvnInstallAutoCmd')
    let g:tortoiseSvnInstallAutoCmd = 1
endif

if !exists('g:tortoiseSvnDebug')
    " let g:tortoiseSvnDebug = 1
    let g:tortoiseSvnDebug = 0
endif

if !exists('g:tortoiseSvnCommitOnce')
    let g:tortoiseSvnCommitOnce = 0
endif

if !exists('g:tortoiseSvnMenuPrefix')
    let g:tortoiseSvnMenuPrefix = 'Plugin.&TortoiseSVN.'
endif

if !exists('g:tortoiseSvnStartCmd')
    let g:tortoiseSvnStartCmd = &shell =~ 'sh' ? 'cygstart' : 'start'
endif

if !exists('g:tortoiseSvnExclude')
    let g:tortoiseSvnExclude = '\~$'
endif

let s:aFile = '<A FILE>'

fun! <SID>CanonicFileName(fname)
    if &shell =~ 'sh'
        return "'". substitute(a:fname, '[/\\]', '\\\\', 'g') ."'"
    else
        return substitute(a:fname, '[/\\]', '\\', 'g')
    endif
endf

" <SID>GetCmdLine(command, ?filename)
fun! <SID>GetCmdLine(command, ...)
    let fn  = (a:0 >= 1 && a:1 != s:aFile) ? fnamemodify(a:1, ':p') : expand('%:p')
    let excl = exists('b:tortoiseSvnExclude') ? b:tortoiseSvnExclude : g:tortoiseSvnExclude
    if fn == '' || (excl != '' && fn =~ excl)
        return ''
    endif
    let svn = expand('%:p:h') .'/.svn'
    if isdirectory(svn) && filereadable(fn) && !isdirectory(fn)
        let fn  = <SID>CanonicFileName(fn)
        let cmd = g:tortoiseSvnCmd ." /command:". a:command ." /path:". fn ." /notempfile /closeonend:2"
        return cmd
    else
        return ''
    endif
endf

fun! <SID>ExecCommand(cmd)
    if g:tortoiseSvnDebug
        exec '! '. a:cmd
    else
        silent exec '! '. g:tortoiseSvnStartCmd .' '. a:cmd
    endif
endf

" TortoiseExec(command, ?extra_arguments, ?filename)
fun! TortoiseExec(command, ...)
    " if a:command == 'commit'
    "     if !(exists('b:tortoiseSvnMaybeCommit') && b:tortoiseSvnMaybeCommit)
    "         return
    "     endif
    " endif
    let fname = a:0 >= 2 ? a:2 : s:aFile
    let cmd = <SID>GetCmdLine(a:command, fname)
    if cmd != ''
        if a:0 >= 1
            let extra = a:1
            let cmd   = cmd .' '. extra
        endif
        call <SID>ExecCommand(cmd)
    endif
    if a:command == 'commit'
        let b:tortoiseSvnMaybeCommit = 0
    endif
endf

" fun! TortoiseSvnLogMsg()
"     " return strftime("%Y-%b-%d") ."\\ ". expand('%') .': '
"     return expand('%') .':'
" endf

" TortoiseSvnMaybeCommitThisBuffer(?filename)
fun! TortoiseSvnMaybeCommitThisBuffer(...)
    if a:0 >= 1 && a:1 != s:aFile
        let fname = a:1
        let abfnr = bufnr(fname)
    else
        let fname = s:aFile
        let abfnr = -1
    endif
    let bfnr = bufnr('%')
    try
        if abfnr >= 0 && bfnr != abfnr
            exec 'buffer '. abfnr
        else
            let abfnr = -1
        endif
        if exists('b:tortoiseSvnCommittedOnce') || exists('b:tortoiseSvnIgnore')
            return
        endif
        if !(exists('b:tortoiseSvnMaybeCommit') && b:tortoiseSvnMaybeCommit)
            return
        endif
        let b:tortoiseSvnMaybeCommit = 0
        let extra = ''
        " " Adding a log message makes TortoiseSVN crash here on my computer
        if exists('*TortoiseSvnLogMsg')
            let msg   = substitute(TortoiseSvnLogMsg(), "[@'\"\\]", '_', 'g')
            let extra = extra ." /logmsg:'". msg. "'"
        endif
        call TortoiseExec('commit', extra, fname)
        if g:tortoiseSvnCommitOnce || 
                    \ (exists('b:tortoiseSvnCommitOnce') && b:tortoiseSvnCommitOnce)
            let b:tortoiseSvnCommittedOnce = 1
        endif
    finally
        if abfnr >= 0
            exec 'buffer '. bfnr
        endif
    endtry 
endf

fun! TortoiseSvnMaybeCommitBuffers()
    let cb = bufnr('%')
    let i  = 1
    let m  = bufnr('$')
    while i <= m
        if bufloaded(i) && buflisted(i)
            exec "buffer ". i
            if expand('%') != '' && exists('b:tortoiseSvnMaybeCommit') && b:tortoiseSvnMaybeCommit
                call TortoiseSvnMaybeCommitThisBuffer()
            endif
        endif
        let i = i + 1
    endwh
    exec "buffer ". cb
endf

command! TortoiseSvnRevisionGraph :call TortoiseExec('revisiongraph')
command! TortoiseSvnBrowser       :call TortoiseExec('repobrowser')
command! TortoiseSvnLog           :call TortoiseExec('log')
command! TortoiseSvnCheckout      :call TortoiseExec('checkout')
command! TortoiseSvnUpdate        :call TortoiseExec('update', '/rev')
" command! -nargs=? TortoiseSvnCommit :call TortoiseSvnMaybeCommitThisBuffer(<q-args>)
command! TortoiseSvnCommit        :call TortoiseExec('commit')

if g:tortoiseSvnMenuPrefix != ''
    exec 'amenu '. g:tortoiseSvnMenuPrefix .'&Browser         :TortoiseSvnBrowser<cr>'
    exec 'amenu '. g:tortoiseSvnMenuPrefix .'Check&out        :TortoiseSvnCheckout<cr>'
    exec 'amenu '. g:tortoiseSvnMenuPrefix .'&Commit          :call TortoiseExec("commit")<cr>'
    exec 'amenu '. g:tortoiseSvnMenuPrefix .'&Log             :TortoiseSvnLog<cr>'
    exec 'amenu '. g:tortoiseSvnMenuPrefix .'Revision\ &Graph :TortoiseSvnRevisionGraph<cr>'
    exec 'amenu '. g:tortoiseSvnMenuPrefix .'&Update          :TortoiseSvnUpdate<cr>'
endif

fun! TSkelMenuCachePostWriteHook()
    let b:tortoiseSvnMaybeCommit = 0
endf

if g:tortoiseSvnInstallAutoCmd
    autocmd BufWritePost * let b:tortoiseSvnMaybeCommit = 1
    if g:tortoiseSvnInstallAutoCmd == 1
        " autocmd BufDelete * exec "TortoiseSvnCommit ".expand('<afile>')
        autocmd BufDelete * call TortoiseSvnMaybeCommitThisBuffer(expand('<afile>'))
        autocmd VimLeavePre * call TortoiseSvnMaybeCommitBuffers()
    elseif g:tortoiseSvnInstallAutoCmd == 2
        " autocmd BufWritePost * TortoiseSvnCommit
        autocmd BufWritePost * call TortoiseSvnMaybeCommitThisBuffer()
    endif
    let g:tortoiseSvnInstallAutoCmd = 0
endif


finish

Version history:

0.1
- Initial release

0.2
- Make sure this works with cmd.exe as &shell too
- Make <SID>CanonicFileName(fname) &shell sensible
- Fixed a cut&paste error in the menu

0.3
- g:tortoiseSvnInstallAutoCmd: 0=disable autocmd; 1=commit on BufUnload; 2=commit on BufWritePost
- most function accept now the filename as optional argument
- fixed problem with some "fileless" buffers
- fixed problem when leaving vim

0.4
- g:tortoiseSvnExclude
- FIX: Problem with <c-w>o and :cclose etc.

