" glark.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim-glark)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     25-Jän-2006.
" @Last Change: 2009-02-15.
" @Revision:    0.3.305

if &cp || exists("loaded_glark") "{{{2
    finish
endif
let loaded_glark = 1

if !exists('g:glarkCommand')  | let g:glarkCommand = 'glark'    | endif "{{{2
if !exists('g:glarkArgs')     | let g:glarkArgs = '-q -n -H -U --explain' | endif "{{{2
if !exists('g:glarkUserArgs') | let g:glarkUserArgs = ''        | endif "{{{2
if !exists('g:glarkHeight')   | let g:glarkHeight = 0           | endif "{{{2
if !exists('g:glarkMultiWin') | let g:glarkMultiWin = 0         | endif "{{{2

function! s:GetLineNumber() "{{{3
    let li = getline('.')
    let ln = matchstr(li, '^\s\+\zs\d\+')
    if ln == ''
        let ln = 1
    end
    return ln
endf

function! s:GetColShift() "{{{3
    let li = getline('.')
    let ln = matchend(li, '^\s\+\d\+ \([:+-] \)\?')
    if ln < 0
        return 1
    elseif ln < col('.')
        return col('.') - ln
    else
        return 1
    endif
endf

function! s:Retrieve(field, default) "{{{3
    if exists('b:glark_'. a:field)
        return b:glark_{a:field}
    endif
    let pos = getpos('.')
    try
        let fld = '* '. a:field .': '
        let li = search('\V\^'. fld)
        if li
            let b:glark_{a:field} = strpart(getline(li), strlen(fld))
            return b:glark_{a:field}
        else
            return a:default
        endif
    finally
        call setpos('.', pos)
    endtry
endf

function! s:Pwd() "{{{3
    return s:Retrieve('PWD', expand('%:p:h'))
endf

function! s:GetFilename() "{{{3
    let min = exists('b:glarkBodyStart') ? b:glarkBodyStart : 1
    if line('.') < min
        return
    endif
    let pos = getpos('.')
    try
        if line('.') == min 
            let li = getline('.')
            if li =~ '^\S'
                return simplify(s:Pwd() .'/'. li)
            endif
        else
            let ln = search('^\S', 'bW')
            if ln
                return simplify(s:Pwd() .'/'. getline(ln))
            endif
        endif
        echoerr 'Malformed output: No filename (make sure you have glark >= 1.7.5)'
        return ''
    finally
        call setpos('.', pos)
    endtry
endf

function! s:Var(var) "{{{3
    return exists('b:'. a:var) ? b:{a:var} : g:{a:var}
endf

function! s:GetGlarkWin(args) "{{{3
    if g:glarkMultiWin
        let wname = '__Glark-'. substitute(a:args, '[^[:alnum]]', '_', 'g') .'__'
    else
        let wname = '__Glark__'
    endif
    let wn = bufwinnr(wname)
    if wn == -1
        split
        exec 'silent edit '. s:CmdFname(wname)
        set filetype=glark
    else
        exec wn .'wincmd w'
    endif
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal buflisted
    setlocal winfixheight
    return bufnr('%')
endf

function! s:CmdFname(fname) "{{{3
    " return escape(a:fname, ' \%#')
    return escape(a:fname, ' %#')
endf

function! s:WinHeight() "{{{3
    let ll = line('$')
    if winheight(0) > ll && (ll < g:glarkHeight || g:glarkHeight == 0)
        return ll
    elseif g:glarkHeight != 0
        return g:glarkHeight
    else
        return (&lines / 2)
    endif
endf

function! s:Run(args)
    setlocal modifiable
    let cmd = s:Var('glarkCommand') .' '. 
                \ s:Var('glarkUserArgs') .' '.
                \ s:Var('glarkArgs') .' '. escape(a:args, '\#%')
    silent exec '%!'. escape(cmd, '!')
    let output = getline(2, '$')
    " TLogVAR output
    if empty(output)
        wincmd c
    else
        call append(0, '* QUERY:')
        call append(0, '* ARG: '. a:args)
        call append(0, '* PWD: '. b:glark_PWD)
        setlocal nomodifiable
        if winnr('$') > 1
            let lines = s:WinHeight()
            " TLogVAR lines
            exec 'resize '. lines
        endif
        call GlarkParseExplain(a:args)
        keepjumps norm! m'1zt''
    endif
