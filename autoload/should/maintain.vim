" maintain.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-26.
" @Last Change: 2009-03-07.
" @Revision:    0.0.8

let s:save_cpo = &cpo
set cpo&vim


" Require tlib.
function! should#maintain#WindowLayout(layout) "{{{3
    if !exists('loaded_tlib')
        throw 'should#maintain#WindowLayout requires tlib'
    endif
    let current_layout = tlib#win#GetLayout(1)
    let rv = 1
    let msg = []
    if a:layout.cmdheight != current_layout.cmdheight
        call add(msg, 'cmdheight')
    endif
    if a:layout.guioptions != current_layout.guioptions
        call add(msg, 'guioptions')
    endif
    if len(a:layout.views) != len(current_layout.views)
        call add(msg, 'number of windows')
    else
        for [n, view] in items(a:layout.views)
            if a:layout.views[n] != view
                call add(msg, 'window '. n)
            endif
        endfor
    endif
    if empty(msg)
        call should#__Explain(rv, 'Window layout has changed: '. join(msg, ', '))
        return 0
    else
        return 1
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
