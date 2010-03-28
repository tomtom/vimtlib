" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-12-13.
" @Last Change: 2010-03-28.
" @Revision:    175
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


" :display: VikiTasks[!] [CONSTRAINT] [PATTERN] [FILE_PATTERNS]
" Collect a list of tasks from a set of viki pages matching 
" FILE_PATTERNS.
"
" The optional |regexp| PATTERN argument is preprocesed by 
" |vikitasks#MakePattern()|.
" 
" CONSTRAINT defined which tasks should be displayed. Possible values 
" for CONSTRAINT are:
"
"   today            ... Show tasks that are due today
"   current          ... Show pending and today's tasks
"   NUMBER (of days) ... Show tasks that are due within N days
"   Nd               ... Tasks for the next N days
"   Nw               ... Tasks for the next N weeks
"   Nm               ... Tasks for the next N months
"   week             ... Tasks for the next week
"   month            ... Tasks for the next month
"   .                ... Show some tasks (see |g:vikitasks#rx_letters| 
"                        and |g:vikitasks#rx_levels|)
"   *                ... Show all tasks
"
" The default value for CONSTRAINT is ".".
"
" With the optional !, all files are rescanned. Otherwise cached 
" information is used.
"
" The current buffer has to be a viki buffer. If it isn't, your 
" |g:vikiHomePage|, which must be set, is opened first.
" Use a period "." for empty CONSTRAINT or PATTERN parameters.
"
" Examples:
"     Show all cached tasks with a date: >
"         VikiTasks
" <   Rescan files and show all tasks: >
"         VikiTasks!
" <   Show all cached tasks for today: >
"         VikiTasks today
" <   Show all current cached tasks (today or with a deadline in the 
" past) in a specified list of files: >
"         VikiTasks current Notes*.txt
command! -bang -nargs=* VikiTasks
            \ call vikitasks#Tasks({
            \   'cached': empty("<bang>"),
            \   'all_tasks': get([<f-args>], 0, '.') =~ '^[.*]$',
            \   'tasks': get([<f-args>], 0, '.') == '*' ? 'tasks' : 'sometasks',
            \   'select': get([<f-args>], 0, '.'),
            \   'rx': vikitasks#MakePattern(get([<f-args>], 1, '')),
            \   'files': [<f-args>][2:-1]
            \ })
cabbr vikitasks VikiTasks


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
- The arguments for :VikiTasks have changed