endf

function! GlarkUpdate() "{{{3
    if &ft != 'glark'
        echoerr 'Not a glark buffer'
    else
        let args = s:Retrieve('ARG', '')
        if arg != ''
            call s:Run(args)
        endif
    endif
endf

function! GlarkParseExplain(...) "{{{3
    let i = search('^\* QUERY:$')
    if i == 0
        let i = 1
    endif
    let h = 3
    let args = ''
    while h != 0
        let i  = i + 1
        let li = getline(i)
        if h != 1
            let m = matchstr(li, '^'. (h == 2 ? '[[:blank]]\+' : '') .'/\zs[^/]\+\ze/\w*')
            if m != ''
                if args == ''
                    let args = escape(m, '\')
                else
                    let args = args .'\|'. escape(m, '\')
                endif
                if h == 3
                    let i = i + 1
                    break
                else
                    let h = 1
                endif
            endif
        endif
        if li =~ '^[[:blank]]*\(any of:\|or\|within \d\+ lines\? of each other:\)$'
            let h = 2
        else
            break
        endif
    endwh
    if hlID('GlarkMatch')
        silent syntax clear GlarkMatch
    endif
    if args == '' && a:0 >= 1 && a:1 != ''
        let args = substitute(a:1, '\(\S\+\|\\ \)\+\s*$', '', 'g')
        let args = escape(args, '/\')
        let args = substitute(args, '\s\+', '\\|', 'g')
        let args = substitute(args, '\\|$', '', '')
    endif
    if args != ''
        " echom 'syntax match GlarkMatch /\V\c'. escape(args, '/') .'/'
        exec 'syntax match GlarkMatch /\V\c'. escape(args, '/') .'/'
        let @/ = '\V\c'. args
    endif
    let b:glarkBodyStart = i
endf

function! GlarkJump(flags) "{{{3
    if exists('b:glarkBodyStart') && line('.') < b:glarkBodyStart
        return
    endif
    let ln = s:GetLineNumber()
    if ln != ''
        let co = s:GetColShift()
        if co > 0
            let fn = s:GetFilename()
            if fn != ''
                let fwn = bufwinnr(fn)
                let fn  = s:CmdFname(fn)
                if a:flags == 'p'
                    exec 'pedit +'. ln .' '. fn
                    if &ft != 'glark'
                        set ft=glark
                    endif
                else
                    if a:flags == 'r'
                        exec 'edit '. fn
                    elseif a:flags == 'f'
                        exec 'edit '. fn
                        wincmd o
                    else
                        if fwn != -1
                            exec fwn .'wincmd w'
                        else
                            let wn = winnr()
                            wincmd W
                            if winnr() == wn
                                split
                            endif
                            exec 'edit '. fn
                        endif
                    endif
                    exec 'norm! '. ln .'G'. co .'|'
                endif
                return
            endif
        endif
    endif
endf

function! GlarkRun(args) "{{{3
    let bn = s:GetGlarkWin(a:args)
    let b:glark_PWD = expand("%:p:h")
    call s:Run(a:args)
endf

command! -nargs=* -complete=file Glark call GlarkRun(<q-args>)


finish
Change Log:

0.1
- initial release

0.2
- File completion for the :Glark command
- Support folds
- Use --explain option to construct @/ pattern
- Bind double click to open file
- GlarkUpdate() (bound to 'u')
- GlarkKeys() is called from ftplugin -> glark is behaves like a proper 
filetype now
- If g:glarkHeight is 0, the window is set to &lines/2 at runtime.
- Unset wrap before jumping to a line in the document

0.3
- Escape ! when running the glark command

