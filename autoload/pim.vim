" pim.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-03.
" @Last Change: 2009-02-15.
" @Revision:    0.1.38
" GetLatestVimScripts: 0 0 :AutoInstall: pim.vim

if &cp || exists("loaded_pim_autoload")
    finish
endif
let loaded_pim_autoload = 1

let s:pimNoclass     = fnamemodify(g:pimHome, ':h:t')
let s:lastdate       = ''

" pim#ExtractField(field, ?default='', ?start=0)
function! pim#ExtractField(field, ...) "{{{3
    let default = a:0 >= 1 ? a:1 : ''
    if a:0 >= 2
        let start = a:2
        if start >= line('$')
            return default
        endif
        let pos   = []
    else
        let start = 0
        let pos   = getpos(".")
    endif
    let rv = default
    let g:pimExtractline = 0
    " if start >= 0 && start != line('.')
    if start >= 0
        " exec (start - 1)
        exec start
    endif
    " norm! $
    if search('^\s\+'. a:field .'\s\+::\s', 'W')
        let g:pimExtractline = line('.')
        let l  = getline('.')
        let rv = matchstr(l, '\s::\s\+\zs.*$')
    endif
    if !empty(pos)
        call setpos('.', pos)
    endif
    if rv =~ '^<+.\{-}+>$'
        return default
    else
        return rv
    endif
endf

function! pim#DeleteIndexEntries(type, class, name) "{{{3
    if a:type == ''
        call pim#DeleteIndexEntries('D', a:class, a:name)
        call pim#DeleteIndexEntries('T', a:class, a:name)
    else
        let entries = pim#GlobIndex(a:type, a:class, '', pim#CleanName(a:name))
        call map(entries, 'pim#DeleteIndexEntry(v:val)')
    endif
endf

function! pim#DeleteIndexEntry(fname) "{{{3
    call delete(a:fname)
endf

function! pim#SaveDate(name, class, date, ...) "{{{3
    if a:name != '' && a:date != ''
        let ddiff = pim#DiffInDays(a:date)
        if ddiff > g:pimDaysFuture || ddiff < -g:pimDaysPast
            return
        endif
        let tstart   = a:0 >= 1 ? a:1 : ''
        let tend     = a:0 >= 2 ? a:2 : ''
        let vikiname = pim#CleanVikiName(a:class, a:name)
        let fname    = pim#MakeFileName('D', a:class, a:date, a:name)
        if tstart != ''
            let time = PimCanonicTime(tstart)
            let text = pim#MakeDateEntry(vikiname, time)
            if tend != ''
                let hstart = matchstr(tstart, '^\d\+\ze')
                let hend   = matchstr(tend, '^\d\+\ze:')
                let d = hend - hstart
                let i = 0
                while i <= d
                    let text = text."\n".pim#MakeDateEntry(vikiname, PimCanonicTime(tstart, i))
                    let i = i + 1
                endwh
            endif
        else
            let text = pim#MakeDateEntry(vikiname, '     ')
        endif
        call pim#SaveIndex(a:name, fname, text)
    else
        echoerr 'PIM: No Name or date:'. a:name
    endif
endf

function! pim#DiffInDays(date, ...)
    let s0 = pim#SecondsSince1970(a:date)
    let s1 = a:0 >= 1 ? pim#SecondsSince1970(a:1) : localtime()
    return (s0 - s1) / g:pimDayshift
endf

