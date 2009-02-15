" tbak.vim -- Yet another simple backup plugin using diff
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim-tbak)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-07.
" @Last Change: 2009-02-15.
" @Revision:    0.1.59

if &cp || exists("loaded_tbak")
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 9
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 9
        echoerr 'tlib >= 0.9 is required'
        finish
    endif
endif
let loaded_tbak = 1

if !exists("g:tbakDateFormat")  | let g:tbakDateFormat = '%y%m%d' | endif "{{{2
" if !exists("g:tbakDateFormat")  | let g:tbakDateFormat = '%y%m'   | endif "{{{2
" if !exists("g:tbakDateFormat")  | let g:tbakDateFormat = '%y%W'   | endif "{{{2

if !exists("g:tbakMaxVersions") | let g:tbakMaxVersions = 20      | endif "{{{2

if !exists("g:tbakAutoBackup")  | let g:tbakAutoBackup = 0        | endif "{{{2
if !exists("g:tbakAutoUpdate")  | let g:tbakAutoUpdate = 1        | endif "{{{2

if !exists("g:tbakAttic")       | let g:tbakAttic = '.attic'      | endif "{{{2
if !exists("g:tbakDir")         | let g:tbakDir = ''              | endif "{{{2

if !exists("g:tbakGlobal")      | let g:tbakGlobal = 0            | endif "{{{2
if !exists("g:tbakGlobalDir")   | let g:tbakGlobalDir = ''        | endif "{{{2

if !exists("g:tbakCheck") "{{{2
    let g:tbakCheck = 'diff -q -w -B "%s" "%s"'
endif
if !exists("g:tbakDiff") "{{{2
    let g:tbakDiff = 'diff -w -B -u3 "%s" "%s" > "%s"'
endif

command! -bang -bar TBak call tbak#TBak("<bang>")
command! -bar -bang -nargs=? TBakRevert call tbak#TBakRevert(<q-args>, "<bang>")
command! -bar -bang -nargs=? TBakCleanup call tbak#TBakCleanup(<q-args>, "<bang>")
command! -bar -bang -nargs=? TBakView call tbak#TBakView(<q-args>, "<bang>")
command! -bar -bang -nargs=? TBakDiff call tbak#TBakView(<q-args>, "<bang>")

augroup tbak
    au!
    au BufWritePre * if !&bin && (exists('b:tbakAutoBackup') ? b:tbakAutoBackup : g:tbakAutoBackup) | TBak | endif
augroup END

