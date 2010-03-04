" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-02-26.
" @Last Change: 2010-03-02.
" @Revision:    354
" GetLatestVimScripts: 0 0 prototype.vim

let s:save_cpo = &cpo
set cpo&vim


" :display: prototype#New(?self={}, ?prototype={})
" Define a new "object".
" The first arguments holds the object's attributes. It can be either a 
" dictionary or a list, which will be converted into a dictionary.
" Optionally inherit methods and attributes from a prototype, which can 
" be an "object" or a vimscript |Dictionary|.
function! prototype#New(...) "{{{3
    if a:0 >= 1
        if type(a:1) == 3
            let self = {}
            let i = 0
            for v in a:1
                let self[i] = v
                let i += 1
            endfor
        elseif type(a:1) == 4
            let self = copy(a:1)
        else
            throw 'Prototype: self must be either a dictionary or a list: '. string(a:1)
        endif
    else
        let self = {}
    endif
    let prototype = a:0 >= 2 ? a:2 : {}
    let self.__Get = function('prototype#Get')
    let self.__Set = function('prototype#Set')
    let self.__Prototype = function('prototype#Prototype')
    return self.__Prototype(prototype)
endf

   
" :display: prototype#Keys(self, ?type=0)
" Return the object's keys as list -- exclude methods/attributes 
" prefixed with an underscore.
" type is one of:
"     0 ... any
"     1 ... numeric only
"     2 ... non-numeric keys only
function! prototype#Keys(self, ...) "{{{3
    let type = a:0 >= 1 ? a:1 : 0
    let keys = keys(a:self)
    call filter(keys, 'type(v:val) != 1 || v:val[0] != "_"')
    if type == 1
        let keys = filter(keys, 'v:val =~ ''^\d\+\(\.\d\+\)\?\(e\d\+\)\?''')
        let keys = map(sort(map(keys, 'printf("%02d", v:val)')), 'v:val + 0')
    elseif type == 2
        let keys = filter(keys, 'type(v:val) != 0')
    endif
    return keys
endf


" :nodoc:
function! prototype#Set(field, value) dict "{{{3
    let self[a:field] = a:value
    return self
endf


" :nodoc:
function! prototype#Get(key, ...) dict
    if !has_key(self, a:key) && has_key(self, '__Default')
        call self.__Default(a:key)
    endif
    return call('get', [self, a:key] + a:000)
endf


" :nodoc:
function! prototype#Prototype(prototype) dict "{{{3
    if a:prototype == self
        throw 'Prototype: Circular reference: '. string(a:prototype)
    endif

    if has_key(self, '__abstract')
        let keys = prototype#Keys(self)
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


" :nodoc:
function! prototype#SetAbstract(dict, self) "{{{3
    " TLogVAR a:self, a:dict
    let keys = prototype#Keys(a:self)
    for field in keys
        if !has_key(a:dict, field)
            let a:dict[field] = {'type': type(a:self[field])}
        endif
    endfor
endf


" Export the object as plain |Dictionary| that has no dependency on 
" prototype.
function! prototype#AsDictionary(obj) "{{{3
    if has_key(a:obj, '__prototype')
        let d = copy(a:obj)
        call filter(d, 'type(v:key) != 1 || v:key[0] != "_"')
        return d
    else
        return copy(a:obj)
    endif
endf


" :display: prototype#AsList(obj, ?default="")
" Export the object's numeric fields as |List|.
" Exported fields start with 0. Values with negative or non-numeric keys 
" are dropped.
" Missing fields are filled with a default value, which defaults to "".
function! prototype#AsList(obj, ...) "{{{3
    let default = a:0 >= 1 ? a:1 : ""
    return map(range(0, max(prototype#Keys(a:obj, 1))), 
                \ 'has_key(a:obj, v:val) ? a:obj[v:val] : default')
endf


" Return an executable string that represents the dictionary as 
" vimscript code.
function! prototype#AsVim(obj) "{{{3
    return join(map(prototype#Keys(a:obj, 2), '"let ". v:val ."=". string(a:obj[v:val])'), '|')
endf


let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release

