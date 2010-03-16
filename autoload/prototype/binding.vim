" binding.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-03-01.
" @Last Change: 2010-03-15.
" @Revision:    61


function! prototype#binding#New(bindings) "{{{3
    let o = copy(a:bindings)
    let o.__Eval = function('prototype#binding#Eval')
    return o
endf


" :nodoc:
" :display: prototype#binding#Eval(STRING, ARGS...)
function! prototype#binding#Eval(...) dict "{{{3
    if type(a:1) == 1
        let env = prototype#AsVim(self)
        exec env .'| return ('. self._Call .')'
    elseif type(a:1) == 2
        return call(a:1, a:000[1 : -1], self)
    else
        throw 'Must be a string or a Funcref: '. string(self._Call)
    endif
endf


" :display: Binding NAME = VARS...
" Define a binding object.
" RESTRICTIONS: NAME cannot be script-local.
" 
" Example:
"     let x = 2
"     Binding foo = x
"     function! foo._(a) dict
"          return a:a * self.x
"     endf
"     echom foo._(10)
"     => 20
"
"     function! Bar(binding)
"          exec prototype#AsVim(a:binding) .'| return x'
"     endf
"     echom Bar(foo)
"     => 20
command! -nargs=+ Binding let s:args = matchlist(<q-args>, '^\s*\(\S\+\)\s*=\s*\(.\{-}\)\s*$') | 
            \ exec 'let '. s:args[1] .' = prototype#binding#New({'.
            \ join(map(split(s:args[2], ',\?\s\+'), 'string(v:val) .":". string(eval(v:val))'), ', ')
            \ .'})' |
            \ unlet s:args


