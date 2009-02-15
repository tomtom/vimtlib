" session.vim
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-09-02.
" @Last Change: 2009-02-15.
" @Revision:    0.0.354

if &cp || exists("loaded_tsession_autoload")
    finish
endif
let loaded_tsession_autoload = 1


let s:none = '*** NONE ***'


function! tsession#Collect() "{{{3
    let session = {'protocol': 1, 'buffers': {}, 'windows': {}, 'winnr': winnr(),
                \ 'winrestcmd': winrestcmd(),
                \ 'restore_global': s:OptionsRestCmd('global')}
    " let s:winwidth  = &co - &fdc
    let s:winwidth  = &co
    let s:winheight = &lines
    " let s:next_vert = winwidth(1) != s:winwidth
    let s:next_vert = 0
    let wn = winnr()
    let wv = winsaveview()
    windo call s:CollectWindowsInfo(session)
    exec wn.'winc w'
    let bn = bufnr('%')
    bufdo call s:CollectBuffersInfo(session)
    exec 'buffer! '. bn
    call winrestview(wv)
    return session
endf


function! s:CollectWindowsInfo(session) "{{{3
    if !empty(&buftype)
        echohl Error
        echom 'WARNING: TSession: Special buffer in view: '. bufname('%')
        echohl NONE
    endif
    let wn = winnr()
    let ww = winwidth(0)
    let wh = winheight(0)
    " TLogVAR wn, ww, wh
    let a:session.windows[wn] = {
                \ 'bn': bufnr('%'),
                \ 'vertical': s:next_vert,
                \ 'cd': getcwd(),
                \ 'restore_win': s:OptionsRestCmd('win'),
            \ }
    " TLogVAR a:session.windows[wn]
    let s:next_vert = ww != s:winwidth
    if s:next_vert
        let ww = s:winwidth - ww - 1
    endif
    " TLogVAR ww
    let s:winwidth  = ww
    let s:winheight = wh
endf


function! s:CollectBuffersInfo(session) "{{{3
    let bn = bufnr('%')
    " TLogDBG expand('%:p')
    " TLogDBG expand('%:t')
    if !empty(expand('%:t')) && empty(&buftype)
        " \ || !empty(g:tsession_register_special.buftype)
        " \ || buflisted(bn) || g:tsession_register_special.unlisted
        " \ || bufloaded(bn) || g:tsession_register_special.unloaded)
        let a:session.buffers[bn] = {
                    \ 'filename': fnamemodify(bufname(bn), ':p'),
                    \ 'buflisted': buflisted(bn),
                    \ 'bufloaded': bufloaded(bn),
                    \ 'pos': getpos('.'),
                    \ 'wv': winsaveview(),
                    \ 'filetype': &filetype,
                    \ 'restore_buf': s:OptionsRestCmd('buf')
                    \ }
        " TLogVAR a:session.buffers[bn]
    endif
endf


function! s:OptionsRestCmd(type) "{{{3
    let options = g:tsession_save_{a:type}
    let extra   = g:tsession_save_{a:type}_extra
    if a:type == 'win' || a:type == 'buf'
        let cmd = 'let &l:'
        " let cmd = 'setlocal '
    else
        " let cmd = 'let &g:'
        let cmd = 'let &'
        " let cmd = 'set '
    endif
    let restore = []
    for o in options
        let val = eval(o)
        if o[0] == '&'
            call add(restore, cmd . o[1:-1] .'='. string(val))
            " call add(restore, cmd . o[1:-1] .'='. escape(val, ' \'))
        elseif o =~ '^[gwb]:'
            call add(restore, 'let '. o .'='. string(val))
        endif
    endfor
    for e in extra
        " TLogVAR e
        call add(restore, eval(e))
    endfor
    return join(restore, '|')
endf


function! s:Restore1(session, ...) "{{{3
    TVarArg ['args', {}]
    let g:SessionLoad = 1
    try
        exec a:session.restore_global
        let swap = get(args, 'swap', 'g:tsession_swap')
        for [bn, buf] in items(a:session.buffers)
            if buf.bufloaded
                let fn = buf.filename
                if !bufloaded(fn)
                    " && filereadable(fn)
                    try
                        let cmd = buf.buflisted ? 'edit ' : 'hide edit '
                        exec cmd . tlib#arg#Ex(fn)
                    catch /^Vim\%((\a\+)\)\=:E325/
                    endtry
                else
                    exec 'buffer! '.  bufnr(fn)
                endif
                if !empty(&bufhidden) && buf.buflisted
                    set bufhidden=
                endif
                let &filetype = buf.filetype
                exec buf.restore_buf
                call setpos('.', buf.pos)
                if swap
                    call setbufvar(fn, 'tsession_keep', 1)
                endif
            endif
        endfor
        " Hide buffers not in the session.
        if swap
            let bn = bufnr('%')
            bufdo if exists('b:tsession_keep') | unlet b:tsession_keep | else | confirm bdelete | endif
            exec 'buffer! '. bn
        endif
        silent only
        " for i in range(winnr('$') - 1)
        "     wincmd c
        " endfor
        for [wn, win] in items(a:session.windows)
            let pre = win.vertical ? 'vert' : ''
            let buf = get(a:session.buffers, win.bn, {})
            " TLogVAR win.bn, buf
            if !empty(buf)
                let bn  = bufnr(buf.filename)
                if wn == 1
                    let cmd = ' buffer! '. bn
                else
                    let cmd = ' sbuffer! '. bn
                endif
            else
                let cmd = ' new '
            endif
            if has_key(buf, 'cd')
                exec 'lcd '. tlib#arg#Ex(buf.cd)
            endif
            exec pre.cmd
            exec win.restore_win
        endfor
        exec a:session.winrestcmd
        exec a:session.winnr .'wincmd w'
        doautoall SessionLoadPost
    finally
        unlet g:SessionLoad
    endtry
