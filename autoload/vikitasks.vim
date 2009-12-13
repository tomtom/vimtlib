" vikitasks.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-12-13.
" @Last Change: 2009-12-13.
" @Revision:    0.0.74

let s:save_cpo = &cpo
set cpo&vim


" :display: vikitasks#Tasks(?all_tasks=0, *files)
" If files is non-empty, use these files (glob patterns actually) 
" instead of those defined in |g:vikitasks_files|.
function! vikitasks#Tasks(...) "{{{3
    TVarArg ['all_tasks', 0]
    " TLogVAR all_tasks, a:0
    if a:0 > 1
        let files = map(range(2, a:0), 'a:{v:val}')
    else
        let files = copy(tlib#var#Get('vikitasks_files', 'bg', []))
        if g:vikitasks_intervikis
            call s:AddInterVikis(files)
        endif
        " TLogVAR files
    endif
    " TAssertType files, 'list'

    call map(files, 'glob(v:val)')
    let files = split(join(files, "\n"), '\n')
    if !empty(files)
        call trag#Grep('tasks', 1, files)

        let date_rx = '^\s*#[A-Z0-9]\+ \zs\d\+-\d\+-\d\+'
        let qfl = getqflist()
        if !all_tasks
            call filter(qfl, 'v:val.text =~ date_rx')
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

        let w = {}
        if i > 1
            let w.initial_index = i
        endif
        call trag#QuickList(w)
    else
        echom "VikiTasks: No task files"
    endif
endf


function! s:SortTasks(a, b) "{{{3
    let a = a:a.text
    let b = a:b.text
    let date_rx = '^\s*#[A-Z0-9]\+ \zs\d\+-\d\+-\d\+'
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
    for iv in viki#GetInterVikis()
        if index(g:vikitasks_intervikis_ignored, matchstr(iv, '^\u\+')) == -1
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
