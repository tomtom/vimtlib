" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-02-26.
" @Last Change: 2010-03-01.
" @Revision:    333
" GetLatestVimScripts: 0 0 prototypestrict.vim

let s:save_cpo = &cpo
set cpo&vim


let s:types = ['Number', 'String', 'Funcref', 'List', 'Dictionary', 'Float']


" :display: prototype#strict#New(self, ?prototype={})
" Define a new "object" similar to |prototype#New()| but checks type 
" consistency when setting the prototype or a field value using the 
" __Set method.
"
" The o.__abstract.FIELD dictionary has an optional field:
"
"     Validate(value)       ... Return a validated value for FIELD
function! prototype#strict#New(...) "{{{3
    let self = call(function('prototype#New'), a:000)
    let self.__Prototype0 = self.__Prototype
    let self.__Prototype = function('prototype#strict#Prototype')
    let self.__Set = function('prototype#strict#Set')
    call s:ValidateDict(self, self, [])
    return self
endf


" :nodoc:
function! prototype#strict#Prototype(prototype) dict "{{{3
    let ans = self.__Prototype0(a:prototype)
    call s:ValidateDict(self, self, [])
    return self
endf


" :nodoc:
function! prototype#strict#Set(field, value) dict "{{{3
    let self[a:field] = a:value
    call s:ValidateDict(self, self, [a:field])
    return self
endf


" Check the object's invariants (type consistency)
function! prototype#strict#Validate(self) "{{{3
    if has_key(a:self, '__prototype')
        return s:ValidateDict(a:self, a:self, [])
    else
        return a:self
    endif
endf


" Return a validated copy of an object.
function! prototype#strict#Clone(object) "{{{3
    let that = copy(a:object)
    call prototype#strict#Validate(that)
    return that
endf


function! s:ValidateDict(self, this, fields) "{{{3
    " TLogVAR a:self
    " TLogVAR a:this
    " TLogVAR has_key(a:this, '__abstract')
    if has_key(a:this, '__abstract')
        let abstract = a:this.__abstract
    else
        let abstract = {}
        call prototype#SetAbstract(abstract, a:this)
    endif
    if !empty(a:fields)
        let abstract = filter(copy(abstract), 'index(a:fields, v:key) != -1')
    endif
    " TLogVAR abstract
    for [field, fdef] in items(abstract)
        " TLogVAR field, fdef
        if has_key(fdef, 'Validate')
            let a:self[field] = call(fdef.Validate, [a:self[field]], a:self)
        endif
        let otype = type(a:self[field])
        let etype = fdef.type
        " TLogVAR field, otype, etype
        if otype != etype
            throw 'Prototype: Expected '. string(field) .' to be a '. s:types[etype] .': '. string(a:self[field])
        endif
    endfor
    if has_key(a:this, '__prototype')
        call s:ValidateDict(a:self, a:this.__prototype, a:fields)
    endif
    return a:self
endf


let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release

