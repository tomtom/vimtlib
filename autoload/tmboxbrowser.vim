" tmboxbrowser.vim -- Browse mbox files
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-21.
" @Last Change: 2007-08-27.
" @Revision:    663

if &cp || exists("loaded_tmboxbrowser_autoload")
    finish
endif
let loaded_tmboxbrowser_autoload = 1

let s:scratch_name = '__MBOX_Browser__'

fun! s:SNR()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
endf

function! tmboxbrowser#TMBoxSelect(bang)
    if empty(g:tmboxbrowser_path)
        echoerr 'tmbox: Please set g:tmboxbrowser_path first'
        return
    endif
    let mboxes = split(globpath(g:tmboxbrowser_path, '**'), '\n')
    call filter(mboxes, 'v:val !~ ''\.\(sbd\|msf\|dat\|html\)$''')
    let mbox   = tlib#input#List('s', 'Select mbox', mboxes)
    if !empty(mbox)
        " TLogVAR mbox
        " exec 'edit '. tlib#arg#Ex(mbox)
        call tmboxbrowser#TMBoxBrowse(a:bang, mbox)
    endif
endf

fun! tmboxbrowser#TMBoxBrowse(...)
    exec tlib#arg#Let(['bang', 'file'])
    let markread = empty(bang)
    " TLogVAR bang
    " TLogVAR file
    " TLogDBG bufnr('%')
    " TLogDBG bufname('%')
    " TLogDBG "exists('s:tmboxbrowser_bufnr')=". exists('b:tmboxbrowser_bufnr')
    if !exists('b:tmboxbrowser_bufnr') || !empty(file) || !markread
        if !empty(file)
            " TLogDBG 'edit '. file
            exec 'edit '. tlib#arg#Ex(file)
        endif
        " TAssert bufname('%') != s:scratch_name
        let b:tmboxbrowser_bufnr  = bufnr('%')
        " TLogVAR b:tmboxbrowser_bufnr
        let pos = getpos('.')
        let b:tmboxbrowser_index  = {}
        let b:tmboxbrowser_ids    = []
        let mbox                  = expand('%:p')
        let b:tmboxbrowser_data   = tlib#cache#Filename('tmbox', mbox, 1)
        " g:tmboxbrowser_datadir . 
        "             \ substitute(tlib#file#Relative(mbox, g:tmboxbrowser_datadir), '\W', '_', 'g')
        call s:SetIgnore(markread)
        silent keepjumps g /^From /call s:CollectHeader(b:tmboxbrowser_index, b:tmboxbrowser_ids)
        if !empty(b:tmboxbrowser_ids)
            let b:tmboxbrowser_index[b:tmboxbrowser_ids[-1]].bodyend = line('$')
        endif
        for id in b:tmboxbrowser_ids
            let mail          = b:tmboxbrowser_index[id]
            let mail.top      = mail.bodystart - mail.headstart + 1
            " let mail.top      = mail.bodystart - mail.headstart
            " TLogVAR mail.top
            let mail.contents = getline(mail.headstart, mail.bodyend)
        endfor
        call setpos('.', pos)
    endif
    let mlist = s:GetList(b:tmboxbrowser_bufnr)
    if !empty(mlist)
        call s:SetInputListParams(1)
        let mailid = tlib#input#List('m', 'Select Mail', mlist, [
                    \ {'key': 24, 'agent': s:SNR() .'AgentToggleMarkRead', 'key_name': '<c-x>', 'help': 'Toggle mark read'},
                    \ {'key': 20, 'agent': s:SNR() .'AgentToggleHideRead', 'key_name': '<c-t>', 'help': 'Toggle show read'},
                    \ {'pick_last_item': 0},
                    \ {'show_empty': 1},
                    \ {'filter_format': s:SNR() .'DisplayFormat(%s)'},
                    \ {'display_format': s:SNR() .'DisplayFormat(%s)'},
                    \ ])
                    " \ {'return_agent': s:SNR() .'AgentReturnValue'},
        if !empty(mailid)
            " call TLogDBG(s:MBoxVar(b:tmboxbrowser_bufnr, 'b:tmboxbrowser_markread'))
            if s:MBoxVar(b:tmboxbrowser_bufnr, 'b:tmboxbrowser_markread')
                call s:MBoxVar(b:tmboxbrowser_bufnr, 's:MarkRead('. string(mailid) .')')
            endif
            " TLogVAR mailidx
            call s:ViewMail(mailid[0], winnr())
        endif
    endif