endf


function! s:GlobSessions() "{{{3
    let rv = []
    let pat = '*'.sfx
    if exists('b:tsessions_dir')
        call tlib#dir#Ensure(b:tsessions_dir)
        let ls = glob(tlib#file#Join([b:tsessions_dir, pat]))
        if !empty(ls)
            let rv += split(ls, '\n')
        endif
    endif
    if exists('g:tsessions_dir')
        call tlib#dir#Ensure(g:tsessions_dir)
        let ls = glob(tlib#file#Join([g:tsessions_dir, pat]))
        if !empty(ls)
            let rv += split(ls, '\n')
        endif
    else
        let ls = glob(tlib#cache#Filename('sessions', pat, 1))
        if !empty(ls)
            let rv += split(ls, '\n')
        endif
    endif
    return rv
endf


function! tsession#Sessions() "{{{3
    let rv = s:GlobSessions()
    " TLogVAR rv
    return map(rv, 'fnamemodify(v:val, ":t")')
endf


function! s:SessionName(name) "{{{3
    let dir = tlib#var#Get('tsessions_dir', 'bg')
    let sfx = tlib#var#Get('tsessions_suffix', 'bg')
    if !empty(dir)
        if a:name =~ '^_'
            return tlib#file#Join([dir, a:name]) .sfx
        elseif !empty(g:tsessions_dir)
            return tlib#file#Join([g:tsessions_dir, a:name]) .sfx
        endif
    else
        return tlib#cache#Filename('sessions', a:name, 1) .sfx
    endif
endf


function! s:SessionBegin(name) "{{{3
    if exists('g:tsession_begin_'. a:name)
        exec g:tsession_begin_{a:name}
    endif
endf


function! s:SessionEnd(name) "{{{3
    if exists('g:tsession_end_'. a:name)
        exec g:tsession_end_{a:name}
    endif
endf


" :def: function! tsession#Save(?name=g:tsession_current, ?args={})
" Save a session description.
function! tsession#Save(...) "{{{3
    TVarArg ['name', g:tsession_current], ['args', {}]
    if name == s:none
        return
    end
    let filename = s:SessionName(name)
    let session  = tsession#Collect()
    let output   = [string(session)]
    return writefile(output, filename, 'b')
endf


" :def: function! tsession#Load(?name=g:tsession_current, ?args={})
" Load 'SESSION'; source 'SESSION.vim' if existent.
" If args.swap == 1, delete (swap-out) any unregistered buffers.
function! tsession#Load(...) "{{{3
    TVarArg ['name', g:tsession_current], ['args', {}]
    if name == s:none
        call s:SessionEnd(g:tsession_current)
    else
        let filename = s:SessionName(name)
        " TLogVAR filename
        if filereadable(filename)
            let session  = eval(readfile(filename, 'b')[0])
            let protocol = get(session, 'protocol', 1)
            call s:Restore{protocol}(session, args)
        endif
        let xfile = filename.'.vim'
        if filereadable(xfile)
            exec 'source '. tlib#arg#Ex(xfile)
        endif
        call s:SessionBegin(name)
    end
    let g:tsession_current = name
endf


function! tsession#AgentDeleteSession(world, selected) "{{{3
    for name in a:selected
        let f = s:SessionName(name)
        if filereadable(f)
            call delete(f)
            call remove(a:world.base, index(a:world.base, name))
            echom 'Delete session: '. f
        else
            echom 'Unknown session: '. f
        endif
    endfor
    let a:world.state = 'reset'
    return a:world
endf


function! tsession#AgentNewSession(world, selected) "{{{3
    let name = input('New session name: ')
    if !empty(name)
        call a:world.CloseScratch()
        call tsession#Save(name)
    endif
    let a:world.state = 'exit empty'
    return a:world
endf


function! tsession#AgentSaveSession(world, selected) "{{{3
    if !empty(a:selected)
        let name = a:selected[0]
        call a:world.CloseScratch()
        call tsession#Save(name)
    endif
    let a:world.state = 'exit empty'
    return a:world
endf


" :def: function! tsession#Browse(?args={})
function! tsession#Browse(...) "{{{3
    TVarArg ['args', {}]
    let w = copy(g:tsession_world)
    let w.base = insert(tsession#Sessions(), s:none)
    let idx = index(w.base, g:tsession_current)
    if idx != -1
        let w.initial_index = idx + 1
    endif
    let s = tlib#input#ListD(w)
    if !empty(s)
        call tsession#Load(s, args)
    endif
endf

redraw

