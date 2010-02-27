" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-02-26.
" @Last Change: 2010-02-27.
" @Revision:    265
" GetLatestVimScripts: 0 0 prototypestrict.vim

let s:save_cpo = &cpo
set cpo&vim


" :display: prototypestrict#New(self, ?prototype={})
" Define a new "object" similar to |prototype#New()| but add some 
" additional methods:
"
"     o.__Validate()           ... Check the object's invariants (type 
"                                  consistency)
"     o.__Clone()              ... Return a validated copy of self
function! prototypestrict#New(self, ...) "{{{3
    let prototype = a:0 >= 1 ? a:1 : {}
    let self = copy(a:self)

    function! self.__Prototype(prototype) dict "{{{3
        if a:prototype == self
            throw 'Prototype: Circular reference: '. string(a:prototype)
        endif

        if has_key(self, '__abstract')
            let keys = keys(self)
            call filter(keys, 'strpart(v:val, 0, 2) != "__"')
            call filter(keys, '!has_key(self.__abstract, v:val)')
            let this = self
            while has_key(this, '__prototype')
                let prec = this.__prototype
                for k in keys
                    if has_key(self, k) && has_key(prec, k) && self[k] == prec[k]
                        call remove(self, k)
                    endif
                endfor
                let this = prec
            endwh
        else
            let self.__abstract = {}
        endif
        call s:SetAbstract(self, self.__abstract)

        call extend(self, a:prototype, 'keep')
        let self.__prototype = a:prototype
        
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


function! s:SetAbstract(self, dict) "{{{3
    " TLogVAR a:self, a:dict
    for nv in items(a:self)
        if strpart(nv[0], 0, 2) != "__" && !has_key(a:dict, nv[0])
            let a:dict[nv[0]] = {'type': type(nv[1])}
        endif
    endfor
endf

    
function! s:Validate(self, this, checked) "{{{3
    " TLogVAR a:self
    " TLogVAR a:this
    if has_key(a:this, '__abstract')
        let abstract = a:this.__abstract
    else
        let abstract = {}
        call s:SetAbstract(a:this, abstract)
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

