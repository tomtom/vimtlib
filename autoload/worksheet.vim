" worksheet.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-15.
" @Last Change: 2010-02-22.
" @Revision:    0.0.713

let s:save_cpo = &cpo
set cpo&vim
" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


let s:modes = {}
let s:bufworksheets = {}
let s:processing = 0
let s:ws_dir = expand('<sfile>:p:h') .'/worksheet/'

augroup Worksheet
    autocmd!
augroup END


function! worksheet#Worksheet(...) "{{{3
    let mode = a:0 >= 1 ? a:1 : g:worksheet_default
    let current_buffer = a:0 >= 2 ? a:2 : 0
    if !current_buffer
        exec 'split __Worksheet@'. mode .'__'
    endif
    let b:worksheet = worksheet#Prototype()
    let b:worksheet.bufnr = bufnr('')
    let b:worksheet.mode = mode
    let b:worksheet.syntax = mode
    let s:bufworksheets[bufnr('')] = b:worksheet
    if getline(line('$') - 1) =~ '^\[worksheet metadata\]$'
        let worksheet_dump = getline('$')
        silent $-1,$delete
        let metadata = eval(worksheet_dump)
        call extend(b:worksheet, metadata)
        let mode = b:worksheet.mode
    endif
    if empty(mode)
        throw 'Worksheet: "mode" is empty'
    endif
    if !has_key(s:modes, mode)
        try
            call worksheet#{mode}#InitializeInterpreter(b:worksheet)
        catch
            if !current_buffer
                wincmd c
            endif
            echoerr 'Worksheet: Failed to initialize '. mode .': '. v:exception
            return
        endtry
        let s:modes[mode] = []
    endif
    call b:worksheet.BufJoin()
    set filetype=worksheet
    call worksheet#{mode}#InitializeBuffer(b:worksheet)
    if current_buffer
        call s:InstallSaveHooks()
    else
        setlocal buftype=nofile
        setlocal noswapfile
        norm! G
        let empty = line('.') == 1
        call b:worksheet.NewEntry(empty ? -1 : 1)
        if empty
            silent exec line('$') .'delete'
        endif
    endif
    exec 'autocmd Worksheet BufUnload <buffer> call s:bufworksheets['. b:worksheet.bufnr .'].BufUnload()'
endf


function! worksheet#Complete(ArgLead, CmdLine, CursorPos) "{{{3
    redraw
    let candidates = split(glob(s:ws_dir .'*.vim'), '\n')
    call map(candidates, 'fnamemodify(v:val, ":t:r")')
    if !empty(a:ArgLead)
        call filter(candidates, 'v:val[0 : len(a:ArgLead) - 1] ==# a:ArgLead')
    endif
    return candidates
endf


function! worksheet#RestoreBuffer() "{{{3
    call worksheet#Worksheet('', 1)
endf


function! worksheet#SetModifiable(mode) "{{{3
    if s:processing || s:IsInputField(b:worksheet)
        setlocal modifiable
    else
        setlocal nomodifiable
    endif
endf


function! worksheet#Restore() "{{{3
    if exists('b:worksheet')
        setlocal modifiable
        let pos = getpos('.')
        silent %delete
        let ws = b:worksheet
        for idx in ws.order
            let entry = get(ws.entries, idx, {})
            if empty(entry)
                echomsg 'Worksheet: Missing entry: '. idx
            else
                call append(line('$'), entry.header)
                if has_key(entry, 'input')
                    call append(line('$'), entry.input)
                else
                    call append(line('$'), '')
                endif
                if has_key(entry, 'lines')
                    let [silent, input] = ws.SilentInput(entry.input)
                    if !silent && !empty(entry.lines)
                        call append(line('$'), entry.lines)
                    endif
                endif
            endif
        endfor
        silent 1delete
        call setpos('.', pos)
    else
        echoerr 'Worksheet: Not a worksheet'
    endif
endf


function! worksheet#SaveAs(bang, ...) "{{{3
    if exists('b:worksheet')
        " let ext = '_'. b:worksheet.mode . g:worksheet_suffix
        " let fname = input('Filename ('. string(ext) .' will be added): ', '', 'file')
        call inputsave()
        let fname = a:0 >= 1 ? a:1 : input('Filename: ', '', 'file')
        call inputrestore()
        if !empty(fname)
            setlocal buftype&
            setlocal swapfile&
            call s:InstallSaveHooks()
            exec 'saveas'. a:bang .' '. fnameescape(fname)
        endif
    else
        echoerr 'Worksheet: Not a worksheet'
    endif
endf


