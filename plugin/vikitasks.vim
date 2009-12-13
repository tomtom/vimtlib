" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-12-13.
" @Last Change: 2009-12-13.
" @Revision:    31
" GetLatestVimScripts: 0 0 :AutoInstall: vikitasks.vim
" Search for task lists and display them in a list


if !exists('g:loaded_tlib') || g:loaded_tlib < 34
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 34
        echoerr 'tlib >= 0.34 is required'
        finish
    endif
endif
if !exists('g:loaded_trag') || g:loaded_trag < 7
    runtime plugin/trag.vim
    if !exists('g:loaded_trag') || g:loaded_trag < 7
        echoerr 'trag >= 0.7 is required'
        finish
    endif
endif
if &cp || exists("loaded_vikitasks")
    finish
endif
let loaded_vikitasks = 1

let s:save_cpo = &cpo
set cpo&vim


" A list of glob patterns (or files) that will be searched for task 
" lists.
" Can be buffer-local.
" Add new items in ~/vimfiles/after/plugin/vikitasks.vim
TLet g:vikitasks_files = []

" If non-null, automatically add the homepages of your intervikis to 
" |g:vikitasks_files|.
TLet g:vikitasks_intervikis = 0

" A list of ignored intervikis.
TLet g:vikitasks_intervikis_ignored = []

" The viewer for the quickfix list. If empty, use |:TRagcw|.
TLet g:vikitasks_qfl_viewer = ''


TRagDefKind tasks viki /^[[:blank:]]\+\zs#\(T: \+.\{-}\u.\{-}:\|\d*\u\d*\( \+\(_\|[0-9%-]\+\)\)\?\)\( \+\[[^[].\{-}\]\)\?\ze /


" :display: VikiTasks[!] [FILE PATTERNS]
" Collect a list of tasks from a set of viki pages.
" With the optional !, show all tasks not just those with a date
" The current buffer has to be a viki buffer. If it isn't, your 
" |g:vikiHomePage|, which must be set, is opened first.
command! -bang -nargs=? VikiTasks call vikitasks#Tasks(!empty("<bang>"), <f-args>)
cabbr vikitasks VikiTasks



let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release

