" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-02-26.
" @Last Change: 2010-02-28.
" @Revision:    273
" GetLatestVimScripts: 0 0 prototypestrict.vim

let s:save_cpo = &cpo
set cpo&vim


" :display: prototype#strict#New(self, ?prototype={})
" Define a new "object" similar to |prototype#New()| but add some 
" additional methods:
"
"     o.__Validate()           ... Check the object's invariants (type 
"                                  consistency)
"     o.__Clone()              ... Return a validated copy of self
function! prototype#strict#New(self, ...) "{{{3
    let prototype = a:0 >= 1 ? a:1 : {}
    let self = prototype#New(a:self, prototype)
    let self.__Prototype__ = self.__Prototype

    function! self.__Prototype(prototype) dict "{{{3
        let ans = self.__Prototype__(a:prototype)
        call s:Validate(self, self, [])
        return self
    endf

    function! self.__Validate() dict "{{{3
        return s:Validate(self, self, [])
    endf

    function! self.__Clone() dict "{{{3
        let that = copy(self)
        call that.__Validate()
        return that
    endf
    
    return self.__Prototype(prototype)
endf

    
function! s:Validate(self, this, checked) "{{{3
    " TLogVAR a:self
    " TLogVAR a:this
    if has_key(a:this, '__abstract')
        let abstract = a:this.__abstract
    else
        let abstract = {}
        call prototype#SetAbstract(abstract, a:this)
    endif
    " TLogVAR abstract
    for [field, fdef] in items(abstract)
        " TLogVAR field
        if index(a:checked, field) == -1
            let otype = type(a:self[field])
            let etype = abstract[field].type
            " TLogVAR field, otype, etype
            if otype != etype
                " TLogDBG 'Prototype: Expected '. field .' to by of type '. otype .': '. string(a:self)
                throw 'Prototype: Expected '. field .' to by of type '. otype .': '. string(a:self)
            endif
            call add(a:checked, field)
        endif
    endfor
    if has_key(a:this, '__prototype')
        call s:Validate(a:self, a:this.__prototype, a:checked)
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release

