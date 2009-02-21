" be.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-21.
" @Last Change: 2009-02-21.
" @Revision:    0.0.18

let s:save_cpo = &cpo
set cpo&vim



" Test if expr is of type (see |type()|).
fun! should#be#A(expr, type)
    return s:CheckType(a:expr, a:type, string(a:type))
endf


fun! should#be#Number(expr)
    return s:CheckType(a:expr, 0, 'number')
endf


fun! should#be#String(expr)
    return s:CheckType(a:expr, 1, 'string')
endf


fun! should#be#Funcref(expr)
    return s:CheckType(a:expr, 2, 'funcref')
endf


fun! should#be#List(expr)
    return s:CheckType(a:expr, 3, 'list')
endf


fun! should#be#Dictionary(expr)
    return s:CheckType(a:expr, 4, 'dictionary')
endf


" Return the exception when evaluating expr or an empty string if 
" nothing was thrown.
fun! should#be#Exception(expr)
    try
        call eval(a:expr)
        return ''
    catch
        return v:exception
    endtry
endf


" Check if the exception throws when evaluating expr matches the 
" expected |regexp|.
fun! should#be#Error(expr, expected)
    let rv = should#be#Exception(a:expr)
    if rv =~ a:expected
        return 1
    else
        call should#__Explain(0, 'Exception '. string(a:expected) .' expected but got '. string(rv))
        return 0
    endif
endf


fun! should#be#Equal(expr, expected)
    " let val = eval(a:expr)
    let val = a:expr
    let rv  = val == a:expected
    if !rv
        call should#__Explain(rv, 'Expected '. string(a:expected) .' but got '. string(val))
    endif
    return rv
endf


fun! should#be#Unequal(expr, expected)
    let val = eval(a:expr)
    let rv  = val != a:expected
    if !rv
        call should#__Explain(rv, 'Expected '. string(a:expected) .' is unequal to '. string(val))
    endif
    return rv
endf


fun! should#be#Empty(expr)
    let rv = empty(a:expr)
    if !rv
        call should#__Explain(rv, string(a:expr) .' isn''t empty')
    endif
    return rv
endf


fun! should#be#NotEmpty(expr)
    let rv = !empty(a:expr)
    if !rv
        call should#__Explain(rv, string(a:expr) .' is empty')
    endif
    return rv
endf


fun! should#be#Match(expr, expected)
    let val = a:expr
    let rv  = val =~ a:expected
    if !rv
        call should#__Explain(rv, string(val) .' doesn''t match '. string(a:expected))
    endif
    return rv
endf


fun! should#be#NotMatch(expr, expected)
    let val = a:expr
    let rv  = val !~ a:expected
    if !rv
        call should#__Explain(rv, add(s:assertReason, string(val) .' matches '. string(a:expected))
    endif
    return rv
endf


fun! should#be#Existent(expr)
    let val = a:expr
    let rv = exists(val)
    if !rv
        call should#__Explain(rv, add(s:assertReason, string(val) .' doesn''t exist')
    endif
    return rv
endf


let s:types = ['number', 'string', 'funcref', 'list', 'dictionary']


" :nodoc:
fun! s:CheckType(expr, type, expected)
    " TLogVAR a:expr, a:type
    let type = type(a:expr)
    if type(a:type) == 3
        for t in a:type
            let rv = s:CheckType(a:expr, t, a:expected)
            if rv
                return rv
            endif
        endfor
    elseif type(a:type) == 1
        let t = index(s:types, tolower(a:type))
        if t == -1
            throw 'Unknown type: '. string(a:type)
        else
            return s:CheckType(a:expr, t, a:expected)
        endif
    elseif type(a:type) == 4
        let Val  = a:expr
        " let type = type(Val)
        if type == 4
            let rv = !len(filter(keys(a:type), '!s:CheckMethod(Val, a:type, v:val)'))
        endif
    else
        " let type = type(Val)
        let rv = type == a:type
    endif
    if !rv
        call should#__Explain(rv, 'Expected a '. a:expected .' but got a '. get(s:types, type, 'unknown') .': '. string(a:expr))
    endif
    return rv
endf


" :nodoc:
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



let &cpo = s:save_cpo
unlet s:save_cpo
