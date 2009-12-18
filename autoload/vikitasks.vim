" vikitasks.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-12-13.
" @Last Change: 2009-12-18.
" @Revision:    0.0.183

let s:save_cpo = &cpo
set cpo&vim



" :display: vikitasks#Tasks(?all=0, ?{'files': [], 'select': '', 'rx': ''})
" If files is non-empty, use these files (glob patterns actually) 
" instead of those defined in |g:vikitasks_files|.
function! vikitasks#Tasks(...) "{{{3
    TVarArg ['all_tasks', 0], ['args', {}]
    " TLogVAR all_tasks, args

    if &filetype != 'viki' && !viki#HomePage()
        echoerr "VikiTasks: Not a viki buffer and cannot open the homepage"
        return
    endif

    " TLogVAR all_tasks, a:0
    let files = get(args, 'files', [])
    if empty(files)
        let files = s:MyFiles()
        " TLogVAR files
    endif
    " TAssertType files, 'list'

    call map(files, 'glob(v:val)')
    let files = split(join(files, "\n"), '\n')
    if !empty(files)
        let tasks = get(args, 'tasks', 'tasks')
        " TLogVAR tasks
        call trag#Grep(tasks, 1, files)

        let date_rx = '\C^\s*#[A-Z0-9]\+ \zs\d\+-\d\+-\d\+'
        " TLogVAR date_rx
        let qfl = getqflist()
        " TLogVAR qfl
        " TLogVAR filter(copy(qfl), 'v:val.text =~ "#D7"')
        if !all_tasks
            call filter(qfl, 'v:val.text =~ date_rx')
            " TLogVAR len(qfl)
            let select = get(args, 'select', '*')
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
                call filter(qfl, 's:Select(v:val.text, date_rx, from, to)')
            endif
        endif

        let rx = get(args, 'rx', [])
        if !empty(rx)
            call filter(qfl, 'v:val.text =~ rx')
        endif

        call sort(qfl, "s:SortTasks")
        " let last = {}
        " let qflu = []
        " for qi in qfl
        "     if last != qi
        "         call add(qflu, qi)
        "         let last = qi
        "     endif
        " endfor
        " call setqflist(qflu)
        call setqflist(qfl)

        let i = 1
        let today = strftime('%Y-%m-%d')
        for qi in qfl
            let qid = matchstr(qi.text, date_rx)
            if qid && qid < today
                let i += 1
            else
                break
            endif
        endfor

        if empty(g:vikitasks_qfl_viewer)
            let w = {}
            if i > 1
                let w.initial_index = i
            endif
            call trag#QuickList(w)
        else
            exec g:vikitasks_qfl_viewer
        endif

    else
        echom "VikiTasks: No task files"
    endif
endf


" :display: vikitasks#TasksGrep(all_tasks, ?pattern='.', *files)
function! vikitasks#TasksGrep(all_tasks, ...) "{{{3
    TVarArg ['pattern', '']
    if a:0 > 2
        let args = map(range(2, a:0), 'a:{v:val}')
    else
        let args = []
    endif
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
    " TLogVAR a:all_tasks, a:pattern, pattern, files
    call vikitasks#Tasks(a:all_tasks, {
                \ 'rx': pattern,
                \ 'select': '*',
                \ 'files': args
                \ })
endf


function! s:SortTasks(a, b) "{{{3
    let a = a:a.text
    let b = a:b.text
    let date_rx = '\C^\s*#[A-Z0-9]\+ \zs\d\+-\d\+-\d\+'
    let ad = matchstr(a, date_rx)
    let bd = matchstr(b, date_rx)
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
        let s:files = get(tlib#cache#Get(g:vikitasks_cache), 'files', [])
    endif
    return s:files
endf


function! s:SaveInfo() "{{{3
    call tlib#cache#Save(g:vikitasks_cache, {'files': s:files})
endf


function! s:MyFiles() "{{{3
    let files = copy(tlib#var#Get('vikitasks_files', 'bg', []))
    let files += s:Files()
    if tlib#var#Get('vikitasks_intervikis', 'bg', 0)
        call s:AddInterVikis(files)
    endif
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


function! vikitasks#AddBuffer(buffer) "{{{3
    let fname = fnamemodify(a:buffer, ':p')
    if filereadable(fname) && index(g:vikitasks_files, fname) == -1
        call add(s:Files(), fname)
        call s:SaveInfo()
    endif
endf


function! vikitasks#EditFiles() "{{{3
    let files = tlib#input#EditList('Edit task files:', s:Files())
    if files != s:files
        let s:files = files
        call s:SaveInfo()
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
