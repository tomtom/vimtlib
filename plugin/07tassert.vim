" tAssert.vim
" @Author:      Thomas Link (micathom AT gmail com?subject=vim-tAssert)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2006-12-12.
" @Last Change: 2009-02-08.
" @Revision:    0.4.625
"
" GetLatestVimScripts: 1730 1 07tAssert.vim
"
" TODO:
" - Interactive assertions (buffer input, expected vs observed)
" - Support for Autoloading, AsNeeded ...


" Prelude {{{1
if &cp || exists("loaded_tassert")
    if !(!exists("s:assert") || g:TASSERT != s:assert)
        finish
    endif
endif
let loaded_tassert = 4


" Core {{{1
if !exists('g:TASSERT')        | let g:TASSERT = 0                       | endif
if !exists('g:TASSERTLOG')     | let g:TASSERTLOG = 1                    | endif

if exists('s:assert')
    echo 'TAssertions are '. (g:TASSERT ? 'on' : 'off')
endif
let s:assert = g:TASSERT

let g:tassertEvaluators = {}

if g:TASSERT
    TLogOn

    function! s:Reset() "{{{3
        let s:assertMsg = ''
        let s:assertFile = ''
        let s:assertSetup = ''
        let s:assertTeardown = ''
    endf

    call s:Reset()

    command! -nargs=1 -bang TAssert 
                \ let s:assertReason = [] |
                \ exec s:assertSetup |
                \ try |
                \ let s:assertFailed = empty(eval(s:ResolveSIDs(<q-args>))) |
                \ catch |
                \ call insert(s:assertReason, v:exception) | 
                \ let s:assertFailed = 1 |
                \ endtry |
                \ exec s:assertTeardown |
                \ if s:assertFailed | 
                \ call insert(s:assertReason, <q-args>) | 
                \ call insert(s:assertReason, s:assertMsg) | 
                \ let s:assertReasonS = join(s:assertReason, ': ') |
                \ call s:InsertLocationList(expand("<sfile>:p"), <line1>, s:assertReasonS) | 
                \ if "<bang>" != '' | 
                \ call TLog(s:assertReasonS) | 
                \ else |
                \ throw s:assertReasonS | 
                \ endif | 
                \ endif
    command! -nargs=* -bang TAssertBegin let s:assertArgs = s:ParseArgs([<args>]) | 
                \ cexpr [] | 
                \ if "<bang>" != '' | call TLog('tAssert: '. s:assertMsg) | endif
    command! -nargs=* -bang TAssertEnd for v in split(<q-args>, '\s\+') | 
                \ if v =~ '()$' |
                \ exec 'delfunction '. matchstr(v, '^[^(]\+') |
                \ else |
                \ exec 'unlet! '. v | 
                \ endif | 
                \ endfor | 
                \ if exists('s:assertMsg') && !empty(s:assertMsg) | call TLog('tAssert: '. s:assertMsg .' ... done') | endif |
                \ call s:Reset()
    command! -nargs=1 -bang TAssertExec exec <q-args> TAssertEnd
else
    command! -nargs=* -bang TAssert :
    command! -nargs=* -bang TAssertBegin :
    command! -nargs=* -bang TAssertEnd :
    command! -nargs=1 -bang TAssertExec :
    if exists(':TAssertOn') | finish | endif
endif


" Convenience commands {{{1

command! -bar TAssertOn let g:TASSERT = 1 | runtime plugin/00tAssert.vim
command! -bar TAssertOff let g:TASSERT = 0 | runtime plugin/00tAssert.vim
command! -bar TAssertToggle let g:TASSERT = !g:TASSERT | runtime plugin/00tAssert.vim

command! -range=% -bar -bang TAssertComment let s:assertCP = getpos('.') | let s:tassertSR = @/ | 
            \ call s:CommentRegion(1, <line1>, <line2>) | 
            \ silent <line1>,<line2>s/\C^\(\s*\)\(TAssert\)/\1" \2/ge | 
            \ if !empty("<bang>") | <line1>,<line2>TLogComment | endif |
            \ let @/ = s:tassertSR | call setpos('.', s:assertCP)
