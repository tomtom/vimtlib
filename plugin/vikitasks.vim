" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-12-13.
" @Last Change: 2009-12-21.
" @Revision:    114
" GetLatestVimScripts: 0 0 :AutoInstall: vikitasks.vim
" Search for task lists and display them in a list


if !exists('g:loaded_tlib') || g:loaded_tlib < 35
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 35
        echoerr 'tlib >= 0.35 is required'
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
" If you add ! to 'viminfo', this variable will be automatically saved 
" between editing sessions.
" Alternatively, add new items in ~/vimfiles/after/plugin/vikitasks.vim
TLet g:vikitasks_files = []

" If non-null, automatically add the homepages of your intervikis to 
" |g:vikitasks_files|.
" Can be buffer-local.
TLet g:vikitasks_intervikis = 0

" A list of ignored intervikis.
" Can be buffer-local.
TLet g:vikitasks_intervikis_ignored = []

" The viewer for the quickfix list. If empty, use |:TRagcw|.
TLet g:vikitasks_qfl_viewer = ''

" Item classes that should be included in the list when calling 
" |:VikiTasks|.
" A user-defined value must be set in |vimrc| before the plugin is 
" loaded.
TLet g:vikitasks_rx_letters = 'A-T'

" Item levels that should be included in the list when calling 
" |:VikiTasks|.
" A user-defined value must be set in |vimrc| before the plugin is 
" loaded.
TLet g:vikitasks_rx_levels = '1-5'

" Cache file name.
" By default, use |tlib#cache#Filename()| to determine the file name.
TLet g:vikitasks_cache = tlib#cache#Filename('vikitasks', 'files', 1)


function! s:VikitasksRx(letters, levels) "{{{3
    return '\C^[[:blank:]]\+\zs'.
                \ '#\(T: \+.\{-}'. a:letters .'.\{-}:\|'. 
                \ '['. a:levels .']\?['. a:letters .']['. a:levels .']\?'.
                \ '\( \+\(_\|['. a:levels .'%-]\+\)\)\?\)\( \+\[[^[].\{-}\]\)\? %s'
endf

exec 'TRagDefKind tasks viki /'. s:VikitasksRx('A-Z', '0-9') .'/'
exec 'TRagDefKind sometasks viki /'. s:VikitasksRx(g:vikitasks_rx_letters, g:vikitasks_rx_levels) .'/'

delf s:VikitasksRx


" :display: VikiTasks[!] [SELECT] [FILE_PATTERNS]
" SELECT items by date. Possible values for SELECT are: today, current, 
" NUMBER (of days). If SELECT is *, all items are elegible.
" Collect a list of tasks from a set of viki pages matching 
" FILE_PATTERNS.
" With the optional !, show all tasks not just those with a date
" The current buffer has to be a viki buffer. If it isn't, your 
" |g:vikiHomePage|, which must be set, is opened first.
"
" Examples:
"     Show all tasks with a date: >
"         VikiTasks
" <   Show all tasks: >
"         VikiTasks!
" <   Show all tasks for today: >
"         VikiTasks today
" <   Show all current tasks (today or with a deadline in the past) in a 
"     specified list of files: >
"         VikiTasks current Notes*.txt
command! -bang -nargs=* VikiTasks 
            \ call vikitasks#Tasks(!empty("<bang>"), {
            \   'tasks': 'sometasks', 
            \   'select': get([<f-args>], 0, '*'), 
            \   'files': [<f-args>][1:-1]
            \ })
cabbr vikitasks VikiTasks


" :display: :VikiTasksGrep[!] REGEXP [FILE PATTERNS]
" Like |:VikiTasks| but display only those items matching REGEXP.
" The |regexp| pattern is prepended with |\<| if it seems to be a word.
command! -bang -nargs=* VikiTasksGrep call vikitasks#TasksGrep(!empty("<bang>"), <f-args>)


" :display: :VikiTasksAdd
" Add the current buffer to |g:vikitasks_files|.
command! VikiTasksAdd call vikitasks#AddBuffer(expand('%:p'))


" :display: :VikiTasksFiles
" Edit |g:vikitasks_files|. This allows you to remove buffers from the 
" list.
command! VikiTasksFiles call vikitasks#EditFiles()


let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release

