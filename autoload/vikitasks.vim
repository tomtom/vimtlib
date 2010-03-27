" vikitasks.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-12-13.
" @Last Change: 2010-03-27.
" @Revision:    0.0.444

let s:save_cpo = &cpo
set cpo&vim
" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


" A list of glob patterns (or files) that will be searched for task 
" lists.
" Can be buffer-local.
" If you add ! to 'viminfo', this variable will be automatically saved 
" between editing sessions.
" Alternatively, add new items in ~/vimfiles/after/plugin/vikitasks.vim
TLet g:vikitasks#files = []

" If non-null, automatically add the homepages of your intervikis to 
" |g:vikitasks#files|.
" Can be buffer-local.
TLet g:vikitasks#intervikis = 0

" A list of ignored intervikis.
" Can be buffer-local.
TLet g:vikitasks#intervikis_ignored = []

" The viewer for the quickfix list. If empty, use |:TRagcw|.
TLet g:vikitasks#qfl_viewer = ''

" Item classes that should be included in the list when calling 
" |:VikiTasks|.
" A user-defined value must be set in |vimrc| before the plugin is 
" loaded.
TLet g:vikitasks#rx_letters = 'A-T'

" Item levels that should be included in the list when calling 
" |:VikiTasks|.
" A user-defined value must be set in |vimrc| before the plugin is 
" loaded.
TLet g:vikitasks#rx_levels = '1-5'

" Cache file name.
" By default, use |tlib#cache#Filename()| to determine the file name.
TLet g:vikitasks#cache = tlib#cache#Filename('vikitasks', 'files', 1)


function! s:VikitasksRx(inline, sometasks, letters, levels) "{{{3
    let val = '\C^[[:blank:]]'. (a:inline ? '*' : '\+') .'\zs'.
                \ '#\(T: \+.\{-}'. a:letters .'.\{-}:\|'. 
                \ '['. a:levels .']\?['. a:letters .']['. a:levels .']\?'.
                \ '\( \+\(_\|[0-9%-]\+\)\)\?\) %s'
    return val
endf

