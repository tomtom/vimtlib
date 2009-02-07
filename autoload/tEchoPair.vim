" tEchoPair.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-12-05.
" @Last Change: 2008-12-05.
" @Revision:    0.0.23

let s:save_cpo = &cpo
set cpo&vim


let s:tEchoPairStyles = []


fun! tEchoPair#CollectStyles()
    redir => vars
    silent let
    redir END
    let s:tEchoPairStyles = split(vars, '\n')
    call filter(s:tEchoPairStyles, 'v:val =~ ''^tEchoPairStyle_''')
    call map(s:tEchoPairStyles, 'matchstr(v:val, ''^tEchoPairStyle_\zs\S\+'')')
endf


" fun! tEchoPair#Echo(backwards, 'rx', ?what, ?[args])
" fun! tEchoPair#Echo(backwards, 'fold', ?shiftopen, ?shiftclose)
fun! tEchoPair#Echo(backwards, type, ...)
    " TLogVAR a:backwards, a:type
    let lz = &lazyredraw
    set lazyredraw
    let w0 = line('w0')
    let l0 = line('.')
    let c0 = col('.')
    " let c0 = col['.']
    let pos = getpos('.')
    try
        if a:type == 'fold'
            let what = '.'
            if a:backwards
                call s:Normal('[z', 'silent!')
            else
                call s:Normal(']z', 'silent!')
            endif
            let idx = a:backwards ? 1 : 2
            let lineshift = a:0 >= idx ? a:{idx} : 0
            " TAssert IsNumber(lineshift)
            " TLog lineshift .' i='. idx
            if lineshift > 0
                call s:Normal(lineshift .'j', 'silent!')
            elseif lineshift < 0
                call s:Normal((-lineshift) .'k', 'silent!')
            endif
        else
            let what = a:0 >= 1 ? a:1 : '.'
            " TAssert IsString(what)
            let args0 = a:0 >= 2 ? a:2 : []
            let args = []
            let m = get(args0, 0, '(')
            " TAssert IsString(m)
            call add(args, s:MakeRx(a:type, m))
            let m = get(args0, 1, '')
            " TAssert IsString(m)
            call add(args, empty(m) ? m : s:MakeRx(a:type, m))
            let m = get(args0, 2, ')')
            " TAssert IsString(m)
            call add(args, s:MakeRx(a:type, m))
            call add(args, a:backwards ? 'bW' : 'W')
            let skip = get(args0, 3, '')
            " TAssert IsString(skip)
            if skip != ''
                call add(args, skip)
            elseif exists('*TEchoSkip_'. &filetype)
                call add(args, 'TEchoSkip_'. &filetype .'()')
            else
                call add(args, 'TEchoSkip()')
            endif
            if len(args0) > 4
                let args += args0[4:-1]
            endif
            " echom "DBG searchpairs: ". string(args)
            " echom "DBG tEchoPair#Echo: ". string(args)
            let what = a:backwards ? args[0] : args[2]
            let this = a:backwards ? args[2] : args[0]
            if len(this) > 1 && strpart(getline('.'), col('.') - 1) !~ '^'. this
                call s:Normal('b')
                " TLogDBG strpart(getline('.'), col('.') - 1)
            end
            " echom 'DBG '. what .' '. a:backwards .' '. expand('<cword>') .' '. (expand('<cword>')=~ '^'. what .'$')
            if a:backwards
                if expand('<cword>') =~ this
                    call search(this, 'cb', l0)
                endif
            else
                if expand('<cword>') =~ this
                    call search(this, 'c', l0)
                endif
            endif
            " TLogVAR args
            call call('searchpair', args)
        endif
        " else
        "     if a:backwards
        "         exec 'norm! ['. a:what
        "     else
        "         exec 'norm! ]'. a:what
        "     endif
        " endif
        let l1 = line('.')
        let c1 = col('.')
        if l1 != l0
            if a:backwards
                let c0 = col('$')
            else
                " let c0 = matchend(getline(l1), '^\s*') - 1
                let c0 = matchend(getline(l1), '^\s*')
            endif
        endif
        let text  = getline(l1)
        let style = s:GetStyle()
        " if l1 < l0 || c1 < c0
        if a:backwards
            let text = tEchoPair#Do_open_{style}(what, text, c0, l0, c1, l1)
        else
            let text = tEchoPair#Do_close_{style}(what, text, c0, l0, c1, l1)
        endif
        " TLogDBG 'tEcho '. a:backwards .':'. c0.'x'.l0.'-'.c1.'x'.l1
        echo text
        let b:tEchoPair = text
        " return a:what
    finally
        call s:Normal(w0 .'zt')
        call setpos('.', pos)
        let &lz = lz
    endtry
endf


fun! s:GetStyle()
    if empty(s:tEchoPairStyles)
        call tEchoPair#CollectStyles()
    endif
    if exists('b:tEchoPairStyle')
        let style = b:tEchoPairStyle
    else
        let style = g:tEchoPairStyle
        for s in s:tEchoPairStyles
            if index(g:tEchoPairStyle_{s}, &filetype) != -1
                let style = s
            endif
        endfor
    endif
    return style
endf


fun! s:MakeRx(type, text)
    if a:type =~ 'rx$'
        return a:text
    elseif a:type == 'string'
        return escape(a:text, '^$.*\[]~')
    else
        echoerr 'tEchopair: Unknown type: '. a:type
    endif
endf


