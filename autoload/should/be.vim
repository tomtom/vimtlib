" be.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-21.
" @Last Change: 2009-03-02.
" @Revision:    0.0.49


let s:save_cpo = &cpo
set cpo&vim


let s:types = ['number', 'string', 'funcref', 'list', 'dictionary']


" Test if expr is of type, where type can be:
"
"     - One of: 'number', 'string', 'funcref', 'list', 'dictionary'
"     - A list of above type names (one of which must match)
"     - A dictionary in which case the type is evaluated as object 
"       template. Keys in the template that do not have a value of 0, 
"       must exist in the object/expression.
"
" See also |type()|.
function! should#be#A(expr, type)
    return s:CheckType(a:expr, a:type, string(a:type))
endf


" Faster checks than version above but without descriptive messages and 
" type must be a string.
function! should#be#Type(expr, type)
    return type(a:expr) == index(s:types, a:type)
endf


function! should#be#Number(expr)
    return s:CheckType(a:expr, 0, 'number')
endf


function! should#be#String(expr)
    return s:CheckType(a:expr, 1, 'string')
endf


function! should#be#Funcref(expr)
    return s:CheckType(a:expr, 2, 'funcref')
endf


function! should#be#List(expr)
    return s:CheckType(a:expr, 3, 'list')
endf


function! should#be#Dictionary(expr)
    return s:CheckType(a:expr, 4, 'dictionary')
endf


function! should#be#Equal(expr, expected)
    let rv = type(a:expr) == type(a:expected) && a:expr == a:expected
    if !rv
        call should#__Explain('Expected '. string(a:expected) .' but got '. string(a:expr))
    endif
    return rv
endf


function! should#be#Unequal(expr, expected)
    let rv  = type(a:expr) != type(a:expected) || a:expr != a:expected
    if !rv
        call should#__Explain('Expected '. string(a:expected) .' is unequal to '. string(a:expr))
    endif
    return rv
endf


function! should#be#Greater(a, b) "{{{3
    return s:Compare(a:a, a:b, '>')
endf


function! should#be#GreaterEqual(a, b) "{{{3
    return s:Compare(a:a, a:b, '>=')
endf


function! should#be#Less(a, b) "{{{3
    return s:Compare(a:a, a:b, '<')
endf


function! should#be#LessEqual(a, b) "{{{3
    return s:Compare(a:a, a:b, '<=')
endf


function! s:Compare(a, b, comparator) "{{{3
    try
        exec 'let rv = a:a '. a:comparator .' a:b'
    catch
        let rv = 0
    endtry
    if !rv
        call should#__Explain('Expected '. string(a:a) .' '. a:comparator .' '. string(a:b))
    endif
    return rv
endf


function! should#be#Empty(expr)
    let rv = empty(a:expr)
    if !rv
        call should#__Explain(string(a:expr) .' isn''t empty')
    endif
    return rv
endf


function! should#be#NotEmpty(expr)
    let rv = !empty(a:expr)
    if !rv
        call should#__Explain(string(a:expr) .' is empty')
    endif
    return rv
endf


function! should#be#Match(expr, expected)
    let val = a:expr
    let rv  = val =~ a:expected
    if !rv
        call should#__Explain(string(val) .' doesn''t match '. string(a:expected))
    endif
    return rv
endf


function! should#be#NotMatch(expr, expected)
    let val = a:expr
    let rv  = val !~ a:expected
    if !rv
        call should#__Explain(add(s:assertReason, string(val) .' matches '. string(a:expected))
    endif
    return rv
endf


function! should#be#Existent(expr)
    let val = a:expr
    let rv = exists(val)
    if !rv
        call should#__Explain(add(s:assertReason, string(val) .' doesn''t exist')
    endif
    return rv
endf


" :display: should#be#Like(string, rx, ?case='')
" Case can be "#" or "?".
function! should#be#Like(string, rx, ...) "{{{3
    exec 'let rv = a:string =~'. (a:0 >= 1 ? a:1 : '') .'a:rx'
    if !rv
        call should#__Explain('Expected '. string(a:string) .' to match '. string(a:rx))
    endif
    return rv
endf


" :display: should#be#Unlike(string, rx, ?case='')
" Case can be "#" or "?".
function! should#be#Unlike(string, rx, ...) "{{{3
    exec 'let rv = a:string !~'. (a:0 >= 1 ? a:1 : '') .'a:rx'
    if !rv
        call should#__Explain('Expected '. string(a:string) .' not to match '. string(a:rx))
    endif
    return rv
endf


" :nodoc:
function! s:CheckType(expr, type, expected)
    " TLogVAR a:expr, a:type
    let type = type(a:expr)
    if type(a:type) == 3
        " type is a list of types
        for t in a:type
            let rv = s:CheckType(a:expr, t, a:expected)
            if rv
                return rv
            endif
        endfor
    elseif type(a:type) == 1
        " type is a type name
        let t = index(s:types, tolower(a:type))
        if t == -1
            throw 'Unknown type: '. string(a:type)
        else
            return s:CheckType(a:expr, t, a:expected)
        endif
    elseif type(a:type) == 4
        " type is a dictionary
        " let Val  = a:expr
        " let type = type(Val)
        if type == 4
            let rv = !len(filter(keys(a:type), '!s:CheckMethod(a:expr, a:type, v:val)'))
        else
            let rv = 0
        endif
    else
        " let type = type(Val)
        let rv = type == a:type
    endif
    if !rv
        call should#__Explain('Expected a '. a:expected .' but got a '. get(s:types, type, 'unknown') .': '. string(a:expr))
    endif
    return rv
endf


" :nodoc:
function! s:CheckMethod(dict, prototype, method)
    " if a:method == 'data'
    "     return 1
    " endif
    let m = a:prototype[a:method]
    if type(m) == 0 && !m
        return 1
    endif
    return has_key(a:dict, a:method)
endf



let &cpo = s:save_cpo
unlet s:save_cpo