function! worksheet#Export(filename) "{{{3
    if exists('b:worksheet')
        let reg = v:register
        let rval = getreg(reg)
        try
            call b:worksheet.YankAll()
            let contents = split(getreg(reg), '\n')
            let filename = a:filename
            if empty(filename)
                call inputsave()
                let filename = input("Export to file: ", "", "file")
                call inputrestore()
            endif
            let filename = fnamemodify(filename, ':p')
            if filereadable(filename)
                let overwrite = input("Overwrite file? (Y/n) ")
                if overwrite == "n"
                    echo "Cancel export."
                    return
                endif
            endif
            call writefile(contents, filename)
        finally
            call setreg(reg, rval)
        endtry
    else
        echoerr 'Worksheet: Not a worksheet'
    endif
endf


function! s:InstallSaveHooks() "{{{3
    " autocmd Worksheet VimLeavePre <buffer> call s:WriteBufferPre()
    autocmd Worksheet BufWritePre <buffer> call s:WriteBufferPre()
    autocmd Worksheet BufWritePost <buffer> call s:WriteBufferPost()
endf


function! s:WriteBufferPre() "{{{3
    let pos = getpos('.')
    try
        let worksheet = copy(b:worksheet)
        for key in keys(worksheet)
            if type(worksheet[key]) == 2
                unlet worksheet[key]
            endif
        endfor
        call append(line('$'), ['[worksheet metadata]', string(worksheet)])
    finally
        call setpos('.', pos)
    endtry
endf


function! s:WriteBufferPost() "{{{3
    let pos = getpos('.')
    try
        silent $-1,$delete
    finally
        call setpos('.', pos)
    endtry
endf

function! worksheet#EvaluateAll() "{{{3
    if exists('b:worksheet')
        let pos = getpos('.')
        try
            let worksheet = b:worksheet
            for cid in worksheet.order
                let entry = worksheet.entries[cid]
                " TLogVAR cid, entry
                let lno = b:worksheet.GotoEntry(cid, 1, 0)
                if lno
                    call b:worksheet.Submit()
                endif
            endfor
        finally
            call setpos('.', pos)
        endtry
    else
        echoerr 'Worksheet: Not a worksheet'
    endif
endf




function! s:IsInputField(worksheet, ...) "{{{3
    let line = getline(a:0 >= 1 ? a:1 : '.')
    return line !~ a:worksheet['rx_output'] && line !~ a:worksheet['rx_entry']
    " let syn = synIDattr(synID(line("."), col("."), 0), "name")
    " return syn !=# 'WorksheetHead' && syn !=# 'WorksheetBody'
endf


