" vikitasks.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-12-13.
" @Last Change: 2009-12-13.
" @Revision:    0.0.99

let s:save_cpo = &cpo
set cpo&vim


" :display: vikitasks#Tasks(?all_tasks=0, ?{"files": []})
" If files is non-empty, use these files (glob patterns actually) 
" instead of those defined in |g:vikitasks_files|.
function! vikitasks#Tasks(...) "{{{3
    TVarArg ['all_tasks', 0], ['args', {}]

    if &filetype != 'viki' && !viki#HomePage()
        echoerr "VikiTasks: Not a viki buffer and cannot open the homepage"
        return
    endif

    " TLogVAR all_tasks, a:0
    let files = get(args, 'files', [])
    if empty(files)
        let files = copy(tlib#var#Get('vikitasks_files', 'bg', []))
        if tlib#var#Get('vikitasks_intervikis', 'bg', 0)
            call s:AddInterVikis(files)
        endif
        " TLogVAR files
    endif
    " TAssertType files, 'list'

    call map(files, 'glob(v:val)')
    let files = split(join(files, "\n"), '\n')
    if !empty(files)
        call trag#Grep('tasks', 1, files)

        let date_rx = '\C^\s*#['. g:vikitasks_rx_letters . g:vikitasks_rx_levels .']\+ \zs\d\+-\d\+-\d\+'
        " TLogVAR date_rx
        let qfl = getqflist()
        if !all_tasks
            call filter(qfl, 'v:val.text =~ date_rx')
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


function! vikitasks#TasksGrep(all_tasks, pattern, ...) "{{{3
    if a:0 > 0
        let files = map(range(1, a:0), 'a:{v:val}')
    else
        let files = []
    endif
    " let pattern = '\v'. a:pattern
    let pattern = a:pattern
    " TLogVAR a:all_tasks, a:pattern, pattern, files
    call vikitasks#Tasks(a:all_tasks, {'rx': pattern, 'files': files})
endf


function! s:SortTasks(a, b) "{{{3
    let a = a:a.text
    let b = a:b.text
    " let date_rx = '\C^\s*#['. g:vikitasks_rx_letters . g:vikitasks_rx_levels .']\+ \zs\d\+-\d\+-\d\+'
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


let &cpo = s:save_cpo
unlet s:save_cpo