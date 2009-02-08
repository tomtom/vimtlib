" tbak.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=vim-tbak)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-07.
" @Last Change: 2007-08-27.
" @Revision:    215

if &cp || exists('loaded_tbak_autoload') "{{{2
    finish
endif
let loaded_tbak_autoload = 1

fun! s:MkDir(dir) "{{{3
    if !isdirectory(a:dir)
        call mkdir(a:dir, 'p')
    endif
endf

fun! s:Latest(filename) "{{{3
    return a:filename .'-latest.'. fnamemodify(a:filename, ':e')
endf

fun! s:ExecEscape(cmd) "{{{3
    return escape(a:cmd, '%#\ ')
endf

fun! s:MkBackup(filename, dest) "{{{3
    " silent exec "write! ". escape(s:Latest(a:dest), '%#"\')
    silent exec "write! ". s:ExecEscape(s:Latest(a:dest))
    " echom 'TBak: Wrote '. a:filename
    echom 'TBak: Wrote '. a:dest
endf

fun! s:MkDiff(filename, dir) "{{{3
    let fname = s:Latest(a:filename)
    let orig  = a:filename .'.orig'
    let diff  = a:filename .'-'. strftime('%y%m%d%S') .'.diff'
    let text  = getline('0', '$')
    let dorig = a:dir .'/'. orig
    call writefile(text, dorig)
    let efname = escape(fname, '%#"\') .'-
    let eorig  = escape(orig, '%#"\')
    let ediff  = escape(diff, '%#"\')
    let cd = getcwd()
    exec 'lcd '. escape(a:dir, '%#"\')
    try
        let isdiff = system(printf(g:tbakCheck, orig, fname))
        if isdiff != ''
            " TLogDBG '!'. printf(g:tbakDiff, eorig, efname, ediff)
            silent exec '!'. printf(g:tbakDiff, eorig, efname, ediff)
            " call delete(fname)
            call rename(orig, fname)
            echom 'TBak: Diff '. a:filename
        else
            call delete(orig)
        endif
    finally
        exec 'lcd '. s:ExecEscape(cd)
    endtry
endf

fun! s:CanonicDirName(dir) "{{{3
    if a:dir[-1:-1] != '/'
        return a:dir . '/'
    else
        return a:dir
    end
endf

fun! s:UseGlobal(global) "{{{3
    " TLogVAR a:global
    if type(a:global) == 1 && a:global == '!'
        let global = 1
    elseif type(a:global) == 0 && a:global == 1
        let global = 1
    else
        let global = tlib#var#Get('tbakGlobal', 'bg', 0)
    endif
    " TLogVAR global
    return global
endf

fun! s:BackupDir(global, ...) "{{{3
    let global = s:UseGlobal(a:global)
    " TLogVAR global
    let datef  = tlib#var#Get('tbakDateFormat', 'bg')
    let date   = a:0 >= 1 ? a:1 : strftime(datef)
    " TLogVAR date
    if global
        let dir = fnamemodify(tlib#var#Get('tbakGlobalDir', 'bg'), ':p')
        " TLogVAR dir
        let ddir  = substitute(expand("%:p:h"), '[:%]', '\=printf("%%%x", char2nr(submatch(0)))', 'g')
        let ddir  = simplify(s:CanonicDirName(dir) . g:tbakAttic .'/'. date .'/'. ddir)
    else
        let dir = fnamemodify(tlib#var#Get('tbakDir', 'bg', expand("%:p:h")), ':p')
        " TLogVAR dir
        let ddir = simplify(s:CanonicDirName(dir) . g:tbakAttic .'/'. date)
    endif
    " TLogVAR ddir
    return ddir
endf

fun! s:CollectDiffs(global, pattern) "{{{3
    let dir     = s:BackupDir(a:global, '*')
    " TLogVAR dir
    let pattern = empty(a:pattern) ? expand('%:t').'*' : a:pattern
    " TLogVAR pattern
    let diffs   = split(glob(dir .'/**/'. pattern), '\n')
    " TLogVAR diffs
    call filter(diffs, '!isdirectory(v:val)')
    call reverse(diffs)
    return diffs
endf

fun! s:SelectVersion(global) "{{{3
    " let dir   = s:BackupDir(a:global, '*')
    let diffs = s:CollectDiffs(a:global, '')
    " TLogVAR diffs
    let vers = tlib#input#List('si', 'Select version', 
                \ map(copy(diffs), 'v:val ." -- ". strftime("%c", getftime(v:val))'),
                \ [{'pick_last_item': 0}])
    " let vers = inputlist(['Select version'] + 
    "             \ map(range(0, len(diffs) - 1), '(v:val + 1) .": ". diffs[v:val] ." -- ". strftime("%c", getftime(diffs[v:val]))'))
    " TLogVAR vers
    return [vers - 1, diffs]
endf

fun! s:LatestFullBackup(diffs, maxversion) "{{{3
    let i = 0
    for file in a:diffs
        if file =~ '-latest.\w\+$'
            return i
        endif
        if i > a:maxversion
            return -1
        endif
        let i += 1
    endfor
    return -1
endf

fun! s:TBakBuffer(cmd) "{{{3
    if exists('s:tbakBuffer')
        exec a:cmd .' '. s:tbakBuffer
    else
        exec a:cmd .' __tbak_view__'
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        setlocal nobuflisted
    endif
endf

fun! s:RevertFile(file) "{{{3
    call s:TBakBuffer('buffer')
    norm! ggdG
    exec '0read '. s:ExecEscape(a:file)
    norm! Gdd
endf

fun! s:RevertDiff(file) "{{{3
    silent exec 'diffpatch '. s:ExecEscape(a:file)
    let text = getline('0', '$')
    bdelete!
    call s:TBakBuffer('buffer')
    norm! ggdG
    call append(0, text)
    norm! Gdd
    norm! gg0
endf

fun! s:Revert(global, vers, diffs) "{{{3
    let diff = a:diffs[a:vers]
    " TLogDBG "vers=". a:vers
    " TLogDBG "diff=". diff
    if diff =~ '-latest.\w\+$'
        call s:RevertFile(diff)
    else
        let diffs = a:diffs[0:a:vers]
        let lfull = s:LatestFullBackup(diffs, a:vers)
        " TLogDBG "lfull=". lfull
        if lfull != -1
            " TLogDBG "diffs[lfull]=". diffs[lfull]
            call s:RevertFile(diffs[lfull])
        endif
        let ndiff = lfull == -1 ? 0 : (lfull + 1)
        " TLogDBG "ndiff=". ndiff
        if ndiff >= 0
            for diff in diffs[ndiff : a:vers]
                " TLogDBG "diffs[ndiff]=". diff
                call s:RevertDiff(diff)
            endfor
        endif
    endif
endf

fun! s:GetVersionDiffs(vers, global) "{{{3
    if empty(a:vers)
        return s:SelectVersion(a:global)
    else
        return [a:vers, s:CollectDiffs(a:global, '')]
    endif
endf

fun! s:Cleanup(maxversion, global, name, diffs) "{{{3
    let diffs = filter(copy(a:diffs), 'v:val =~ ''\V''. escape(a:name, ''\'') .''\(-latest.\w\+\|-\d\+\.diff\)$''')
    for fname in diffs[a:maxversion:-1]
        echom "DBG call delete(". fname .")"
        " call delete(fname)
    endfor
endf

fun! tbak#TBak(...) "{{{3
    if &modified
        if g:tbakAutoUpdate
            update
        " else
        "     echoerr 'TBak: Buffer was modified'
        endif
    endif
    let fname = expand("%:p:t")
    let ddir  = s:BackupDir(a:0 >= 1 ? a:1 : '')
    let dest  = ddir .'/'. fname
    if filereadable(dest)
        call s:MkDiff(fname, ddir)
    else
        call s:MkDir(ddir)
        call s:MkBackup(fname, dest)
    endif
endf

fun! tbak#TBakRevert(vers, global) "{{{3
    let bang = a:0 >= 1 ? a:1 : ''
    call tbak#TBak(bang)
    let global = s:UseGlobal(bang)
    let [vers, diffs] = s:GetVersionDiffs(a:vers, global)
    if vers >= 0
        let s:tbakBuffer = bufnr('%')
        try
            call s:Revert(global, vers, diffs)
        finally
            unlet s:tbakBuffer
        endtry
    endif
endf

fun! tbak#TBakCleanup(maxversion, ...) "{{{3
    let maxversion = !empty(a:maxversion) ? a:maxversion : 
                \ (exists('b:tbakMaxVersions') b:tbakMaxVersions : g:tbakMaxVersions)
    let bang   = a:0 >= 1 ? a:1 : ''
    let global = s:UseGlobal(bang)
    let diffs  = s:CollectDiffs(global, '*')
    let latest = filter(copy(diffs), 'v:val =~ ''-latest.\w\+$''')
    for name in latest
        let basename = matchstr(name, '^.\{-}\ze-latest.\w\+$')
        call s:Cleanup(maxversion, global, basename, diffs)
    endfor
endf

fun! tbak#TBakView(vers, ...) "{{{3
    let bang = a:0 >= 1 ? a:1 : ''
    let global = s:UseGlobal(bang)
    " TLogVAR global
    let [vers, diffs] = s:GetVersionDiffs(a:vers, global)
    if vers >= 0
        let fname = expand('%:p')
        let text  = getline('0', '$')
        call s:TBakBuffer('split')
        norm! ggdG
        call append(0, text)
        norm! Gdd
        call s:Revert(global, vers, diffs)
        norm! gg0
        exec 'vert diffsplit '. s:ExecEscape(fname)
    endif
endf

