" tassert.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-21.
" @Last Change: 2009-02-21.
" @Revision:    0.0.96

let s:save_cpo = &cpo
set cpo&vim


" :nodoc:
function! tassert#Comment(line1, line2, bang) "{{{3
    let assertCP = getpos('.')
    let tassertSR = @/
    call s:CommentRegion(1, a:line1, a:line2)
    exec 'silent '. a:line1.','. a:line2 .'s/\C^\(\s*\)\(TAssert\)/\1" \2/ge'
    if !empty(a:bang)
        call tlog#Comment(a:line1, a:line2)
    endif
    let @/ = tassertSR
    call setpos('.', assertCP)
endf


" :nodoc:
function! tassert#Uncomment(line1, line2, bang) "{{{3
    let assertCP = getpos('.')
    let tassertSR = @/
    call s:CommentRegion(0, a:line1, a:line2)
    exec 'silent '. a:line1.','. a:line2 .'s/\C^\(\s*\)"\s*\(TAssert\)/\1\2/ge'
    if !empty(a:bang)
        call tlog#Uncomment(a:line1, a:line2)
    endif
    let @/ = tassertSR
    call setpos('.', assertCP)
endf


fun! s:CommentRegion(mode, line1, line2)
    exec a:line1
    let prefix = a:mode ? '^\s*' : '^\s*"\s*'
    let tb = search(prefix.'TAssertBegin\>', 'bc', a:line1)
    while tb
        let te = search(prefix.'TAssertEnd\>', 'W', a:line2)
        if te
            if a:mode
                silent exec tb.','.te.'s/^\s*/\0" /'
            else
                silent exec tb.','.te.'s/^\(\s*\)"\s*/\1/'
            endif
            let tb = search(prefix.'TAssertBegin\>', 'W', a:line2)
        else
            throw 'tAssert: Missing TAssertEnd below line '. tb
        endif
    endwh
endf


" :nodoc:
fun! tassert#__ResolveSIDs(string, ...)
    if stridx(a:string, '<SID>') != -1
        if a:0 >= 1
            let snr = a:1
        elseif s:assertFile != ''
            let snr = tassert#__GetSNR(s:assertFile)
        else
            let snr = 0
        endif
        if !empty(snr)
            let string = substitute(a:string, '<SID>', '<SNR>'.snr.'_', 'g')
            " TLogDBG a:string .': '. snr
            return string
            " else
            "     TLog 'tAssert: Unknown script context: '. a:string .' '. snr
        endif
    endif
    return a:string
endf


" :nodoc:
fun! tassert#__GetSNR(file, ...)
    let update = a:0 >= 1 ? a:1 : 0
    call tassert#__InitSNR(update)
    " echom "DBG ". string(s:scripts)
    let file = substitute(a:file, '[/\\]', '[\\\\/]', 'g')
    for fn in s:scripts
        if fn[1] =~ file.'$'
            return fn[0]
        endif
    endfor
    if !update
        return tassert#__GetSNR(a:file, 1)
    else
        " TLog 'tAssert: Unknown script file: '. a:file
        return 0
    endif
endf


" fun! s:GetScript(sid, ...)
"     let update = a:0 >= 1 ? a:1 : 0
"     call tassert#__InitSNR(update)
"     for fn in s:scripts
"         if fn[0] == a:sid
"             return fn[1]
"         endif
"     endfor
"     if !update
"         return s:GetScript(a:sid, 1)
"     else
"         TLog 'tAssert: Unknown SID: '. a:sid
"         return 0
"     endif
" endf


" :nodoc:
fun! tassert#__InitSNR(update)
    if a:update || !exists('s:scripts')
        redir => scriptnames
        silent! scriptnames
        redir END
        let s:scripts = split(scriptnames, "\n")
        call map(s:scripts, '[matchstr(v:val, ''^\s*\zs\d\+''), matchstr(v:val, ''^\s*\d\+: \zs.*$'')]')
    endif
endf