function! s:RegexpEscape(string) "{{{3
    return '\V'. escape(a:string, '\')
endf


let s:prototype = {
            \ 'entry_id': 0,
            \ 'entries': {},
            \ 'order': [],
            \ 'buffers': [],
            \ 'fmt_output': '`  %s',
            \ 'rx_output': '^`  ',
            \ 'fmt_entry': '___[@%04d@]_________[%s]___',
            \ 'rx_entry': '^___\[@\(\d\{4,}\)@\]_________\[\([^]]*\)\]___\+$',
            \ }


function! worksheet#Prototype() "{{{3
    let o = copy(s:prototype)
    let o.entries = {}
    let o.order = []
    let o.buffers = []
    return o
endf


function! s:prototype.BufJoin() dict "{{{3
    call add(s:modes[self.mode], self.bufnr)
    " call add(self.buffers, self.bufnr)
endf


function! s:prototype.BufUnload() dict "{{{3
    exec 'autocmd! Worksheet BufUnload <buffer='. self.bufnr .'>'
    " call remove(self.buffers, index(self.buffers, self.bufnr))
    " TLogVAR self.buffers
    " if empty(self.buffers) && has_key(self, 'Quit')
    if !has_key(s:modes, self.mode)
        echom 'Worksheet: Mode '. self.mode .' not found in: '. string(keys(s:modes))
        return
    endif
    let idx = index(s:modes[self.mode], self.bufnr)
    if idx < 0
        echom 'Worksheet: Buffer '. self.bufnr .' not found in: '. string(s:modes[self.mode])
    else
        call remove(s:modes[self.mode], idx)
    endif
    if empty(s:modes[self.mode])
        unlet s:modes[self.mode]
        if has_key(self, 'Quit')
            call self.Quit()
        endif
    endif
endf


function! s:prototype.NextEntry(rel_pos, create, wrap) dict "{{{3
    let cid = self.CurrentEntryId()
    let oid = self.OtherEntry(cid, a:rel_pos, a:wrap)
    return self.GotoEntry(oid, a:rel_pos, a:create)
endf


function! s:prototype.OtherEntry(cid, rel_pos, wrap) dict "{{{3
    let cidx = index(self.order, a:cid)
    let oidx = cidx + a:rel_pos
    " TLogVAR a:cid, cidx, a:rel_pos, oidx, self.order
    if a:wrap
        let oidx = (oidx + len(self.order)) % len(self.order)
    endif
    " TLogVAR oidx
    if oidx < 0
        let oid = 0
    elseif oidx >= len(self.order)
        let oid = 0
    else
        let oid = get(self.order, oidx, 0)
    endif
    " TLogVAR a:cid, cidx, a:rel_pos, oid, oidx, self.order
    return oid
endf


function! s:prototype.GotoEntry(entry_id, rel_pos, create) dict "{{{3
    " TLogVAR a:entry_id, a:create
    if a:entry_id > 0
        let entry = get(self.entries, a:entry_id, {})
        " TLogVAR entry
        if !empty(entry)
            return search(s:RegexpEscape(entry.header), 'cw')
        endif
    elseif a:create
        let dir = a:rel_pos < 0 ? -1 : 1
        let eid = self.NewEntry(dir, 1)
        " TLogVAR dir, eid
        return self.HeadOfEntry()
    endif
    return 0
endf


function! s:prototype.NextInputField(rel_pos, create, wrap) dict "{{{3
    let lno = self.NextEntry(a:rel_pos, a:create, a:wrap)
    " TLogVAR lno
    if lno
        " TLogDBG getline('.')
        exec self.EndOfInput(lno + 1)
        if s:IsInputField(self) && &modifiable
            norm! A
        endif
    endif
endf


function! s:prototype.CurrentEntryId() dict "{{{3
    let line = self.HeadOfEntry('n')
    let ml = matchlist(getline(line), self.rx_entry)
    let id = 0 + substitute(get(ml, 1), '^0*', '', '')
    " TLogVAR line, ml, id
    return id
endf


function! s:prototype.Header(cid) dict "{{{3
    let tstamp = strftime("%c")
    let header = printf(self.fmt_entry, a:cid, tstamp)
    " let fill   = min([50, &columns]) - &fdc - len(header)
    " if fill > 0
    "     let header .= repeat('_', fill)
    " endif
    return header
endf


function! s:prototype.NewEntry(direction, ...) dict "{{{3
    " let last_entry = a:0 >= 1 ? a:1 : 0

    let cid = self.CurrentEntryId()
    " TLogVAR cid

    let entry_top = max(keys(self.entries)) + 1
    let head = self.Header(entry_top)
    let self.entries[entry_top] = {'header': head}
    let pos = index(self.order, cid)
    if a:direction > 0
        let pos += 1
    endif
    if pos < 0
        let pos = 0
    elseif pos > len(self.order)
        let pos = len(self.order)
    endif
    call insert(self.order, entry_top, pos)
    " TLogVAR entry_top, head, pos, self.order

    if a:direction < 0
        let lno = self.HeadOfEntry() - 1
    else
        let lno = self.EndOfOutput()
    endif
    if lno < 0
        let lno = 0
    elseif lno > line('$')
        let lno = line('$')
    endif

    call append(lno, head)

    exec lno + 1
    norm! o
    return entry_top
endf


function! s:prototype.HeadOfEntry(...) dict "{{{3
    let flags = 'cW'
    if a:0 >= 1
        let flags .= a:1
    endif
    let line = search(self.rx_entry, 'b'. flags)
    " TLogVAR line
    if !line
        let line = search(self.rx_entry, flags)
        " TLogVAR line
    endif
    return line
endf


function! s:prototype.EndOfInput(...) "{{{3
    let line = a:0 >= 1 ? a:1 : self.HeadOfEntry() + 1
    if line
        let bot = line('$')
        while line < bot && s:IsInputField(self, line + 1)
            let line += 1
        endwh
    endif
    return line
endf


function! s:prototype.EndOfOutput() "{{{3
    let bot = line('$')
    let line = line('.')
    while line < bot && getline(line + 1) !~ self.rx_entry
        let line += 1
    endwh
    return line
endf


function! s:ReplaceVariable(cid, worksheet) "{{{3
    let entry = get(a:worksheet.entries, a:cid, {})
    " TLogVAR entry
    return get(entry, 'output', '')
endf


function! s:prototype.PrepareInput(line) dict "{{{3
    let line = substitute(a:line, '\\\@<!\zs@\(\w\+\)@', '\=<SID>ReplaceVariable(submatch(1), self)', 'g')
    " TLogVAR a:line, line
    let line = substitute(line, '\\\@<!\zs\\@', '@', 'g')
    " TLogVAR line
    let rules = get(g:worksheet_rewrite, 'mode', [])
    for rule in rules
        let line = call('substitute', rule)
    endfor
    return line
endf


function! s:prototype.Keyword() dict "{{{3
    norm! K
endf


function! s:prototype.Yank(eid, what) dict "{{{3
    " TLogVAR a:eid, a:what
    let eid = a:eid > 0 ? a:eid : self.CurrentEntryId()
    " TLogVAR eid
    let entry = get(self.entries, eid, {})
    " TLogVAR entry
    if !empty(entry)
        let reg = v:register
        let v = get(entry, a:what, '')
        if !empty(v)
            call setreg(reg, v)
        elseif s:IsInputField(self)
            let pos = getpos('.')
            try
                let ebeg = self.HeadOfEntry()
                let eend = self.EndOfInput()
                if ebeg < eend
                    let lines = getline(ebeg + 1, eend)
                    " TLogVAR ebeg, eend, lines
                    call setreg(reg, join(lines, "\n"))
                endif
            finally
                call setpos('.', pos)
            endtry
        endif
    endif
endf


function! s:prototype.YankAll() "{{{3
    let reg = v:register
    let rval = getreg(reg)
    let pos = getpos('.')
    let out = []
    try
        for cid in self.order
            " TLogVAR cid
            call setreg(reg, "")
            call self.Yank(cid, 'string')
            let val = getreg(reg)
            " TLogVAR val
            if !empty(val)
                call add(out, val)
            endif
        endfor
    finally
        call setpos('.', pos)
    endtry
    let sout = join(out, "\n\n")
    " TLogVAR sout
    if empty(sout)
        call setreg(reg, rval)
    else
        call setreg(reg, sout)
    endif
endf


function! s:prototype.SwapEntries(rel_pos) dict "{{{3
    let cid = self.CurrentEntryId()
    let cp  = index(self.order, cid)
    let oid = self.OtherEntry(cid, a:rel_pos, 1)
    let op  = index(self.order, oid)
    let self.order[cp] = oid
    let self.order[op] = cid
    call worksheet#Restore()
    exec self.GotoEntry(cid, 0, 0)
    exec self.EndOfInput()
endf


function! s:prototype.SilentInput(input) dict "{{{3
    if a:input[-1][-1 : -1] == ';'
        let a:input[-1] = a:input[-1][0 : -2]
        return [1, a:input]
    else
        return [0, a:input]
    endif
endf


" Special syntax:
" Last character is ";" ... silent
" Leading character is "%" ... comment
function! s:prototype.Submit() dict "{{{3
    let pos = getpos('.')
    let s:processing = 1
    try
        let head_lno = self.HeadOfEntry()
        exec head_lno
        let cid    = self.CurrentEntryId()
        let in_beg = head_lno + 1
        let in_end = self.EndOfInput(in_beg)
        " TLogVAR in_beg, in_end
        if !s:IsInputField(self, in_beg)
            echoerr 'Worksheet: Cannot find input field'
        else
            let input = getline(in_beg, in_end)
            let [silent, input] = self.SilentInput(input)
            " TLogVAR silent, input
            call filter(input, 'v:val[0] != "%"')
            call map(input, 'self.PrepareInput(v:val)')
            " TLogVAR input
            let out_beg = in_end + 1
            if out_beg <= line('$')
                let out_end = self.EndOfOutput()
                " TLogVAR out_beg, out_end
                if out_end <= 0
                    let out_end = line('$')
                endif
                if out_end >= out_beg
                    silent exec out_beg .','. out_end .'delete'
                endif
            endif
            let output = self.Evaluate(input)
            if type(output) <= 1
                let body  = output
                let lines = split(output, "\n")
            elseif type(output) == 3
                let body = join(output, "\n")
                let lines = output
            else
                echoerr 'Worksheet: Unexpected type: '. string(output)
            endif
            call map(lines, 'printf(self.fmt_output, v:val)')
            if !silent && !empty(lines)
                call append(in_end, lines)
            endif
            let header = self.Header(cid)
            call setline(head_lno, header)
            let self.entries[cid].header = header
            let self.entries[cid].input = input
            let self.entries[cid].string = join(input, "\n")
            let self.entries[cid].output = body
            let self.entries[cid].lines = lines
        endif
    finally
        let s:processing = 0
        call setpos('.', pos)
    endtry
endf



" call TLogDBG(string(s:prototype))

let &cpo = s:save_cpo
unlet s:save_cpo