command! -range=% -bar -bang TAssertUncomment let s:assertCP = getpos('.') | let s:tassertSR = @/ | 
            \ call s:CommentRegion(0, <line1>, <line2>) | 
            \ silent <line1>,<line2>s/\C^\(\s*\)"\s*\(TAssert\)/\1\2/ge | 
            \ if !empty("<bang>") | <line1>,<line2>TLogUncomment | endif |
            \ let @/ = s:tassertSR | call setpos('.', s:assertCP)

fun! TAssertInit()
    return "function! s:TAssertVal(expr)\nreturn eval(a:expr)\nendf"
endf

fun! TAssertVal(script, expr)
    if a:script =~ '^function <SNR>'
        let sid = matchstr(a:script, '<SNR>\zs\d\+\ze_')
    else
        let sid = s:GetSNR(a:script)
    endif
    let fn = s:ResolveSIDs('<SID>TAssertVal', sid)
    if empty(fn)
        echoerr 'tAssert: Uninitialized script: '. a:script
        return ''
    else
        return call(function(fn), [a:expr])
    endif
endf

function! s:ParseArgs(args) "{{{3
    let s:assertMsg = get(a:args, 0, '')
    let file = expand("<sfile>:p")
    let arg1 = get(a:args, 1, file)
    if type(arg1) == 4
        let s:assertFile  = get(arg1, 'file', file)
        let s:assertSetup = get(arg1, 'setup', '')
        let s:assertTeardown = get(arg1, 'teardown', '')
    else
        let s:assertFile = arg1
        let s:assertSetup = ''
        let s:assertTeardown = ''
    endif
endf

fun! s:InitSNR(update)
    if a:update || !exists('s:scripts')
        redir => scriptnames
        silent! scriptnames
        redir END
        let s:scripts = split(scriptnames, "\n")
        call map(s:scripts, '[matchstr(v:val, ''^\s*\zs\d\+''), matchstr(v:val, ''^\s*\d\+: \zs.*$'')]')
    endif
endf

fun! s:GetScript(sid, ...)
    let update = a:0 >= 1 ? a:1 : 0
    call s:InitSNR(update)
    for fn in s:scripts
        if fn[0] == a:sid
            return fn[1]
        endif
    endfor
    if !update
        return s:GetScript(a:sid, 1)
    else
        TLog 'tAssert: Unknown SID: '. a:sid
        return 0
    endif
endf

fun! s:GetSNR(file, ...)
    let update = a:0 >= 1 ? a:1 : 0
    call s:InitSNR(update)
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
        " TLog 'tAssert: Unknown script file: '. a:file
        return 0
    endif
endf

fun! s:ResolveSIDs(string, ...)
    if a:0 >= 1
        let snr = a:1
    elseif s:assertFile != ''
        let snr = s:GetSNR(s:assertFile)
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

fun! s:InsertLocationList(file, line, reason)
    " TLogVAR a:reason
    let bn = bufnr(a:file)
    if bn >= 0
        let qfl = getqflist()
        let src = {}
        let src.bufnr = bn
        let src.filename = a:file
        let src.lnum = a:line
        let src.text = a:reason
        call add(qfl, src)
        call setqflist(qfl)
    endif
endf

" Test functions
fun! s:Test(a)
    return a:a + a:a
endf


" Convenience functions {{{1
if exists('g:tAssertNoCFs') && g:tAssertNoCFs
    finish
endif

let s:types = ['number', 'string', 'funcref', 'list', 'dictionary']

fun! s:CheckMethod(dict, prototype, method)
    if a:method == 'data'
        return 1
    endif
    let m = a:prototype[a:method]
    if type(m) == 0 && !m
        return 1
    endif
    return has_key(a:dict, a:method)
endf

fun! s:Explain(rv, reason)
    if !a:rv || g:TASSERTLOG >= 2
        call add(s:assertReason, a:reason)
    endif
endf