" pim#SecondsSince1970(date, ?daysshift=0)
function! pim#SecondsSince1970(date, ...) "{{{3
    let year  = matchstr(a:date, '^\(\d\+\)\ze-\(\d\+\)-\(\d\+\)$')
    let month = matchstr(a:date, '^\(\d\+\)-\zs\(\d\+\)\ze-\(\d\+\)$')
    let days  = matchstr(a:date, '^\(\d\+\)-\(\d\+\)-\zs\(\d\+\)$')
    if year == '' || month == '' || days == '' || 
                \ month < 1 || month > 12 || days < 1 || days > 31
        echoerr 'PIM: Invalid date: '. a:date
        return 0
    endif
    if strlen(year) == 2
        let year = g:pimShortDatePrefix . year
    endif
    if a:0 >= 1 && a:1 > 0
        let days = days + a:1
    end
    let days_passed = days
    let i = 1970
    while i < year
        let days_passed = days_passed + 365
        if i % 4 == 0 || i == 2000
            let days_passed = days_passed + 1
        endif
        let i = i + 1
    endwh
    let i = 1
    while i < month
        if i == 1
            let days_passed = days_passed + 31
        elseif i == 2
            let days_passed = days_passed + 28
            if year % 4 == 0 || year == 2000
                let days_passed = days_passed + 1
            endif
        elseif i == 3
            let days_passed = days_passed + 31
        elseif i == 4
            let days_passed = days_passed + 30
        elseif i == 5
            let days_passed = days_passed + 31
        elseif i == 6
            let days_passed = days_passed + 30
        elseif i == 7
            let days_passed = days_passed + 31
        elseif i == 8
            let days_passed = days_passed + 31
        elseif i == 9
            let days_passed = days_passed + 30
        elseif i == 10
            let days_passed = days_passed + 31
        elseif i == 11
            let days_passed = days_passed + 30
        endif
        let i = i + 1
    endwh
    let seconds = (days_passed - 1) * 24 * 60 * 60
    let seconds = seconds + (strftime('%H') + g:pimTimeZoneShift) * 60 * 60
    let seconds = seconds + strftime('%M') * 60
    let seconds = seconds + strftime('%S')
    return seconds
endf

function! pim#CleanVikiName(iviki, name) "{{{3
    let name = pim#CleanName(a:name)
    return VikiMakeName(a:iviki, name)
endf

function! pim#CleanName(name) "{{{3
    let name = substitute(a:name, '[\]\[:*/&?<>|\"]', '_', 'g')
    if g:pimNameLength > 0 && strlen(name) > g:pimNameLength
        if g:pimWarnings =~# 'l'
            echom 'PIM: Name too long:'. name
            echom 'PIM: Only first '. g:pimNameLength .' chars are significant.'
        endif
        let name = strpart(name, 0, g:pimNameLength)
    endif
    return name
endf

function! pim#CleanFilename(fname) "{{{3
    let cd = fnamemodify(a:fname, ':p:h').'/'
    let cf = pim#CleanName(fnamemodify(a:fname, ':t'))
    return cd.cf
endf

" pim#GlobIndex(type, ?class, ?info, ?name)
function! pim#GlobIndex(type, ...) "{{{3
    let class = a:0 >= 1 && a:1 != '' ? a:1 : '*'
    let info  = a:0 >= 2 && a:2 != '' ? a:2 : '*'
    let name  = a:0 >= 3 && a:3 != '' ? a:3 : '*'
    let pat   = a:type . class .' '. info .'$'. name
    let rv    = glob(g:pimIndex . pat)
    return split(rv, '\n')
endf

function! pim#GlobDB(class, ...) "{{{3
    exec tlib#arg#Let([['pattern', '*']])
    let ls = globpath(g:vikiInter{a:class}, pattern . g:pimFileSuffix)
    return split(ls, '\n')
endf


