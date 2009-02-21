" tassert.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-21.
" @Last Change: 2009-02-21.
" @Revision:    0.0.35

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
    call tassert#__ParseArgs(a:args, a:sfile)
    cexpr []
    if !empty(a:bang)
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
    if exists('s:assertMsg') && !empty(s:assertMsg)
        call tlog#Log('tAssert: '. s:assertMsg .' ... done')
    endif
    call tassert#__Reset()
endf


" :nodoc:
function! tassert#__ParseArgs(args, sfile) "{{{3
    let s:assertMsg = get(a:args, 0, '')
    let arg1 = get(a:args, 1, a:sfile)
    if type(arg1) == 4
        let s:assertFile  = get(arg1, 'file', a:sfile)
    else
        let s:assertFile = arg1
    endif
    return {'file': s:assertFile}
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
