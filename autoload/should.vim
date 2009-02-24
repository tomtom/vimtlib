" should.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-21.
" @Last Change: 2009-02-22.
" @Revision:    0.0.35

let s:save_cpo = &cpo
set cpo&vim



" :nodoc:
fun! should#__Init() "{{{3
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
fun! should#__Explain(rv, reason)
    if empty(a:rv) && exists(':s:should_reason')
        call add(s:should_reason, a:reason)
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
