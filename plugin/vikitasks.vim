" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-12-13.
" @Last Change: 2010-03-26.
" @Revision:    142
" GetLatestVimScripts: 0 0 :AutoInstall: vikitasks.vim
" Search for task lists and display them in a list


if !exists('g:loaded_tlib') || g:loaded_tlib < 37
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 37
        echoerr 'tlib >= 0.37 is required'
        finish
    endif
endif
if !exists('g:loaded_trag') || g:loaded_trag < 7
    runtime plugin/trag.vim
    if !exists('g:loaded_trag') || g:loaded_trag < 7
        echoerr 'trag >= 0.8 is required'
        finish
    endif
endif
if &cp || exists("loaded_vikitasks")
    finish
endif
let loaded_vikitasks = 2

let s:save_cpo = &cpo
set cpo&vim


" Show alarms on pending tasks.
" If 0, don't display alarms for pending tasks.
" If n > 0, display alarms for pending tasks or tasks with a deadline in n 
" days.
TLet g:vikitasks_alarms = !has('clientserver') || len(split(serverlist(), '\n')) == 1


" :display: VikiTasks[!] [SELECT] [PATTERN] [FILE_PATTERNS]
" SELECT items by date. Possible values for SELECT are: today, current, 
" NUMBER (of days). If SELECT is *, all items are elegible.
" Collect a list of tasks from a set of viki pages matching 
" FILE_PATTERNS.
" The optional |regexp| PATTERN argument is preprocesed by 
" |vikitasks#MakePattern()|.
" With the optional !, show all tasks not just those with a date
" The current buffer has to be a viki buffer. If it isn't, your 
" |g:vikiHomePage|, which must be set, is opened first.
" Use a period "." for empty SELECT or PATTERN parameters.
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
            \   'select': get([<f-args>], 0, '.'), 
            \   'rx': vikitasks#MakePattern(get([<f-args>], 1, '')), 
            \   'files': [<f-args>][2:-1]
            \ })
cabbr vikitasks VikiTasks


" " :display: :VikiTasksGrep[!] REGEXP [FILE PATTERNS]
" " Like |:VikiTasks| but display only those items matching REGEXP.
" " The optional PATTERN argument is preprocesed by 
" " |vikitasks#MakePattern()|.
" command! -bang -nargs=* VikiTasksGrep call vikitasks#TasksGrep(!empty("<bang>"), <f-args>)


" :display: :VikiTasksAdd
" Add the current buffer to |g:vikitasks#files|.
command! VikiTasksAdd call vikitasks#AddBuffer(expand('%:p'))


" :display: :VikiTasksFiles
" Edit |g:vikitasks#files|. This allows you to remove buffers from the 
" list.
command! VikiTasksFiles call vikitasks#EditFiles()


command! -count VikiTasksAlarms call vikitasks#Alarm(<count>)


augroup VikiTasks
    autocmd!
    autocmd VimEnter * if g:vikitasks_alarms | call vikitasks#Alarm() | endif
    autocmd BufWrite * if exists('b:vikiEnabled') && b:vikiEnabled | call vikitasks#ScanCurrentBuffer() | endif
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release

0.2
- :VikiTasks now takes a pattern as optional second argument. This 
change makes the :VikiTasksGrep command obsolete, which was removed.
- Moved the definition of some variables from plugin/vikitasks.vim to autoload/vikitasks.vim
- Scan buffers on save
- Require tlib 0.37