fun! s:CheckType(expr, type)
    let Val  = a:expr
    if type(a:type) == 3
        for t in a:type
            let rv = s:CheckType(Val, t)
            if rv
                return rv
            endif
        endfor
    elseif type(a:type) == 1
        let t = index(s:types, tolower(a:type))
        if t == -1
            throw 'Unknown type: '. string(a:type)
        else
            return s:CheckType(Val, t)
        endif
    elseif type(a:type) == 4
        let type = type(Val)
        if type == 4
            let rv = !len(filter(keys(a:type), '!s:CheckMethod(Val, a:type, v:val)'))
        endif
    else
        let type = type(Val)
        let rv   = type == a:type
    endif
    if !rv
        call s:Explain(rv, string(Val) .' is a '. s:types[type])
    endif
    return rv
endf

fun! IsA(expr, type)
    return s:CheckType(a:expr, a:type)
endf

fun! IsNumber(expr)
    return s:CheckType(a:expr, 0)
endf

fun! IsString(expr)
    return s:CheckType(a:expr, 1)
endf

fun! IsFuncref(expr)
    return s:CheckType(a:expr, 2)
endf

fun! IsList(expr)
    return s:CheckType(a:expr, 3)
endf

fun! IsDictionary(expr)
    return s:CheckType(a:expr, 4)
endf

fun! IsException(expr)
    try
        call eval(a:expr)
        return ''
    catch
        return v:exception
    endtry
endf

fun! IsError(expr, expected)
    let rv = IsException(a:expr)
    if rv =~ a:expected
        return 1
    else
        call s:Explain(0, 'Exception '. string(a:expected) .' expected but got '. string(rv))
        return 0
    endif
endf

fun! IsEqual(expr, expected)
    " let val = eval(a:expr)
    let val = a:expr
    let rv  = val == a:expected
    if !rv
        call s:Explain(rv, 'Expected '. string(a:expected) .' but got '. string(val))
    endif
    return rv
endf

fun! IsNotEqual(expr, expected)
    let val = eval(a:expr)
    let rv  = val != a:expected
    if !rv
        call s:Explain(rv, string(a:expected) .' is equal to '. string(val))
    endif
    return rv
endf

fun! IsEmpty(expr)
    let rv = empty(a:expr)
    if !rv
        call s:Explain(rv, string(a:expr) .' isn''t empty')
    endif
    return rv
endf

fun! IsNotEmpty(expr)
    let rv = !empty(a:expr)
    if !rv
        call s:Explain(rv, string(a:expr) .' is empty')
    endif
    return rv
endf

fun! IsMatch(expr, expected)
    let val = a:expr
    let rv  = val =~ a:expected
    if !rv
        call s:Explain(rv, string(val) .' doesn''t match '. string(a:expected))
    endif
    return rv
endf

fun! IsNotMatch(expr, expected)
    let val = a:expr
    let rv  = val !~ a:expected
    if !rv
        call s:Explain(rv, add(s:assertReason, string(val) .' matches '. string(a:expected))
    endif
    return rv
endf

fun! IsExistent(expr)
    let val = a:expr
    let rv = exists(val)
    if !rv
        call s:Explain(rv, add(s:assertReason, string(val) .' doesn''t exist')
    endif
    return rv
endf


finish
CHANGE LOG {{{1

0.1: Initial release

0.2
- More convenience functions
- The convenience functions now display an explanation for a failure
- Convenience commands weren't loaded when g:TASSERT was off.
- Logging to a file & via Decho()
- TAssert! (the one with the bang) doesn't throw an error but simply 
displays the failure in the log
- s:ResolveSIDs() didn't return a string if s:assertFile wasn't set.
- s:ResolveSIDs() caches scriptnames
- Moved logging code to 00tLog.vim

0.3
- IsA(): Can take a list of types as arguments and it provides a way to 
check dictionaries against prototypes or interface definitions.
- IsExistent()
- New log-related commands: TLogOn, TLogOff, TLogBufferOn, TLogBufferOff
- Use TAssertVal(script, expr) to evaluate an expression (as 
argument to a command) in the script context.
- TAssertOn implies TLogOn
- *Comment & *Uncomment commands now take a range as argument (default: 
whole file).
- TAssertComment! & TAssertUncomment! (with [!]) also call 
TLog(Un)Comment.

0.4
- TLogVAR: take a comma-separated variable list as argument; display a 
time-stamp (if +reltime); show only the g:tlogBacktrace'th last items of 
the backtrace.


Doesn't work yet: Line number?
- Integration with the quickfix list.

