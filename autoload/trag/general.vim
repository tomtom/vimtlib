" general.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-12-01.
" @Last Change: 2008-12-03.
" @Revision:    0.0.10

let s:save_cpo = &cpo
set cpo&vim


function! trag#general#Rename(world, selected, from, to) "{{{3
    let cmd = 's/\C\<'. escape(tlib#rx#Escape(a:from), '/') .'\>/'. escape(tlib#rx#EscapeReplace(a:to), '/') .'/ge'
    return trag#RunCmdOnSelected(a:world, a:selected, cmd)
endf


let &cpo = s:save_cpo
unlet s:save_cpo