endf

fun! s:MarkRead(ids)
    for id in a:ids
        " TLogVAR id
        let idi = index(b:tmboxbrowser_ignore, id)
        " TLogVAR idi
        if idi == -1
            call add(b:tmboxbrowser_ignore, id)
        else
            call remove(b:tmboxbrowser_ignore, idi)
        endif
    endfor
    " if !isdirectory(g:tmboxbrowser_datadir)
    "     call mkdir(g:tmboxbrowser_datadir, 'p')
    " endif
    call writefile(b:tmboxbrowser_ignore, b:tmboxbrowser_data)
    call s:SetInputListParams(0)
endf

fun! s:SetInputListParams(setbuffer)
    " TLogDBG bufname('%')
    if a:setbuffer
        let s:tmboxbrowser_bufnr = b:tmboxbrowser_bufnr
    endif
    let s:mails_index  = s:MBoxVar(b:tmboxbrowser_bufnr, 'b:tmboxbrowser_index')
    let s:mails_ignore = s:MBoxVar(b:tmboxbrowser_bufnr, 'b:tmboxbrowser_ignore')
endf

fun! s:SetIgnore(markread)
    " TLogVAR a:markread
    " TAssert bufnr('%') == b:tmboxbrowser_bufnr
    let b:tmboxbrowser_markread = a:markread
    if filereadable(b:tmboxbrowser_data)
        let b:tmboxbrowser_ignore = readfile(b:tmboxbrowser_data)
    else
        let b:tmboxbrowser_ignore = []
    endif
endf

fun! s:MBoxVar(bufnr, name)
    let bn = bufnr('%')
    if a:bufnr != bn
        exec 'buffer! '. a:bufnr
    endif
    let rv = eval(a:name)
    if a:bufnr != bn
        exec 'buffer! '. bn
    endif
    return rv
endf

function! s:AgentToggleHideRead(world, selected)
    call s:MBoxVar(s:tmboxbrowser_bufnr, 's:SetIgnore(!b:tmboxbrowser_markread)')
    let a:world.base  = s:GetList(s:tmboxbrowser_bufnr)
    let a:world.state = 'reset'
    call a:world.ResetSelected()
    return a:world
endf

function! s:AgentToggleMarkRead(world, selected)
    call s:MBoxVar(s:tmboxbrowser_bufnr, 's:MarkRead('. string(a:selected) .')')
    let a:world.base  = s:GetList(s:tmboxbrowser_bufnr)
    let a:world.state = 'reset'
    call a:world.ResetSelected()
    return a:world
endf

fun! s:DisplayFormat(id)
    let mail = s:mails_index[a:id]
    let sep  = index(s:mails_ignore, a:id) == -1 ? ':' : '*'
    return printf('%-20s %s %s', mail.from, sep, mail.subject)
endf

fun! s:GetList(bufnr)
    " TLogVAR a:bufnr
    let mails = s:MBoxVar(a:bufnr, 'copy(b:tmboxbrowser_ids)')
    let sort  = s:MBoxVar(a:bufnr, "tlib#var#Get('tmboxbrowser_sort', 'bg')")
    if !empty(sort)
        if sort == '-'
            call reverse(mails)
        endif
    end
    if s:MBoxVar(a:bufnr, 'b:tmboxbrowser_markread')
        let ignore = s:MBoxVar(a:bufnr, 'b:tmboxbrowser_ignore')
        if !empty(ignore)
            let mails1 = filter(copy(mails), 'index(ignore, v:val) == -1')
            if empty(mails1) && g:tmboxbrowser_if_no_unread_mails_show_all
                echom 'TMBOX: No unread mails. Displaying all mails.'
            else
                let mails = mails1
            endif
        endif
    endif
    return mails
endf

