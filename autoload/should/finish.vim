" finish.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2009-02-28.
" @Revision:    0.0.14

let s:save_cpo = &cpo
set cpo&vim


function! should#finish#InSecs(expr, secs) "{{{3
    let start = localtime()
    try
        call should#__Eval(a:expr)
    catch
    endtry
    let d  = localtime() - start
    let rv = d <= a:secs
    if !rv
        call should#__Explain('Expected '. a:expr .' to finish in less than '. a:secs .'s, but it took '. d .'s')
    endif
    return rv
endf


function! should#finish#InMicroSecs(expr, msecs) "{{{3
    if exists('g:loaded_tlib')
        let start = tlib#time#Now()
        try
            call should#__Eval(a:expr)
        catch
        endtry
        let d  = tlib#time#Diff(tlib#time#Now(), start)
        " TLogVAR d
        let rv = d <= a:msecs
        if !rv
            call should#__Explain('Expected '. a:expr .' to finish in less than '. a:msecs .'ms, but it took '. d .'ms')
        endif
        return rv
    else
        call should#__Explain('should#finish#InMicroSecs requires tlib')
        return 0
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
