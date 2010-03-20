" hookcursormoved.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-10-04.
" @Last Change: 2010-03-20.
" @Revision:    0.3.245

" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


let s:unknown_hooks = []

augroup HookCursorMoved
    autocmd!
augroup END


function! s:RunHooks(mode, condition) "{{{3
    if !exists('b:hookcursormoved_'. a:mode .'_'. a:condition)
        return
    endif
    " TLogVAR a:condition, g:hookcursormoved_{a:condition}
    if call(g:hookcursormoved_{a:condition}, [a:mode])
        let hooks = b:hookcursormoved_{a:mode}_{a:condition}
        for HookFn in hooks
            " TLogVAR HookFn
            try
                keepjumps keepmarks call call(HookFn, [a:mode])
            catch
                echohl Error
                echom v:errmsg
                echohl NONE
            endtry
            if winsaveview() != b:hookcursormoved_currview
                call winrestview(b:hookcursormoved_currview)
                " call setpos('.', b:hookcursormoved_currpos)
            endif
            unlet HookFn
        endfor
    endif
endf


function! s:SaveView() "{{{3
    if exists('b:hookcursormoved_currpos')
        let b:hookcursormoved_oldpos = b:hookcursormoved_currpos
        let b:hookcursormoved_oldview = b:hookcursormoved_currview
        " TLogVAR b:hookcursormoved_oldpos
    endif
    let b:hookcursormoved_currpos = getpos('.')
    let b:hookcursormoved_currview = winsaveview()
    " TLogVAR b:hookcursormoved_currpos
endf


function! hookcursormoved#Enable(condition) "{{{3
    if !exists('b:hookcursormoved_enabled')
        let b:hookcursormoved_enabled = []
        autocmd HookCursorMoved CursorMoved,CursorMovedI <buffer> call s:SaveView()
    endif
    if index(b:hookcursormoved_enabled, a:condition) == -1
        exec 'autocmd HookCursorMoved CursorMoved  <buffer> call s:RunHooks("n", '. string(a:condition) .')'
        exec 'autocmd HookCursorMoved CursorMovedI <buffer> call s:RunHooks("i", '. string(a:condition) .')'
        call add(b:hookcursormoved_enabled, a:condition)
    endif
    if !exists('b:hookcursormoved_synname')
        let b:hookcursormoved_synname = ''
        let b:hookcursormoved_synpos  = []
    endif
    if !exists('b:hookcursormoved_char')
        let b:hookcursormoved_char     = ''
        let b:hookcursormoved_charpos  = []
    endif
endf


" :def: function! hookcursormoved#Register(condition, fn, ?mode='ni', ?remove=0)
function! hookcursormoved#Register(condition, fn, ...) "{{{3
    if !exists('g:hookcursormoved_linechange')
        " Not loaded
        return
    endif
    let modes  = a:0 >= 1 && a:1 != '' ? a:1 : 'ni'
    let remove = a:0 >= 2 ? a:2 : 0
    " TLogVAR a:condition, a:fn, mode
    " TLogDBG exists('*hookcursormoved#Test_'. a:condition)
    " TLogVAR 'g:hookcursormoved_'. a:condition, exists('g:hookcursormoved_'. a:condition)
    if exists('g:hookcursormoved_'. a:condition)
        call hookcursormoved#Enable(a:condition)
        for mode in split(modes, '\ze')
            if stridx(mode, 'i') != -1
                let var = 'b:hookcursormoved_i_'. a:condition
            endif
            if stridx(mode, 'n') != -1
                let var = 'b:hookcursormoved_n_'. a:condition
            endif
            " TLogVAR remove, a:fn
            if remove
                if exists(var)
                    " TLogVAR {var}
                    let idx = index({var}, a:fn)
                    if idx >= 0
                        call remove({var}, idx)
                        " TLogVAR {var}
                    endif
                endif
            else
                if !exists(var)
                    let {var} = [a:fn]
                else
                    call add({var}, a:fn)
                endif
                " TLogVAR {var}
            endif
        endfor
    elseif index(s:unknown_hooks, a:condition) == -1
        call add(s:unknown_hooks, a:condition)
        echohl Error
        echom 'hookcursormoved: Unknown condition: '. string(a:condition)
        echohl None
    endif
