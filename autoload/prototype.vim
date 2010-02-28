" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-02-26.
" @Last Change: 2010-02-28.
" @Revision:    291
" GetLatestVimScripts: 0 0 prototype.vim

let s:save_cpo = &cpo
set cpo&vim


" :display: prototype#New(?self={}, ?prototype={})
" Define a new "object". Optionally inherit methods and attributes from 
" a prototype, which can be an "object" or a vimscript |Dictionary|.
"
" Example: >
"
"     let o = prototype#New({'a': 1, 'b': 2})
"     function! o.Foo(x) dict
"         return self.a * a:x
"     endf
"
" < The new object has the following additional fields and method(s):
"
"     o.__Prototype(prototype) ... Set the prototype
"     o.__prototype            ... Access the prototype
"     o.__Keys()               ... Return the object's fields (without 
"                                  those prefixed with '__')
"     o.__Get(key, [default])  ... Get key's value, call 
"                                  o.__Missing(key) if defined.
"
" For internal use:
"
"     o.__abstract             ... The fields that define the assured 
"                                  interface of the object (those 
"                                  fields not inherited from prototypes)
" 
" You should not overwrite the values of these fields.
function! prototype#New(...) "{{{3
    let self      = a:0 >= 1 ? copy(a:1) : {}
    let prototype = a:0 >= 2 ? a:2 : {}
    let self.__Keys = function(s:SNR().'Keys')
    let self.__Get = function(s:SNR().'Get')
    let self.__Prototype = function(s:SNR().'Prototype')
    return self.__Prototype(prototype)
endf


fun! s:SNR()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
endf

    
function! s:Keys() dict "{{{3
    let keys = keys(self)
    call filter(keys, 'strpart(v:val, 0, 2) != "__"')
    return keys
endf


function! s:Get(key, ...) dict
    if !has_key(self, a:key) && has_key(self, '__Default')
        call self.__Default(a:key)
    endif
    return call('get', [self, a:key] + a:000)
endf


function! s:Prototype(prototype) dict "{{{3
    if a:prototype == self
        throw 'Prototype: Circular reference: '. string(a:prototype)
    endif

    if has_key(self, '__abstract')
        let keys = self.__Keys()
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

    call prototype#SetAbstract(self.__abstract, self)

    call extend(self, a:prototype, 'keep')
    let self.__prototype = a:prototype

    return self
endf


function! prototype#SetAbstract(dict, self) "{{{3
    " TLogVAR a:self, a:dict
    let keys = has_key(a:self, '__Keys') ? a:self.__Keys() : keys(a:self)
    for field in keys
        if !has_key(a:dict, field)
            let a:dict[field] = {'type': type(a:self[field])}
        endif
    endfor
endf


let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release

