" throw.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-21.
" @Last Change: 2010-02-27.
" @Revision:    0.0.20

let s:save_cpo = &cpo
set cpo&vim


" Return the exception when evaluating expr or an empty string if 
" nothing was thrown.
fun! should#throw#Something(expr)
    try
        call should#__Eval(a:expr)
        call should#__Explain('Expected exception but none was thrown')
        return 0
    catch
        " TLog v:exception
        return 1
    endtry
endf


" Check if the exception throws when evaluating expr matches the 
" expected |regexp|.
fun! should#throw#Exception(expr, expected)
    try
        call should#__Eval(a:expr)
        let msg = ''
    catch
        let msg = v:exception .': '. v:throwpoint
    endtry
    if empty(msg)
        call should#__Explain('Expected exception '. string(a:expected) .'but none was thrown')
        let rv = 0
    elseif msg =~ a:expected
        let rv = 1
    else
        call should#__Explain('Expected exception '. string(a:expected) .' but got '. string(msg))
        let rv = 0
    endif
    if rv == 0
        echohl Error
        echom msg
        echohl NONE
    endif
    return rv
endf


let &cpo = s:save_cpo
unlet s:save_cpo
