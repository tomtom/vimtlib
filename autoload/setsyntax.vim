" setsyntax.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-11-18.
" @Last Change: 2008-07-08.
" @Revision:    0.0.149

if &cp || exists("loaded_setsyntax_autoload")
    finish
endif
let loaded_setsyntax_autoload = 1
let s:save_cpo = &cpo
set cpo&vim


function! s:InitializeBuffer() "{{{3
    if !exists('b:setsyntax_options')
        let b:setsyntax_options = {}
        call hookcursormoved#Register("syntaxchange", "setsyntax#Set")
    endif
endf


function! setsyntax#Initialize() "{{{3
    let ft_opts = get(g:setsyntax_options, &filetype, {})
    if !empty(ft_opts)
        " TLogVAR &filetype
        call s:InitializeBuffer()
        for [rx, opts] in items(ft_opts)
            for syn in tlib#syntax#Names(rx)
                let b:setsyntax_options[syn] = opts
            endfor
        endfor
    endif
endf


" :def: function! setsyntax#SetSyntax(syntax_names, VAR1, VALUE1, ...)
" syntax_names is either a comma-separated list or a slash-enclosed 
" REGEXP.
function! setsyntax#SetSyntax(syntax_names, ...) "{{{3
    let opts = {}
    let opt  = ''
    for i in range(1, a:0)
        if empty(opt)
            let ml = matchlist(a:{i}, '^\([[:alnum:]:&]\+\)=\(.*\)$')
            if !empty(ml)
                let opts[ml[1]] = ml[2]
                continue
            endif
        endif
        if i % 2 == 0
            let val = a:{i}
            let opts[opt] = val
        else
            let opt = a:{i}
        endif
    endfor
    let rx = matchstr(a:syntax_names, '^/\zs.\{-}\ze/$')
    " TLogVAR rx
    if !empty(rx)
        let names = tlib#syntax#Names(rx)
    else
        let names = split(a:syntax_names, ',')
    endif
    if !empty(names)
        call s:InitializeBuffer()
        for name in names
            " TLogVAR name
            if !has_key(b:setsyntax_options, name)
                let b:setsyntax_options[name] = opts
            else
                call extend(b:setsyntax_options[name], opts)
            endif
        endfor
    endif
endf


" :def: function! setsyntax#Set(mode, ?condition_name=b:hookcursormoved_syntax)
function! setsyntax#Set(mode, ...) "{{{3
    let condition_name = a:0 >= 1 ? a:1 : b:hookcursormoved_syntax
    " TLogVAR a:mode, condition_name
    if exists('b:setsyntax')
        " TLogDBG 1
        for [var, val] in items(b:setsyntax)
            " TLogVAR var, val
            if var == '-'
                for unset_value in val
                    exec unset_value
                    unlet unset_value
                endfor
            else
                call s:Set(var, val)
            endif
            " TLogDBG 2
            unlet var val
        endfor
        " TLogDBG 'unset'
    endif
    let b:setsyntax = {}
    if !empty(condition_name)
        let opts = get(b:setsyntax_options, condition_name, {})
        " TLogDBG 3
        if !empty(opts)
            " TLogVAR opts
            for [var, val] in items(opts)
                " TLogDBG "4"
                " TLogVAR var, val
                if var == '-'
                elseif var == '+'
                    " TLogDBG "4.0"
                    let unset_value = get(opts, '-', '')
                    " TLogDBG "4.1"
                    if !empty(unset_value)
                        " TLogDBG "4.2"
                        if has_key(b:setsyntax, '-')
                            " TLogDBG "4.3"
                            call add(b:setsyntax, unset_value)
                        else
                            " TLogDBG "4.4"
                            let b:setsyntax['-'] = [unset_value]
                        endif
                    endif
                    unlet unset_value
                    " TLogDBG "4.5"
                    exec val
                else
                    " TLogDBG 5
                    call s:SSet(var, val, var)
                endif
                " TLogDBG 6
                unlet var val
            endfor
        endif
    endif
    " TLogDBG 'fini'
endf


function! s:Set(option, value) "{{{3
    " TLogVAR a:option, a:value
    exec 'let '. a:option .' = a:value'
    " TLogDBG "ok"
endf


function! s:Save(option, unset_value) "{{{3
    " TLogVAR a:option, a:unset_value
    exec 'let b:setsyntax['. string(a:option) .'] = '. a:unset_value
    " TLogDBG "ok"
endf


function! s:SSet(option, value, unset_value) "{{{3
    " TLogVAR a:option, a:value, a:unset_value
    " TLogDBG 'let b:setsyntax['. string(a:option) .'] = '. string(eval(a:option))
    call s:Save(a:option, a:unset_value)
    call s:Set(a:option, eval(a:value))
    " TLogDBG "ok"
endf


let &cpo = s:save_cpo
unlet s:save_cpo