fun! s:ViewMail(id, winnr)
    let bufnr = b:tmboxbrowser_bufnr
    " TLogVAR bufnr
    let bidx = s:MBoxVar(b:tmboxbrowser_bufnr, 'b:tmboxbrowser_index')
    " TAssert IsDictionary(bidx)
    let mail = bidx[a:id]
    " TLogVAR mail.top
    call tlib#scratch#UseScratch({'scratch': s:scratch_name, 'scratch_split': 0})
    " TAssert IsEqual(fnamemodify(bufname('%'), ':t'), '__MBOX_Browser__')
    let b:tmboxbrowser_bufnr = bufnr
    " TLogVAR b:tmboxbrowser_bufnr
    if &term =~ 'gui'
        noremap <buffer> <esc> :call tmboxbrowser#TMBoxBrowse()<cr>
    endif
    noremap <buffer> q :bdelete<cr>
    " exec 'noremap <buffer> i :buffer '. bufnr .'| call tmboxbrowser#TMBoxBrowse()<cr>'
    " noremap <buffer> i :call <SID>MBoxVar(b:tmboxbrowser_bufnr, 'tmboxbrowser#TMBoxBrowse()')<cr>
    noremap <buffer> i :call tmboxbrowser#TMBoxBrowse()<cr>
    noremap <buffer> ? :call <SID>ShowHelp()<cr>
    noremap <buffer> $ :echo <SID>MBoxVar(b:tmboxbrowser_bufnr, 'string(b:tmboxbrowser_mail)')<cr>
    exec 'noremap <buffer> p :call <SID>ViewMail('. string(a:id) .', '. a:winnr .')<cr>'
    map <buffer> <bs> <PageUp>
    map <buffer> <space> <PageDown>
    set ft=mail

    " let charset = matchstr(mail.contenttype, 'charset=\zs\S\+')
    " if charset =~? 'utf-\?8'
    "     setlocal enc=utf8
    " endif
    let contents = copy(mail.contents)
    " TLogDBG "len0(contents)=". len(contents)
    let type = matchstr(mail.contenttype, '.\{-}\ze;')
    " TLogVAR type
    while type =~ 'multipart'
        let boundary = matchstr(mail.contenttype, 'boundary=\zs\("[^"]\+"\|[^[:space:];]\+\)')
        let boundary = substitute(boundary, '^"\(.*\)"$', '\1', '')
        norm! ggdG
        call append(0, contents[1:-1])
        let parts       = s:CollectMultipart(boundary)
        let part_names  = map(copy(parts), 'v:val["contenttype"]')
        let parts_index = tlib#input#List('si', 'Select part', part_names, [], 0)
        if parts_index > 0
            " let mail = extend(parts[parts_index - 1], mail)
            let mail = extend(parts[parts_index - 1], mail, 'keep')
            " TLogVAR mail.top
            " TLogVAR mail.encoding
            " TLogVAR parts[parts_index - 1].encoding
            let type = matchstr(mail.contenttype, '.\{-}\ze;')
            " TLogVAR type
            let contents = copy(mail.contents)
        else
            let @/ = '^--'. boundary
            break
        endif
    endwh

    let cenc = tolower(substitute(mail.encoding, '\W', '_', 'g'))
    " TLogVAR mail.encoding
    " TLogVAR cenc
    if exists('*s:Convert_'. cenc)
        " TLogDBG "len1(contents)=". len(contents)
        " TLogVAR mail.top
        " let contents[mail.top : -1] = s:Convert_{cenc}(contents[mail.top : -1])
        let contents_body = contents[mail.top : -1]
        call remove(contents, mail.top, -1)
        let contents += s:Convert_{cenc}(contents_body)
        " TLogVAR contents
    endif
    " TLogVAR type

    let cleantype = substitute(type, '\W', '_', 'g')
    if exists('g:tmboxbrowser_convert_'. cleantype) && !empty(g:tmboxbrowser_convert_{cleantype})
        norm! ggdG
        call append(0, contents[mail.top : -1])
        silent exec '%'. g:tmboxbrowser_convert_{cleantype}
        call remove(contents, mail.top, -1)
        let contents += getline(1, line('$'))
    elseif mail.encoding == 'base64' && !empty(g:tmboxbrowser_decode_base64)
        let filename = matchstr(mail.contenttype, 'name="\zs.\{-}\ze"')
        if s:AttachmentOk(filename) && (!exists('loaded_viki') || VikiIsSpecialFile(filename))
            let cwd = getcwd()
            call s:EnsureAttachmentsDir()
            silent exec 'lcd '. escape(g:tmboxbrowser_attachments_dir, '#% \')
            try
                " echom filename .' -- '. g:tmboxbrowser_attachments_dir
                if !filereadable(filename) || !empty(input('File exists. Overwrite? (y/n) ', 'y'))
                    let image = contents[mail.top : -1]
                    let fn64  = filename .'.base64'
                    call writefile(image, fn64)
                    silent exec printf(g:tmboxbrowser_decode_base64, tlib#arg#Ex(fn64), tlib#arg#Ex(filename))
                    call delete(fn64)
                    if exists('*VikiOpenSpecialFile')
                        call VikiOpenSpecialFile(filename)
                    else
                        silent exec '!'. g:netrw_browsex_viewer .' '. tlib#arg#Ex(filename)
                    endif
                endif
            finally
                silent exec 'lcd '. escape(cwd, '#% \')
            endtry
        endif
    endif

    norm! ggdG
    call append(0, contents[1:-1])
    setlocal nomodifiable
    exec (mail.top - 1)
    norm! zt
    if exists(':VikiMinorMode')
        let b:vikiDisableType = 'c'
        VikiMinorMode
    endif
endf

function! s:AttachmentOk(filename) "{{{3
    return tlib#list#Any(g:tmboxbrowser_attachments_filter, string(a:filename) .' =~ v:val')
endf

fun! s:EnsureAttachmentsDir()
    if !isdirectory(g:tmboxbrowser_attachments_dir)
        call mkdir(g:tmboxbrowser_attachments_dir, 'p')
    endif
endf

fun! s:ShowHelp()
    if &term =~ 'gui'
        echo '<esc> ... Index'
    endif
    echo 'i     ... Index'
    echo 'p     ... Select parts or re-view mail'
    echo 'q     ... Quit'
    echo '?     ... Help'
endf

" fun! s:AgentReturnValue(world, return_value)
"     if !empty(a:return_value)
"         let bidx = a:world.table[a:world.prefidx - 1]
"         return bidx
"     endif
" endf

fun! s:CollectMultipart(boundary)
    let prx = '^--'. a:boundary .'$'
    " TLogVAR prx
    let erx = '^--'. a:boundary .'--$'
    " TLogVAR erx
    norm! G
    let end = search(erx, 'Wbc') - 1
    " TLogVAR end
    let parts = []
    while search(prx, 'bW')
        let headstart = line('.')
        " TLogVAR headstart
        let headend   = search('\n\zs\n', 'Wn')
        " TLogVAR headend
        " let part      = getline(headstart, end - 1)
        let part      = getline(headstart, end)
        let ctype     = s:ExtractHeader(headstart, headend, 'Content-Type')
        " TLogVAR ctype
        let ctenc     = s:ExtractHeader(headstart, headend, 'Content-Transfer-Encoding')
        " TLogVAR ctenc
        let top       = headend - headstart + 1
        " let top       = headend - headstart
        call insert(parts, {'contenttype': ctype, 'encoding': ctenc, 'top': top, 
                    \ 'contents': part})
        let end = headstart - 1
        exec end
    endwh
    return parts
endf

fun! s:CollectHeader(acc, ids)
    let date      = matchstr(getline('.'), '^From -\s*\zs.*')
    let headstart = line('.')
    let headend   = search('\n\zs\n')
    if !empty(a:acc)
        let a:acc[a:ids[-1]].bodyend = headstart - 1
    endif
    let from     = s:ExtractHeader(headstart, headend, 'From')
    let fromlist = matchlist(from, '^\(.\{-}\)\?\s*\(<.\{-}>\)')
    if !empty(fromlist)
        let from = !empty(fromlist[1]) ? fromlist[1] : fromlist[2]
    endif
    let subject     = s:ExtractHeader(headstart, headend, 'Subject')
    let encoding    = s:ExtractHeader(headstart, headend, 'Content-Transfer-Encoding')
    " TLogVAR encoding
    let contenttype = s:ExtractHeader(headstart, headend, 'Content-Type')
    let idheaders = ['Message-ID', 'X-UIDL']
    let messageid = ''
    while empty(messageid) && !empty(idheaders)
        let [header; idheaders] = idheaders
        let messageid = s:ExtractHeader(headstart, headend, header)
    endwh
    if empty(messageid)
        let messageid = join([from, subject, date])
    endif
    exec headstart
    norm! }
    if has_key(a:acc, messageid)
        echohl Error
        echom 'TMBOX: Dupplicate Message-ID: '. messageid
        echohl NONE
    endif
    let a:acc[messageid] = {
                \ 'date': date, 'from': from, 'subject': subject, 'encoding': encoding, 
                \ 'contenttype': contenttype, 'messageid': messageid,
                \ 'headstart': headstart, 'bodystart': headend + 1,
                \ }
    call add(a:ids, messageid)
endf

fun! s:ExtractHeader(headstart, headend, name)
    exec a:headstart
    let rx = '\c^'. a:name .':'
    call search(rx, 'W', a:headend)
    let info = [matchstr(getline('.'), rx .'\s\+\zs.*')]
    while line('.') < a:headend && getline(line('.') + 1) =~ '^\s\+\S'
        norm! j
        call add(info, matchstr(getline('.'), '^\s\+\zs.\+'))
    endwh
    " TLogVAR info
    return join(info)
endf

fun! s:Convert_quoted_printable(body)
    let qplc = 0
    let acc  = []
    for i in range(0, len(a:body) - 1)
        " TLogVAR a:body[i]
        let line0 = a:body[i]
        let line  = substitute(line0, '=\([0-F][0-F]\)', '\=nr2char("0x". submatch(1))', 'g')
        " TLogVAR line
        let qplc0 = qplc
        " TLogVAR qplc0
        if line[-1:-1] == '='
            let line = line[0:-2]
            let qplc = 1
        else
            let qplc = 0
        endif
        " TLogVAR qplc
        if qplc0
            let acc[-1] .= substitute(line, '^\s\+', '', '')
            " TLogVAR acc[-1]
        else
            call add(acc, line)
            " TLogVAR line
        endif
    endfor
    return acc
endf

fun! tmboxbrowser#Decode_base64(infile, outfile)
    silent exec printf(g:tmboxbrowser_decode_base64, a:infile, a:outfile)
endf

fun! tmboxbrowser#Convert_image_jpeg(line1, line2)
    if !empty(g:tmboxbrowser_decode_base64)
        " call s:EnsureAttachmentsDir()
        let tempfile = tempname()
        let tempdir  = fnamemodify(tempfile, ':h')
        let tempname = fnamemodify(tempfile, ':t')
        let cwd      = getcwd()
        silent exec 'lcd '. escape(tempdir, '#% \')
        try
            let image = contents[mail.top : -1]
            call writefile(image, tempname)
            call tmboxbrowser#Decode_base64(tempname, tempname .'.jpg')
            silent exec printf(g:tmboxbrowser_decode_jpeg, tempname .'.jpg', tempname .'.txt')
            exec 'norm! '. a:line1 .'Gd'. a:line2 .'G'
            call append(a:line1, readfile(tempname .'.txt'))
        finally
            if filereadable(tempname .'.jpg')
                call delete(tempname .'.jpg')
            endif
            if filereadable(tempname .'.txt')
                call delete(tempname .'.txt')
            endif
            if filereadable(tempname)
                call delete(tempname)
            endif
            silent exec 'lcd '. escape(cwd, '#% \')
            echom tempfile
        endtry
    endif
endf


finish

CHANGES:
0.1
Initial release

0.2
- Show all mails if there are no unread mails.
- Require tlib 0.9

0.3
- Require tlib 0.10
- FIX: Problem with scratch related functions
- Check if an attachement's filename matches g:tmboxbrowser_attachments_filter

