" should.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-21.
" @Last Change: 2009-03-01.
" @Revision:    0.0.47

let s:save_cpo = &cpo
set cpo&vim



" :nodoc:
fun! should#__Init() "{{{3
    " TLog 'should#__Init'
    let s:should_reason = []
endf


" :nodoc:
fun! should#__InsertReason(reason) "{{{3
    call insert(s:should_reason, a:reason)
    return a:reason
endf


" :nodoc:
fun! should#__Reasons() "{{{3
    return join(s:should_reason, ': ')
endf


" :nodoc:
fun! should#__ClearReasons() "{{{3
    let rv = should#__Reasons()
    let s:should_reason = []
    return rv
endf


" :nodoc:
fun! should#__Explain(reason)
    if exists('s:should_reason')
        call add(s:should_reason, a:reason)
    endif
endf


" :nodoc:
function! should#__Eval(expr) "{{{3
    if a:expr[0:0] == ':'
        exec a:expr
    else
        return eval(a:expr)
    endif
endf


function! should#__Require(what) "{{{3
    if !exists('g:loaded_'. a:what)
        throw 'should#maintain#WindowLayout requires '. a:what
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