endf


function! hookcursormoved#Test_linechange(mode) "{{{3
    " TLogVAR a:mode
    return exists('b:hookcursormoved_oldpos')
                \ && b:hookcursormoved_currpos[1] != b:hookcursormoved_oldpos[1]
endf


function! hookcursormoved#Test_parenthesis(mode) "{{{3
    return s:CheckChars(a:mode, '(){}[]')
endf


function! hookcursormoved#Test_parenthesis_round(mode) "{{{3
    return s:CheckChars(a:mode, '()')
endf


function! hookcursormoved#Test_parenthesis_round_open(mode) "{{{3
    return s:CheckChars(a:mode, '(')
endf


function! hookcursormoved#Test_parenthesis_round_close(mode) "{{{3
    return s:CheckChars(a:mode, ')')
endf


function! hookcursormoved#Test_syntaxchange(mode) "{{{3
    let syntax = s:SynId(a:mode, b:hookcursormoved_currpos)
    if exists('b:hookcursormoved_syntax')
        let rv = b:hookcursormoved_syntax != syntax
    else
        let rv = 0
    endif
    let b:hookcursormoved_syntax = syntax
    return rv
endf


function! hookcursormoved#Test_syntaxleave(mode) "{{{3
    let syntax = s:SynId(a:mode, b:hookcursormoved_oldpos)
    let rv = b:hookcursormoved_syntax != syntax && index(b:hookcursormoved_syntaxleave, syntax) != -1
    let b:hookcursormoved_syntax = syntax
    return rv
endf


function! hookcursormoved#Test_syntaxleave_oneline(mode) "{{{3
    if exists('b:hookcursormoved_oldpos')
        let rv = b:hookcursormoved_currpos[1] != b:hookcursormoved_oldpos[1]
        let syntax = s:SynId(a:mode, b:hookcursormoved_oldpos)
        if !rv && exists('b:hookcursormoved_syntax')
            " TLogVAR syntax
            if !empty(syntax) && (!exists('b:hookcursormoved_syntaxleave') || index(b:hookcursormoved_syntaxleave, syntax) != -1)
                " TLogVAR b:hookcursormoved_syntax, syntax
                let rv = b:hookcursormoved_syntax != syntax
                " TLogVAR rv, b:hookcursormoved_currpos[1], b:hookcursormoved_oldpos[1]
            endif
            " TLogVAR rv
        endif
        let b:hookcursormoved_syntax = syntax
        " TLogVAR rv
        return rv
    endif
    return 0
endf


function! s:Col(mode, col) "{{{3
    " let co = a:col - 1
    let co = a:col
    if a:mode == 'i' && co > 1
        let co -= 1
    endif
    " TLogVAR co
    " TLogDBG getline('.')[co - 1]
    return co
endf


function! s:CheckChars(mode, chars) "{{{3
    if b:hookcursormoved_charpos != b:hookcursormoved_currpos
        let ln = b:hookcursormoved_currpos[1]
        let cn = b:hookcursormoved_currpos[2]
        let li = getline(ln)
        let co = s:Col(a:mode, cn)
        let b:hookcursormoved_char = li[co - 1]
        let b:hookcursormoved_charpos = b:hookcursormoved_currpos
    endif
    let rv = !empty(b:hookcursormoved_char) && stridx(a:chars, b:hookcursormoved_char) != -1
    " TLogVAR a:mode, li, co, rv, b:hookcursormoved_char
    return rv
endf


function! s:SynId(mode, pos) "{{{3
    if a:pos != b:hookcursormoved_synpos
        let li = a:pos[1]
        let co = s:Col(a:mode, a:pos[2])
        " let synid = synID(li, co, 1)
        let synid = synID(li, co, 0)
        let b:hookcursormoved_synname = synIDattr(synid, 'name')
        let b:hookcursormoved_synpos  = a:pos
        " TLogVAR li, co, synid, b:hookcursormoved_synname
        " TLogDBG synID(li, co, 0)
    endif
    return b:hookcursormoved_synname
endf