fun! s:Normal(cmd, ...)
    let p = a:0 >= 1 ? a:1 : ''
    let m = mode()
    if m ==? 's' || m == ''
        exec p .' keepjumps norm! '. a:cmd
    else
        exec p .' keepjumps norm! '. a:cmd
    endif
endf


function! s:Trim(text) "{{{3
    return strpart(a:text, 0, &co - 2)
endf


fun! tEchoPair#Do_open_inner(what, text, c0, l0, c1, l1)
    return s:Trim(strpart(a:text, a:c1 - 1, a:c0 - a:c1))
endf


fun! tEchoPair#Do_close_inner(what, text, c0, l0, c1, l1)
    return s:Trim(strpart(a:text, a:c0, a:c1 - a:c0))
endf


fun! tEchoPair#Do_open_indicate(what, text, c0, l0, c1, l1)
    let text = s:IndicateCursor(a:text, a:c0, a:l0, a:c1, a:l1)
    let text = s:Trim(a:l1.': '. substitute(text, '\%'. a:c1 .'c'. a:what, g:tEchoPairIndicateOpen, ''))
    let cmdh = s:GetCmdHeight()
    if cmdh > 1
        let acc = [text]
        for i in range(a:l1 + 1, a:l1 + cmdh - 1)
            if i > a:l0
                break
            endif
            " call add(acc, i.': '. s:IndicateCursor(getline(i), a:c0, a:l0, a:c1, i))
            call add(acc, s:Trim(i.': '. getline(i)))
        endfor
        let text = join(acc, "\<c-j>")
    endif
    return text
endf


fun! tEchoPair#Do_close_indicate(what, text, c0, l0, c1, l1)
    let text = substitute(a:text, '\%'. a:c1 .'c'. a:what, g:tEchoPairIndicateClose, '')
    let text = a:l1.': '. s:IndicateCursor(text, a:c0, a:l0, a:c1, a:l1)
    let cmdh = s:GetCmdHeight()
    if cmdh > 1
        let acc = [text]
        for i in range(a:l1 - 1, a:l1 - cmdh + 1, -1)
            if i < a:l0
                break
            endif
            " call insert(acc, i.': '. s:IndicateCursor(getline(i), a:c0, a:l0, a:c1, i))
            call insert(acc, s:Trim(i.': '. getline(i)))
        endfor
        let text = join(acc, "\<c-j>")
    endif
    return text
endf


fun! s:IndicateCursor(text, c0, l0, c1, l1)
    if a:l0 == a:l1
        return substitute(a:text, '\%'. a:c0 .'c.', g:tEchoPairIndicateCursor, '')
    else
        return a:text
    endif
endf


fun! s:GetCmdHeight()
    let ch = &cmdheight
    if mode() =~? '[ivsr]' && &showmode
        let ch -= 1
    endif
    return ch
endf


fun! tEchoPair#Reset()
    augroup TEchoPair
        au!
    augroup END
endf
" call tEchoPair#Reset()


fun! tEchoPair#Install(pattern, ...)
    augroup TEchoPair
        let pattern = empty(a:pattern) ? '<buffer>' : a:pattern
        if a:0 >= 1
            let list = a:1
        elseif has_key(g:tEchoPairs, &filetype)
            let list = g:tEchoPairs[&filetype]
        else
            " [a b]
            " [['(', ')'], ['{', '}']]
            let list = split(&matchpairs, ',')
            call map(list, 'insert(split(v:val, ":"), "string")')
        endif
        for i in list
            let type = i[0]
            if type == 'fold'
                let args = join(map(i, 'string(v:val)'), ', ')
                " TLogDBG args
                exec 'au TEchoPair CursorMoved '. pattern .' if foldclosed(line(".")) == -1 '.' | TEchoPair 1, '. args .' | endif'
            else
                let def = i[1:-1]
                if len(def) == 2
                    let [io, ie] = def
                    call insert(def, '', 1)
                    let im = ''
                elseif len(def) >= 3
                    let [io, im, ie; rest] = def
                else
                    echoerr 'tEchoPair: Malformed definition: '. string(i)
                endif
                if len(io) == 1
                    let condo = 'getline(".")[col(".") - 1] == '. string(io)
                else
                    " let condo = 'strpart(getline("."), col(".") - 1) =~ ''^'''. string(io)
                    let condo = 'expand("<cword>") =~ ''^'. io .'$'''
                endif
                if len(ie) == 1
                    let conde = 'getline(".")[col(".") - 1] == '. string(ie)
                else
                    " let conde = 'strpart(getline("."), col(".") - 1) =~ ''^'''. string(io)
                    let conde = 'expand("<cword>") =~ ''^'. ie .'$'''
                endif
                let argso = join(map([type, io, def], 'string(v:val)'), ', ')
                let argse = join(map([type, ie, def], 'string(v:val)'), ', ')
                " TLogVAR condo, argso
                " TLogVAR conde, argse
                exec 'au TEchoPair CursorMoved '. pattern .' if '. condo .' | TEchoPair 0, '. argse .' | endif'
                exec 'au TEchoPair CursorMoved '. pattern .' if '. conde .' | TEchoPair 1, '. argso .' | endif'
                exec 'au TEchoPair CursorMovedI '. pattern .' if '. condo .' | TEchoPair 0, '. argse .' | endif'
                exec 'au TEchoPair CursorMovedI '. pattern .' if '. conde .' | TEchoPair 1, '. argso .' | endif'
            endif
        endfor
    augroup END
endf


let &cpo = s:save_cpo
unlet s:save_cpo