" :nodoc:
function! tassert#Begin(args, sfile, bang) "{{{3
    let s:tassert_args = tassert#__ParseArgs(a:args, a:sfile)
    if !empty(a:bang) && !exists('s:tassert_file')
        call tlog#Log('tAssert: '. s:assertMsg)
    endif
endf


" :nodoc:
function! tassert#End(args) "{{{3
    for v in a:args
        if v =~ '()$'
            exec 'delfunction '. matchstr(v, '^[^(]\+')
        else
            exec 'unlet! '. v
        endif
    endfor
    if exists('s:assertMsg') && !empty(s:assertMsg) && !exists('s:tassert_file')
        call tlog#Log('tAssert: '. s:assertMsg .' ... done')
    endif
    call tassert#__Reset()
endf


function! tassert#__Setup() "{{{3
    call should#__Init()
    if exists('s:tassert_file')
        let s:tassert_counts += 1
        exec get(s:tassert_args, 'setup', '')
    endif
endf


function! tassert#__Teardown() "{{{3
    if exists('s:tassert_file')
        exec get(s:tassert_args, 'teardown', '')
    endif
endf


function! tassert#AddQFL(expr, reason)
    let ncmd = 0
    let idx = 1
    let lnum = idx
    for line in s:tassert_files[s:tassert_file]
        if line =~ '^\s*TAssert!\?\s\+'
            if exists('g:loaded_tlib') && line =~ '^\s*TAssert!\?\s\+'. tlib#rx#Escape(a:expr) .'\s*$'
                let lnum = idx
                break
            endif
            let ncmd += 1
            if ncmd == s:tassert_counts
                let lnum = idx
                break
            endif
        endif
        let idx += 1
    endfor
    let qfl = [{
                \ 'filename': s:tassert_file,
                \ 'lnum': lnum,
                \ 'text': a:reason,
                \ }]
    call setqflist(qfl, 'a')
endf


function! tassert#__Run(path, file) "{{{3
    " TAssert should#be#String(a:path)
    " TAssert should#be#String(a:file)
    " TLogVAR a:path, a:file
    if empty(a:path)
        let files = [a:file]
    else
        let files = globpath('*.vim', a:path)
    endif
    " TLogVAR files
   
    cexpr []
    let s:tassert_files = {}
    for file in files
        TLogVAR file
        let s:tassert_counts = 0
        let s:tassert_file = s:CanonicalFilename(file)
        let s:tassert_files[s:tassert_file] = readfile(s:tassert_file)
        try
            exec 'source '. fnameescape(file)
        catch
            " echohl Error
            " echom v:exception
            " echohl NONE
        endtry
    endfor
    unlet! s:tassert_files s:tassert_file s:tassert_counts
    
    if len(getqflist()) > 0
        try
            exec g:tassert_cwindow
        catch
            echohl Error
            echom v:exception
            echohl NONE
        endtry
    endif
endf


function! s:CanonicalFilename(filename) "{{{3
    let filename = substitute(a:filename, '\\', '/', 'g')
    let filename = substitute(filename, '^.\ze:/', '\u&', '')
    return filename
endf


" :nodoc:
function! tassert#__ParseArgs(args, sfile) "{{{3
    let s:assertMsg = get(a:args, 'title', '')
    let s:assertFile = get(a:args, 'file', a:sfile)
    if !has_key(a:args, 'file')
        let a:args['file'] = s:assertFile
    endif
    return a:args
endf


" Evaluate an expression in the context of a script.
" Requires a call to |TAssertInit()|.
fun! tassert#Val(script, expr)
    if a:script =~ '^function <SNR>'
        let sid = matchstr(a:script, '<SNR>\zs\d\+\ze_')
    else
        let sid = tassert#__GetSNR(a:script)
    endif
    let fn = tassert#__ResolveSIDs('<SID>TAssertVal', sid)
    if empty(fn)
        echoerr 'tAssert: Uninitialized script: '. a:script
        return ''
    else
        return call(function(fn), [a:expr])
    endif
endf


" :nodoc:
function! tassert#__Reset() "{{{3
    let s:assertMsg = ''
    let s:assertFile = ''
endf

call tassert#__Reset()



let &cpo = s:save_cpo
unlet s:save_cpo