let s:sometasks_rx = s:VikitasksRx(1, 1, g:vikitasks#rx_letters, g:vikitasks#rx_levels)
let s:tasks_rx = s:VikitasksRx(0, 0, 'A-Z', '0-9')
exec 'TRagDefKind tasks viki /'. s:tasks_rx .'/'

delf s:VikitasksRx


let s:date_rx = '\C^\s*#[A-Z0-9]\+ \zs\d\+-\d\+-\d\+'


" :display: vikitasks#Tasks(?{'all_tasks': 0, 'cached': 1, 'files': [], 'select': '', 'rx': ''})
" If files is non-empty, use these files (glob patterns actually) 
" instead of those defined in |g:vikitasks#files|.
function! vikitasks#Tasks(...) "{{{3
    TVarArg ['args', {}]

    if get(args, 'cached', 1)

        let qfl = copy(s:Tasks())
        call s:TasksList(qfl, args)

    else

        if &filetype != 'viki' && !viki#HomePage()
            echoerr "VikiTasks: Not a viki buffer and cannot open the homepage"
            return
        endif

        " TLogVAR args
        let files = get(args, 'files', [])
        if empty(files)
            let files = s:MyFiles()
            " TLogVAR files
        endif
        " TAssertType files, 'list'

        call map(files, 'glob(v:val)')
        let files = split(join(files, "\n"), '\n')
        " TLogVAR files
        if !empty(files)
            let qfl = trag#Grep('tasks', 1, files)
            " TLogVAR qfl
            " TLogVAR filter(copy(qfl), 'v:val.text =~ "#D7"')

            " TLogVAR qfl
            let tasks = copy(qfl)
            for i in range(len(tasks))
                call remove(tasks[i], 'bufnr')
            endfor
            call s:SaveInfo(s:Files(), tasks)

            call s:TasksList(qfl, args)
        else
            echom "VikiTasks: No task files"
        endif

    endif
endf


function! s:TasksList(qfl, args) "{{{3
    call s:FilterTasks(a:qfl, a:args)
    call sort(a:qfl, "s:SortTasks")
    call setqflist(a:qfl)
    let i = s:GetCurrentTask(a:qfl, 0)
    call s:View(i, 0)
endf


function! s:FilterTasks(tasks, args) "{{{3
    " TLogVAR a:args

    let rx = get(a:args, 'rx', '')
    if !empty(rx)
        call filter(a:tasks, 'v:val.text =~ rx')
    endif

    let which_tasks = get(a:args, 'tasks', 'tasks')
    " TLogVAR which_tasks
    if which_tasks == 'sometasks'
        let rx = s:TasksRx('sometasks')
        " TLogVAR rx
        " TLogVAR len(a:tasks)
        call filter(a:tasks, 'v:val.text =~ rx')
        " TLogVAR len(a:tasks)
    endif

    if !get(a:args, 'all_tasks', 0)
        call filter(a:tasks, 'v:val.text =~ s:date_rx')
        " TLogVAR len(a:tasks)
        let select = get(a:args, 'select', '.')
        " TLogVAR select
        let from = 0
        let to = 0
        if select =~ '^t\%[oday]'
            let from = localtime()
            let to = from
        elseif select =~ '^c\%[urrent]'
            let to = localtime()
        elseif select =~ '^\d\+$'
            let from = localtime()
            let to = from + select * 86400
        endif
        " TLogVAR from, to
        if from != 0 || to != 0
            call filter(a:tasks, 's:Select(v:val.text, s:date_rx, from, to)')
        endif
    endif
endf


function! s:View(index, suspend) "{{{3
    if empty(g:vikitasks#qfl_viewer)
        let w = {}
        if a:index > 1
            let w.initial_index = a:index
        endif
        let w.trag_list_syntax = 'viki'
        let w.trag_list_syntax_nextgroup = '@vikiPriorityListTodo'
        let w.trag_short_filename = 1
        call trag#QuickList(w, a:suspend)
    else
        exec g:vikitasks#qfl_viewer
    endif
endf


" The |regexp| PATTERN is prepended with |\<| if it seems to be a word. 
" The PATTERN is made case sensitive if it contains an upper-case letter 
" and if 'smartcase' is true.
function! vikitasks#MakePattern(pattern) "{{{3
    let pattern = a:pattern
    if empty(pattern)
        let pattern = '.'
    else
        if pattern =~ '^\w'
            let pattern = '\<'. pattern
        endif
        if &smartcase && pattern =~ '\u'
            let pattern = '\C'. pattern
        endif
    endif
    return pattern
endf


function! s:GetCurrentTask(qfl, daysdiff) "{{{3
    " TLogVAR a:daysdiff
    let i = 1
    let today = strftime('%Y-%m-%d')
    for qi in a:qfl
        let qid = matchstr(qi.text, s:date_rx)
        " TLogVAR qid
        if qid && (a:daysdiff == 0 ? qid < today : tlib#date#DiffInDays(qid, today) <= a:daysdiff)
            let i += 1
        else
            break
        endif
    endfor
    return i
endf


function! s:SortTasks(a, b) "{{{3
    let a = a:a.text
    let b = a:b.text
    let ad = matchstr(a, s:date_rx)
    let bd = matchstr(b, s:date_rx)
    if ad && !bd
        return -1
    elseif !ad && bd
        return 1
    elseif ad && bd && ad != bd
        return ad > bd ? 1 : -1
    else
        return a == b ? 0 : a > b ? 1 : -1
    endif
endf


function! s:Files() "{{{3
    if !exists('s:files')
        let s:files = get(tlib#cache#Get(g:vikitasks#cache), 'files', [])
        if !has('fname_case') || !&shellslash
            call map(s:files, 's:CanonicFilename(v:val)')
        endif
        " echom "DBG nfiles = ". len(s:files)
    endif
    return s:files
endf


function! s:Tasks() "{{{3
    if !exists('s:tasks')
        let s:tasks = get(tlib#cache#Get(g:vikitasks#cache), 'tasks', [])
        " echom "DBG ntasks = ". len(s:tasks)
    endif
    return s:tasks
endf


function! s:SaveInfo(files, tasks) "{{{3
    " TLogVAR len(a:files), len(a:tasks)
    let s:files = a:files
    let s:tasks = a:tasks
    call tlib#cache#Save(g:vikitasks#cache, {'files': a:files, 'tasks': a:tasks})
endf


function! s:CanonicFilename(filename) "{{{3
    let filename = a:filename
    if !has('fname_case')
        let filename = tolower(filename)
    endif
    if !&shellslash
        let filename = substitute(filename, '\\', '/', 'g')
    endif
    return filename
endf


function! s:MyFiles() "{{{3
    let files = copy(tlib#var#Get('vikitasks_files', 'bg', []))
    let files += s:Files()
    if tlib#var#Get('vikitasks_intervikis', 'bg', 0)
        call s:AddInterVikis(files)
    endif
    if !has('fname_case') || !&shellslash
        call map(files, 's:CanonicFilename(v:val)')
    endif
    let files = tlib#list#Uniq(files)
    " TLogVAR files
    return files
endf


function! s:AddInterVikis(files) "{{{3
    " TLogVAR a:files
    let ivignored = tlib#var#Get('vikitasks_intervikis_ignored', 'bg', [])
    for iv in viki#GetInterVikis()
        if index(ivignored, matchstr(iv, '^\u\+')) == -1
            " TLogVAR iv
            let def = viki#GetLink(1, '[['. iv .']]', 0, '')
            " TLogVAR def
            let hp = def[1]
            " TLogVAR hp, filereadable(hp), !isdirectory(hp), index(a:files, hp) == -1
            if filereadable(hp) && !isdirectory(hp) && index(a:files, hp) == -1
                call add(a:files, hp)
            endif
        endif
    endfor
endf


function! s:Select(text, date_rx, from, to) "{{{3
    let date = matchstr(a:text, a:date_rx)
    let sfrom = strftime('%Y-%m-%d', a:from)
    let sto = strftime('%Y-%m-%d', a:to)
    " TLogVAR date, sfrom, sto
    return date >= sfrom && date <= sto
endf


function! vikitasks#AddBuffer(buffer, ...) "{{{3
    TVarArg ['save', 1]
    " TLogVAR a:buffer, save
    let fname = s:CanonicFilename(fnamemodify(a:buffer, ':p'))
    let files = s:Files()
    if filereadable(fname) && index(files, fname) == -1
        call add(files, fname)
        if save
            call s:SaveInfo(files, s:Tasks())
        endif
    endif
endf


function! vikitasks#EditFiles() "{{{3
    let files = tlib#input#EditList('Edit task files:', sort(copy(s:Files())))
    if files != s:files
        call s:SaveInfo(files, s:Tasks())
    endif
endf


function! vikitasks#Alarm(...) "{{{3
    TVarArg ['ddays', g:vikitasks_alarms - 1]
    " TLogVAR ddays
    if ddays < 0
        return
    endif
    let tasks = s:Tasks()
    call sort(tasks, "s:SortTasks")
    " TLogVAR tasks
    " TLogVAR len(tasks)
    " let i = s:GetCurrentTask(tasks, ddays) - 2
    let i = s:GetCurrentTask(tasks, ddays) - 1
    " TLogVAR i
    if i > 0
        let subtasks = tasks[0 : i]
        call s:FilterTasks(subtasks, {'all_tasks': 0, 'tasks': 'sometasks'})
        " TLogVAR subtasks
        call setqflist(subtasks)
        call s:View(0, 1)
        redraw
        " call tlib#scratch#UseScratch()
        " for j in range(i, 0, -1)
        "     call append(0, ' '. tasks[j].text)
        " endfor
        " exec 'resize '. line('$')
        " setlocal ft=viki
        " setlocal nowrap
        " 1
    endif
endf


function! s:TasksRx(which_tasks) "{{{3
    return printf(s:{a:which_tasks}_rx, '.*')
endf


function! vikitasks#ScanCurrentBuffer() "{{{3
    let tasks = s:Tasks()
    let filename = s:CanonicFilename(fnamemodify(bufname('%'), ':p'))
    let ntasks = len(tasks)
    let tasks = []
    let buftasks = {}
    for task in s:Tasks()
	" TLogVAR task
        if s:CanonicFilename(task.filename) == filename
            " TLogVAR task.lnum, task
            if has_key(task, 'text')
                let buftasks[task.lnum] = task
            endif
        else
            call add(tasks, task)
        endif
	unlet task
    endfor
    " TLogVAR len(tasks)
    let rx = s:TasksRx('tasks')
    let @r = rx
    let update = 0
    let lnum = 1
    " echom "DBG ". string(keys(buftasks))
    for line in getline(1, '$')
        let text = tlib#string#Strip(line)
        if line =~ rx
            if get(get(buftasks, lnum, {}), 'text', '') != text
                " TLogVAR lnum
                " echom "DBG ". get(buftasks,lnum,'')
                let update = 1
                " TLogVAR lnum, text
                call add(tasks, {
                            \ 'filename': filename,
                            \ 'lnum': lnum,
                            \ 'text': text
                            \ })
            else
                call add(tasks, buftasks[lnum])
            endif
        endif
        let lnum += 1
    endfor
    " TLogVAR len(tasks)
    if update
        " TLogVAR update
        call vikitasks#AddBuffer(filename, 0)
        call s:SaveInfo(s:Files(), tasks)
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
