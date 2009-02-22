" spec.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2009-02-22.
" @Revision:    0.0.104

let s:save_cpo = &cpo
set cpo&vim


exec SpecInit()


let s:rewrite_should = '\(be\|throw\|yield\|finish\)'
let s:rewrite_table = [
            \ ['^\s*not\s\+', '!'],
            \ ['^!\?\zs'. s:rewrite_should .'#', 'should#&'],
            \ ]
            " \ ['^!\?'. s:rewrite_should .'\zs\s\+', '#'],
            " \ '^!\?\(be\|throw\|yield\)\zs\s\+\(.\)': '#\u\1',


" :nodoc:
function! spec#__Rewrite(string) "{{{3
    let string = a:string
    for [rx, subst] in s:rewrite_table
        " TLogVAR rx, subst
        let string = substitute(string, rx, subst, 'g')
        " TLogVAR string
    endfor
    let string = s:ResolveSIDs(string)
    return string
endf


" :nodoc:
fun! s:ResolveSIDs(string, ...)
    if stridx(a:string, '<SID>') != -1
        if a:0 >= 1
            let snr = a:1
        elseif s:spec_context != ''
            let snr = s:GetSNR(s:spec_context)
        else
            let snr = 0
        endif
        if !empty(snr)
            let string = substitute(a:string, '<SID>', '<SNR>'.snr.'_', 'g')
            " TLogDBG a:string .': '. snr
            return string
            " else
            "     TLog 'spec: Unknown script context: '. a:string .' '. snr
        endif
    endif
    return a:string
endf


" :nodoc:
fun! s:GetSNR(file, ...)
    let update = a:0 >= 1 ? a:1 : 0
    call spec#__InitSNR(update)
    " echom "DBG ". string(s:scripts)
    let file = substitute(a:file, '[/\\]', '[\\\\/]', 'g')
    for fn in s:scripts
        if fn[1] =~ file.'$'
            return fn[0]
        endif
    endfor
    if !update
        return s:GetSNR(a:file, 1)
    else
        " TLog 'spec: Unknown script file: '. a:file
        return 0
    endif
endf


" fun! s:GetScript(sid, ...)
"     let update = a:0 >= 1 ? a:1 : 0
"     call spec#__InitSNR(update)
"     for fn in s:scripts
"         if fn[0] == a:sid
"             return fn[1]
"         endif
"     endfor
"     if !update
"         return s:GetScript(a:sid, 1)
"     else
"         TLog 'spec: Unknown SID: '. a:sid
"         return 0
"     endif
" endf


" :nodoc:
fun! spec#__InitSNR(update)
    if a:update || !exists('s:scripts')
        redir => scriptnames
        silent! scriptnames
        redir END
        let s:scripts = split(scriptnames, "\n")
        call map(s:scripts, '[matchstr(v:val, ''^\s*\zs\d\+''), matchstr(v:val, ''^\s*\d\+: \zs.*$'')]')
    endif
endf


" :nodoc:
function! spec#__Begin(args, sfile) "{{{3
    let s:spec_args = s:ParseArgs(a:args, a:sfile)
    let s:spec_vars = keys(g:)
    let s:spec_comment = ''
endf


" :nodoc:
function! spec#__End(args) "{{{3
    for v in a:args
        if v =~ '()$'
            exec 'delfunction '. matchstr(v, '^[^(]\+')
        else
            exec 'unlet! '. v
        endif
    endfor

    let vars = keys(g:)
    call filter(vars, 'index(s:spec_vars, v:val) == -1')
    " TLogVAR vars
    call map(vars, '"g:". v:val')
    " TLogVAR vars
    if !empty(vars)
        exec 'unlet! '. join(vars, ' ')
    endif
endf


function! spec#__Setup() "{{{3
    call should#__Init()
    let s:should_counts += 1
    exec get(s:spec_args, 'setup', '')
endf


function! spec#__Teardown() "{{{3
    exec get(s:spec_args, 'teardown', '')
    " let s:spec_comment = ''
endf


function! spec#__AddQFL(expr, reason)
    " TLogVAR a:expr, a:reason
    let ncmd = 0
    let idx = 1
    let lnum = idx
    " call tlog#Debug(string(keys(s:spec_files)))
    for line in s:spec_files[s:spec_file]
        if line =~# '^\s*Should\s\+'
            " if exists('g:loaded_tlib') && line =~ '^\s*spec!\?\s\+'. tlib#rx#Escape(a:expr) .'\s*$'
            "     let lnum = idx
            "     break
            " endif
            let ncmd += 1
            if ncmd == s:should_counts
                let lnum = idx
                break
            endif
        endif
        let idx += 1
    endfor
    let qfl = [{
                \ 'filename': s:spec_file,
                \ 'lnum': lnum,
                \ 'text': a:reason,
                \ }]
    if !empty(s:spec_comment)
        call insert(qfl, {
                    \ 'filename': s:spec_file,
                    \ 'lnum': lnum,
                    \ 'text': s:spec_comment,
                    \ })
    endif
    call setqflist(qfl, 'a')
endf


function! spec#__Comment(string) "{{{3
    let s:spec_comment = a:string
endf


function! spec#__Run(path, file, bang) "{{{3
    " TLogVAR a:path, a:file
    if empty(a:path)
        let files = [a:file]
    elseif filereadable(a:path)
        let files = [a:path]
    else
        let files = globpath('**.vim', a:path)
    endif
    " TLogVAR files
   
    cexpr []
    let s:spec_files = {}
    for file in files
        " TLogVAR file
        let s:should_counts = 0
        let s:spec_file = s:CanonicalFilename(file)
        let s:spec_files[s:spec_file] = readfile(s:spec_file)
        let source = 'source '. fnameescape(file)
        try
            exec source
        catch
            call spec#__AddQFL(source, v:exception)
        endtry
        " TLogVAR len(getqflist())
    endfor
    unlet! s:spec_files s:spec_file s:should_counts
   
    echo " "
    redraw
    if len(getqflist()) > 0
        try
            exec g:spec_cwindow
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
function! s:ParseArgs(args, sfile) "{{{3
    let s:spec_msg = get(a:args, 'title', '')
    let s:spec_context = get(a:args, 'sfile', a:sfile)
    if !has_key(a:args, 'sfile')
        let a:args['sfile'] = s:spec_context
    endif
    return a:args
endf


" Evaluate an expression in the context of a script.
" Requires a call to |specInit()|.
fun! spec#Val(expr)
    let fn = s:ResolveSIDs('<SID>SpecVal')
    if empty(fn)
        echoerr 'Spec: Uninitialized script: '. a:script
        return ''
    else
        return call(function(fn), [a:expr])
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