function! pim#MakeDateEntry(vikiname, time) "{{{3
    " return '  '. a:time .' :: '. a:text
    let t = escape(a:time, '"\')
    let v = escape(a:vikiname, '"\')
    return 'let d_time = "'. t .'" | let d_ref ="'. v .'"'
endf

function! pim#MakeTaskEntry(vikiname, category, priority, due) "{{{3
    " return '  #'. a:category . a:priority .' '. a:due .' '. a:vikiname
    let vikiname = escape(a:vikiname, '"\')
    let category = escape(a:category, '"\')
    let priority = escape(a:priority, '"\')
    let due      = escape(a:due, '"\')
    return 'let t_cat="'. category 
                \ .'" | let t_pri="'. priority
                \ .'" | let t_due="'. due
                \ .'" | let t_ref="'. vikiname .'"'
endf

function! pim#MakeDisplayEntryT(text)
    " <+TODO+> Option: select which entries should be displayed
    exec a:text
    return '  #'. t_cat . t_pri .' '. t_due .' '. t_ref
endf

function! pim#MakeDisplayEntryD(text)
    " <+TODO+> Option: select which entries should be displayed
    exec a:text
    return '  '. d_time .' :: '. d_ref
endf

function! pim#MakeFileName(type, class, info, name) "{{{3
    return a:type . a:class .' '. a:info .'$'. pim#CleanName(a:name)
endf

function! pim#SaveIndex(name, fname, text) "{{{3
    split
    let t = @t
    let v = g:vikiEnabled
    let b = &backup
    let p = &patchmode
    try
        let g:vikiEnabled = 0
        set nobackup
        set patchmode=
        exec 'edit! '. g:pimIndex.a:fname
        let @t = a:text
        norm! ggdG"tp
        update
    finally
        let g:vikiEnabled = v
        let @t = t
        let &backup = b
        let &patchmode = p
        bdelete!
    endtry
endf


function! pim#StartEndTime(line, tstart, tend, tdur) "{{{3
    " echom "DBG StartEndTime 0: ". a:line .": ". a:tstart
    let tstart = pim#ExtractField('Time', a:tstart, a:line)
    " echom "DBG StartEndTime 1: ". tstart
    if tstart != ''
        let rv   = 'let tstart="'. tstart .'"'
        let tend = pim#ExtractField('End time', a:tend, a:line)
        if tend == ''
            let tdur = pim#ExtractField('Duration', a:tdur, a:line)
            if tdur != ''
                let tend = PimCanonicTime(tstart, tdur)
            endif
        endif
        if tend != ''
            let rv = rv.'| let tend="'. tend .'"'
        endif
        return rv
    else
        return ''
    endif
endf

function! pim#StartEndTimeCleanUp(tstart, tend, tdur)
    let rv = 'let tstart="'. a:tstart .'" | let tdur ="'. a:tdur .'"'
    if a:tdur != ''
        let rv = rv.'| let tend=""'
    else
        let rv = rv.'| let tend="'. a:tend .'"'
    endif
    return rv
endf


" pim#NewFile(?file='', ?class='')
function! pim#NewFile(...) "{{{3
    " let f = a:0 >= 1 && a:1 != '' ? a:1 : expand("<afile>")
    let f = a:0 >= 1 && a:1 != '' ? a:1 : expand("%:p")
    let c = a:0 >= 2 && a:2 != '' ? a:2 : s:GetClass(f)
    if c == '' || !s:IsValidClass(c)
        return
    endif
    let f = pim#CleanFilename(f)
    if filereadable(f)
        exec 'edit '. f
    else
        let tpl = g:pimTemplates . c .g:pimFileSuffix
        " <+TODO+> keep alternate file etc.
        if filereadable(tpl)
            let ea = g:pimExecAC
            try
                let g:pimExecAC = 0
                exec 'edit '. f
                exec '0read '. tpl
                call s:FillInTemplate()
            finally
                let g:pimExecAC = ea
            endtry
        else
            echoerr 'PIM: Missing template: '. tpl
            return
        endif
    endif
    call pim#EditFile(f, c)
endf

function! s:FillInTemplate() "{{{3
    call s:SubstituteArgs(
                \ 'ID', expand('%:t:r'),
                \ 'TODAY', strftime('%Y-%m-%d')
                \ )
endf

function! s:SubstituteArgs(...) "{{{3
    for i in range(1, a:0, 2)
        let j = i + 1
        let lab = a:{i}
        let val = a:{j}
        exec '%s/\V<+'. lab .'+>/'. escape(val, '&\/') .'/ge'
    endfor
endf

" pim#EditFile(?file='', ?class='')
function! pim#EditFile(...) "{{{3
    " let f = a:0 >= 1 && a:1 != '' ? a:1 : expand("<afile>")
    let f = a:0 >= 1 && a:1 != '' ? a:1 : expand("%:p")
    let f = pim#CleanFilename(f)
    let c = a:0 >= 2 && a:2 != '' ? a:2 : s:GetClass(f)
    if c != ''
        call pim#Viki()
        call pim#SetBufferMaps()
    endif
endf

function! pim#Viki() "{{{3
    let b:vikiLowerCharacters = 'a-z_'
    set ft=viki
endf

" pim#UpdateIndex(?file='', ?class='')
function! pim#UpdateIndex(...) "{{{3
    " let f = a:0 >= 1 && a:1 != '' ? a:1 : expand("<afile>")
    let f = a:0 >= 1 && a:1 != '' ? a:1 : expand("%:p")
    let c = a:0 >= 2 && a:2 != '' ? a:2 : s:GetClass(f)
    if c != '' && exists("*PimUpdateIndex_". c)
        let f = pim#CleanFilename(f)
        call PimUpdateIndex_{c}(f)
    endif
endf

function! pim#SaveTask(name, class, category, priority, due) "{{{3
    if a:name != ''
        let vikiname = pim#CleanVikiName(a:class, a:name)
        let finfo    = a:category.a:priority.' '.a:due
        let fname    = pim#MakeFileName('T', a:class, finfo, a:name)
        let text     = pim#MakeTaskEntry(vikiname, a:category, a:priority, a:due)
        call pim#SaveIndex(a:name, fname, text)
        if a:due =~ '\d'
            let date = PimCanonicDate(a:due)
            call pim#SaveDate(a:name, a:class, date)
        endif
    else
        echoerr 'PIM: No Name:'. a:name
    endif
endf

function! s:SplitFileName(fname) "{{{3
    let fn = fnamemodify(a:fname, ':t')
    let rx = '^\([A-Z]\)\([A-Z]*\) \([^\$]*\)\$\(.*\)$'
    let m1 = escape(substitute(fn, rx, '\1', ''), '"')
    let m2 = escape(substitute(fn, rx, '\2', ''), '"')
    let m3 = escape(substitute(fn, rx, '\3', ''), '"')
    let m4 = escape(substitute(fn, rx, '\4', ''), '"')
    return 'let m_type="'.m1.'"|let m_class="'.m2.'"|let m_info="'.m3.'"|let m_name="'.m4.'"'
endf

" s:GetClass(?file='')
function! s:GetClass(...) "{{{3
    " let f = a:0 >= 1 && a:1 != '' ? a:1 : expand("<afile>")
    let f = a:0 >= 1 && a:1 != '' ? a:1 : expand("%:p")
    " TLogVAR f
    " let f = s:CanonicFilename(f)
    let c = toupper(fnamemodify(f, ':p:h:t'))
    if s:IsValidClass(c)
        return c
    else
        echoerr 'PIM: Unknown class: '. c .' ('. f .')'
        return ''
        " return 'Free'
    endif
endf

function! pim#Today(bang, date) "{{{3
    call s:Split()
    call pim#BuildOverview(0, 'Today', a:bang, a:date)
endf

function! pim#Week(bang, date) "{{{3
    call s:Split()
    call pim#BuildOverview(7, 'Week', a:bang, a:date)
endf

function! pim#Month(bang, date) "{{{3
    call s:Split()
    call pim#BuildOverview(31, 'Month', a:bang, a:date)
endf

function! s:Split() "{{{3
    exec tlib#var#Get('pimSplit', 'bg')
endf

" pim#BuildOverview(days, ?file=%, ?bang='', ?date='')
function! pim#BuildOverview(days, ...) "{{{3
    let explicit = a:0 >= 1 && a:1 != ''
    let fname    = explicit ? a:1 : expand("%")
    let anyway   = a:0 >= 2 ? (a:2 == '!') : 0
    if a:0 >= 3 && a:3 != ''
        let tstamp  = pim#SecondsSince1970(a:3)
        let fname   = a:3
        let scratch = 1
    else
        let tstamp  = localtime()
        let scratch = 0
    endif
    let fname   = g:pimHome.fname.g:pimFileSuffix
    let modtime = getftime(fname)
    if explicit
        exec 'edit '. fname
        if scratch
            setlocal buftype=nofile
            setlocal bufhidden=hide
            setlocal noswapfile
            setlocal nobuflisted
            " setlocal indentkeys=
            " setlocal indentexpr=
            " setlocal nosmartindent
        endif
        let b:tortoiseSvnIgnore = 1
    endif
    if anyway || modtime == -1 || (tstamp - modtime) / 60 > g:pimOutdated
        " setlocal modifiable
        let t = @t
        try
            let dayd = 0
            exec "norm! ggdGi* Overview for ". strftime('%Y-%m-%d', tstamp)
            if a:days != 0
                exec "norm! gg$a -- ". a:days ." day(s)"
            endif
            norm! Go
            norm! Gi% This file was automatically generated. Do not edit.
            norm! Go
            norm! Gi** Dates
            " call s:InsertCalender(tstamp, a:days)
            let s:lastdate = ''
            let s:dates0   = line('$') + 1
            while dayd <= a:days
                let today = strftime('%Y-%m-%d', tstamp)
                let dates = pim#GlobIndex('D', '', today)
                call map(dates, 's:InsertEntry("D", v:val, a:days)')
                if exists(':PimSortDates')
                    if s:dates0 < line('$')
                        exec s:dates0.',$PimSortDates'
                    endif
                endif
                let tstamp = tstamp + g:pimDayshift
                let dayd   = dayd + 1
            endwh
            norm! Go
            norm! Go
            norm! Gi** Tasks
            let tasks0 = line('$') + 1
            let tasks  = pim#GlobIndex('T')
            call map(tasks, 's:InsertEntry("T", v:val)')
            if exists(':PimSortTasks')
                if tasks0 < line('$')
                    exec tasks0.',$PimSortTasks'
                endif
            endif
            norm! Go
            norm! gg
            " <+TODO+> additional markup, special filetype
            if explicit && !scratch
                write
            endif
        finally
            " setlocal nomodifiable
            let @t = t
        endtry
    endif
endf

" s:InsertEntry(class, fname, ?days=1)
function! s:InsertEntry(class, fname, ...) "{{{3
    if filereadable(a:fname)
        if a:0 >= 1 && a:1 > 1
            exec s:SplitFileName(a:fname)
            if m_info != s:lastdate
                let ts = pim#SecondsSince1970(m_info)
                let ft = strftime('%Y-%m-%d %A', ts)
                exec "norm! Go\<Home>*** ". ft
                " exec "norm! Go\<Home>*** ". m_info
                let s:lastdate = m_info
                let s:dates0   = line('$') + 1
            endif
        endif
        let t    = @t
        let line = line('$') + 1
        exec 'silent $read '. a:fname
        if line('.') >= line
            try
                " exec 'norm! '. line .',$"td'
                norm! G"tdd
                let @t = pim#MakeDisplayEntry{a:class}(@t)
                if @t != ''
                    " exec 'norm! Go'. @t
                    $put t
                endif
            finally
                let @t = t
            endtry
        endif
    endif
endf

" function! pim#DiffInDays(date)
"     if a:0 >= 1
"         return pim#DiffInDays(a:date, a:1)
"     else
"         return pim#DiffInDays(a:date)
"     end
" endf

function! pim#RebuildIndex(class) "{{{3
    echom 'PIM: Rebuilding the index for: '. a:class
    call pim#DeleteIndexEntries('', a:class, '')
    let entries = pim#GlobDB(a:class)
    call map(entries, 's:RebuildIndexEntry(v:val, a:class)')
endf

function! pim#Rebuild() "{{{3
    for c in s:pimClasses
        call pim#RebuildIndex(c)
    endfor
endf

function! s:RebuildIndexEntry(fname, class) "{{{3
    split
    exec 'edit '. tlib#arg#Ex(a:fname)
    call pim#UpdateIndex(fnamemodify(a:fname, ':p'), a:class)
    bdelete!
endf


""" Utilities
"""""" For use with calender.vim
if exists(':Calendar') "{{{2
    if exists('g:pimInstallCalendar') && g:pimInstallCalendar
        function! pim#Calendar(day, month, year, week, dir) "{{{3
            if a:dir == 'H'
                let b:pimSplit = 'split'
            else
                " let b:pimSplit = 'vsplit'
                let b:pimSplit = 'wincmd l | split'
            endif
            exec 'PimToday! '. a:year .'-'. a:month .'-'. a:day
        endf
    
        let g:calendar_action = 'pim#Calendar'
    endif
   
    function! pim#SelectDate(...) "{{{3
        let s:pimTempReg = a:0 >= 1 ? a:1 : '+'
        let s:pimCalendarAction = g:calendar_action
        let g:calendar_action   = 'pim#SelectDateCallback'
        CalendarH
        " Calendar
    endf
    
    function! pim#SelectDateCallback(day, month, year, week, dir) "{{{3
        let date = a:year .'-'. a:month .'-'. a:day
        wincmd c
        if s:pimTempReg =~ '^\d\+$'
            exec 'buffer '. s:pimTempReg
            exec 'norm! i'. date
        else
            " exec 'let @'. s:pimTempReg .' = "'.date .'"'
            let @{s:pimTempReg} = date
            let s:pimTempReg = ''
        endif
        let g:calendar_action = s:pimCalendarAction
    endf
    
    command! -narg=? PimYankDate call pim#SelectDate(<f-args>)
    command! PimInsertDate call pim#SelectDate(bufnr('%'))
endif

function! pim#Prompt(class, what) "{{{3
    echom "Please enter ". a:what ." for the new ". a:class
endf


""" Classes "{{{1
let s:pimClasses     = []

function! s:IsValidClass(class) "{{{3
    return index(s:pimClasses, a:class) != -1
endf

function! pim#Complete(ArgLead, CmdLine, CursorPos) "{{{3
    let cl    = split(a:CmdLine, '\s\+')
    let cmd   = cl[0]
    let class = matchstr(cmd, '^Pim\zs\u\+$')
    let entries = pim#GlobDB(class)
    call map(entries, 'fnamemodify(v:val, ":t:r")')
    return entries
endf

function! s:GetClassDir(class) "{{{3
    return tlib#file#Join([g:pimHome . 'db', a:class])
endf

function! pim#DefClass(class) "{{{3
    let class = toupper(a:class)
    if !exists('g:vikiInter'. class)
        let path = s:GetClassDir(a:class)
        call tlib#dir#Ensure(path)
        call viki#Define(class, path, g:pimFileSuffix)
        call add(s:pimClasses, class)
        exec 'command! -narg=1 -complete=customlist,pim#Complete Pim'. class 
            \ .' call pim#NewFile(tlib#file#Join([g:vikiInter'. class .', <q-args>.g:pimFileSuffix]), "'. a:class .'")'
        if g:pimMenuPrefix != ''
            exec 'amenu '. g:pimMenuPrefix .'&List.'. class .' :call pim#List("'. class .'")<cr>'
            exec 'amenu '. g:pimMenuPrefix .'&New.'. class .' :Pim'. class .' '
        endif
    elseif g:pimWarnings =~# 'i'
        echom 'PIM: Interviki '. class .' already defined'
    endif
endf

function! pim#List(class) "{{{3
    if exists('*TSelectFiles')
        call TSelectFiles("normal!", g:vikiInter{a:class})
    else
        exec 'Explore '. g:vikiInter{a:class}
    endif
endf


""" Maps "{{{1
function! pim#SetBufferMaps() "{{{3
    if !hasmapto(":PimCleanEntry")
        noremap <buffer> <Leader>#c :PimCleanEntry<cr>
    endif
endf

