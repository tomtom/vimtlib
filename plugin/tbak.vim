" tbak.vim -- Yet another simple backup plugin using diff
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim-tbak)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-07.
" @Last Change: 2010-01-03.
" @Revision:    0.1.66

if &cp || exists("loaded_tbak")
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 32
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 32
        echoerr 'tlib >= 0.32 is required'
        finish
    endif
endif
let loaded_tbak = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists("g:tbakAutoBackup")  | let g:tbakAutoBackup = 0        | endif "{{{2


command! -bang -bar TBak call tbak#TBak("<bang>")
command! -bar -bang -nargs=? TBakRevert call tbak#TBakRevert(<q-args>, "<bang>")
command! -bar -bang -nargs=? TBakCleanup call tbak#TBakCleanup(<q-args>, "<bang>")
command! -bar -bang -nargs=? TBakView call tbak#TBakView(<q-args>, "<bang>")
command! -bar -bang -nargs=? TBakDiff call tbak#TBakView(<q-args>, "<bang>")

augroup tbak
    au!
    au BufWritePre * if !&bin && (exists('b:tbakAutoBackup') ? b:tbakAutoBackup : g:tbakAutoBackup) | TBak | endif
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
finish

0.1
Initial release

