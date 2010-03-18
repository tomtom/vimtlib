" Mark quickfix & location list items with signs
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-14.
" @Last Change: 2010-03-18.
" @Revision:    394
" GetLatestVimScripts: 2584 1 :AutoInstall: quickfixsigns.vim

if &cp || exists("loaded_quickfixsigns") || !has('signs')
    finish
endif
let loaded_quickfixsigns = 7

let s:save_cpo = &cpo
set cpo&vim


" Reset the signs in the current buffer.
command! QuickfixsignsSet call QuickfixsignsSet("")


if !exists('g:quickfixsigns_classes')
    " A list of sign classes that should be displayed.
    " Can be one of:
    "
    "   rel    ... relative line numbers
    "   cursor ... current line
    "   qfl    ... |quickfix| list
    "   loc    ... |location| list
    "   marks  ... marks |'a|-zA-Z (see also " |g:quickfixsigns_marks|)
    "
    " The sign classes are defined in g:quickfixsigns_class_{NAME}.
    "
    " A list definition is a |Dictionary| with the following fields:
    "
    "   sign:  The name of the sign, which has to be defined. If the 
    "          value begins with "*", the value is interpreted as 
    "          function name that is called with a qfl item as its 
    "          single argument.
    "   get:   A vim script expression as string that returns a list 
    "          compatible with |getqflist()|.
    "   event: The event on which signs of this type should be set. 
    "          Possible values: BufEnter, any
    let g:quickfixsigns_classes = ['cursor', 'qfl', 'loc', 'marks']   "{{{2
    " let g:quickfixsigns_classes = ['rel', 'qfl', 'loc', 'marks']   "{{{2
endif


if !exists('g:quickfixsigns_marks')
    " A list of marks that should be displayed as signs. If empty, 
    " disable the display of marks.
    let g:quickfixsigns_marks = split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ<>', '\zs') "{{{2
    " let g:quickfixsigns_marks = split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ<>''`^.(){}[]', '\zs') "{{{2
    " let g:quickfixsigns_marks = split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ<>.''`^', '\zs') "{{{2
endif


if !exists('g:quickfixsigns_events1')
    " List of events for signs that should be frequently updated.
    let g:quickfixsigns_events1 = ['BufEnter', 'CursorHold', 'CursorHoldI', 'InsertLeave', 'InsertEnter', 'InsertChange']   "{{{2
endif


if !exists('g:quickfixsigns_class_marks')
    " The definition of signs for marks.
    " :read: let g:quickfixsigns_class_marks = {...} "{{{2
    let g:quickfixsigns_class_marks = {
                \ 'sign': '*s:MarkSign',
                \ 'get': 's:Marks()',
                \ 'id': 's:MarkId',
                \ 'event': g:quickfixsigns_events1,
                \ 'timeout': 2
                \ }
                " \ 'event': ['BufEnter', 'CursorHold', 'CursorHoldI', 'CursorMoved', 'CursorMovedI'],
                " \ 'event': ['BufEnter', 'CursorHold', 'CursorHoldI'],
endif
if !&lazyredraw && !empty(g:quickfixsigns_class_marks)
    let s:cmn = index(g:quickfixsigns_class_marks.event, 'CursorMoved')
    let s:cmi = index(g:quickfixsigns_class_marks.event, 'CursorMovedI')
    if s:cmn >= 0 || s:cmi >= 0
        echohl Error
        echom "quickfixsigns: Support for CursorMoved(I) events requires 'lazyredraw' to be set"
        echohl NONE
        if s:cmn >= 0
            call remove(g:quickfixsigns_class_marks.event, s:cmn)
        endif
        if s:cmi >= 0
            call remove(g:quickfixsigns_class_marks.event, s:cmi)
        endif
    endif
    unlet s:cmn s:cmi
endif


if !exists('g:quickfixsigns_class_rel')
    " Signs for number of lines relative to the current line.
    let g:quickfixsigns_class_rel = {'sign': '*s:RelSign', 'get': 's:GetRelList()', 'event': g:quickfixsigns_events1, 'max': 5}  "{{{2
endif


if !exists('g:quickfixsigns_class_qfl')
    " Signs for |quickfix| lists.
    let g:quickfixsigns_class_qfl = {'sign': 'QFS_QFL', 'get': 'getqflist()', 'event': ['BufEnter']}   "{{{2
endif


if !exists('g:quickfixsigns_class_loc')
    " Signs for |location| lists.
    let g:quickfixsigns_class_loc = {'sign': 'QFS_LOC', 'get': 'getloclist(winnr())', 'event': ['BufEnter']}   "{{{2
endif


if !exists('g:quickfixsigns_class_cursor')
    " Sign for the current cursor position
    let g:quickfixsigns_class_cursor = {'sign': 'QFS_CURSOR', 'get': 's:GetCursor()', 'event': g:quickfixsigns_events1}   "{{{2
endif


if !exists('g:quickfixsigns_balloon')
    " If non-null, display a balloon when hovering with the mouse over 
    " the sign.
    " buffer-local or global
    let g:quickfixsigns_balloon = 1   "{{{2
endif


if !exists('g:quickfixsigns_max')
    " Don't display signs if the list is longer than n items.
    let g:quickfixsigns_max = 100   "{{{2
endif



" ----------------------------------------------------------------------

redir => s:signss
silent sign list
redir END
let s:signs = split(s:signss, '\n')
call filter(s:signs, 'v:val =~ ''^sign QFS_''')
call map(s:signs, 'matchstr(v:val, ''^sign \zsQFS_\w\+'')')

if index(s:signs, 'QFS_QFL') == -1
    sign define QFS_QFL text=* texthl=WarningMsg
endif

if index(s:signs, 'QFS_LOC') == -1
    sign define QFS_LOC text=> texthl=Special
endif

if index(s:signs, 'QFS_CURSOR') == -1
    sign define QFS_CURSOR text=. texthl=Question
endif

sign define QFS_DUMMY text=. texthl=NonText

for s:i in g:quickfixsigns_marks
	if index(s:signs, 'QFS_Mark_'. s:i) == -1
		exec 'sign define QFS_Mark_'. s:i .' text='. s:i .' texthl=Identifier'
	endif
endfor
unlet s:i

let s:relmax = -1
function! s:GenRel(num) "{{{3
    " TLogVAR a:num
    " echom "DBG ". s:relmax
    if a:num > s:relmax && a:num < 100
        for n in range(s:relmax + 1, a:num)
            exec 'sign define QFS_REL_'. n .' text='. n .' texthl=LineNr'
        endfor
        let s:relmax = a:num
    endif
endf

let s:last_run = {}


function! QuickfixsignsSelect(list) "{{{3
	" FIXME: unset first
    let s:quickfixsigns_lists = {}
	for what in a:list
		let s:quickfixsigns_lists[what] = g:quickfixsigns_class_{what}
	endfor
endf
call QuickfixsignsSelect(g:quickfixsigns_classes)


" (Re-)Set the signs that should be updated at a certain event. If event 
" is empty, update all signs.
"
" Normally, the end-user doesn't need to call this function.
function! QuickfixsignsSet(event) "{{{3
    if exists("b:noquickfixsigns") && b:noquickfixsigns
        return
    endif
    " let lz = &lazyredraw
    " set lz
    " try
        let bn = bufnr('%')
        let anyway = empty(a:event)
        for def in values(s:quickfixsigns_lists)
            " if exists("b:noquickfixsigns") && b:noquickfixsigns
            "     call s:ClearBuffer(def.sign, bn, [])
            " elseif anyway || index(get(def, 'event', ['BufEnter']), a:event) != -1
            if anyway || index(get(def, 'event', ['BufEnter']), a:event) != -1
                let t_d = get(def, 'timeout', 0)
                let t_l = localtime()
                let t_s = string(def)
                " TLogVAR t_s, t_d, t_l
                if anyway || (t_d == 0) || (t_l - get(s:last_run, t_s, 0) >= t_d)
                    let s:last_run[t_s] = t_l
                    let list = eval(def.get)
                    " TLogVAR list
                    call filter(list, 'v:val.bufnr == bn')
                    " TLogVAR list
                    if !empty(list) && len(list) < g:quickfixsigns_max
                        let get_id = get(def, 'id', 's:SignId')
                        call s:ClearBuffer(def.sign, bn, s:PlaceSign(def.sign, list, get_id))
                        if has('balloon_eval') && g:quickfixsigns_balloon && !exists('b:quickfixsigns_balloon') && empty(&balloonexpr)
                            let b:quickfixsigns_ballooneval = &ballooneval
                            let b:quickfixsigns_balloonexpr = &balloonexpr
                            setlocal ballooneval balloonexpr=QuickfixsignsBalloon()
                            let b:quickfixsigns_balloon = 1
                        endif
                    else
                        call s:ClearBuffer(def.sign, bn, [])
                    endif
                endif
            endif
        endfor
    " finally
    "     if &lz != lz
    "         let &lz = lz
    "     endif
    " endtry
endf


function! QuickfixsignsBalloon() "{{{3
    " TLogVAR v:beval_lnum, v:beval_col
    if v:beval_col <= 1
        let lnum = v:beval_lnum
        let bn = bufnr('%')
        let acc = []
        for def in values(s:quickfixsigns_lists)
            let list = eval(def.get)
            call filter(list, 'v:val.bufnr == bn && v:val.lnum == lnum')
            if !empty(list)
                let acc += list
            endif
        endfor
        " TLogVAR acc
        return join(map(acc, 'v:val.text'), "\n")
    endif
    if exists('b:quickfixsigns_balloonexpr') && !empty(b:quickfixsigns_balloonexpr)
        return eval(b:quickfixsigns_balloonexpr)
    else
        return ''
    endif
endf


let s:cursor_last_line = 0

function! s:GetCursor() "{{{3
    let pos = getpos('.')
    let s:cursor_last_line = pos[1]
    return [{'bufnr': bufnr('%'), 'lnum': pos[1], 'col': pos[2], 'text': 'CURSOR'}]
endf


function! s:Marks() "{{{3
    let acc = []
    let bn  = bufnr('%')
    let ignore = exists('b:quickfixsigns_ignore_marks') ? b:quickfixsigns_ignore_marks : []
    for mark in g:quickfixsigns_marks
        let pos = getpos("'". mark)
        if (pos[0] == 0 || pos[0] == bn) && index(ignore, mark) == -1
            call add(acc, {'bufnr': bn, 'lnum': pos[1], 'col': pos[2], 'text': 'Mark_'. mark})
        endif
    endfor
    return acc
endf


function! s:MarkSign(item) "{{{3
    return 'QFS_'. a:item.text
endf


function! s:MarkId(item) "{{{3
    let bn = bufnr('%')
    let item = filter(values(s:register), 'v:val.bn == bn && get(v:val.item, "text", "") ==# get(a:item, "text", "")')
    if empty(item)
        return s:base + a:item.bufnr * 67 + char2nr(get(a:item, "text", "")[-1 : -1]) - 65
    else
        " TLogVAR item
        return item[0].idx
    endif
endf


function! s:RelSign(item) "{{{3
    return 'QFS_'. a:item.text
endf


function! s:GetRelList() "{{{3
	let lnum = line('.')
	let col = col('.')
	let bn = bufnr('%')
    let top = line('w0') - lnum
    let bot = line('w$') - lnum
    if g:quickfixsigns_class_rel.max >= 0
        let top = max([top, -g:quickfixsigns_class_rel.max])
        let bot = min([bot, g:quickfixsigns_class_rel.max])
    endif
    call s:GenRel(max([abs(top), abs(bot)]))
    return map(range(top, bot), '{"bufnr": bn, "lnum": lnum + v:val, "col": col, "text": "REL_". abs(v:val)}')
endf


let s:base = 5272
let s:register = {}


" Clear all signs with name SIGN.
function! QuickfixsignsClear(sign) "{{{3
    " TLogVAR a:sign_rx
    let idxs = filter(keys(s:register), 's:register[v:val].sign ==# a:sign')
    " TLogVAR idxs
    for idx in idxs
        exec 'sign unplace '. idx .' buffer='. s:register[idx].bn
        call remove(s:register, idx)
    endfor
endf


" Clear all signs with name SIGN in buffer BUFNR.
function! s:ClearBuffer(sign, bufnr, new_idxs) "{{{3
    " TLogVAR a:sign, a:bufnr, a:new_idxs
    let old_idxs = filter(keys(s:register), 's:register[v:val].sign ==# a:sign && s:register[v:val].bn == a:bufnr && index(a:new_idxs, v:val) == -1')
    " TLogVAR old_idxs
    for idx in old_idxs
        exec 'sign unplace '. idx .' buffer='. s:register[idx].bn
        call remove(s:register, idx)
    endfor
endf


function! s:ClearDummy(idx, bufnr) "{{{3
    exec 'sign unplace '. a:idx .' buffer='. a:bufnr
endf


function! s:SignId(item) "{{{3
    " TLogVAR a:item
    " let bn  = bufnr('%')
    let bn = get(a:item, 'bufnr', -1)
    if bn == -1
        return -1
    else
        let idx = s:base + bn * 427 + 1
        while has_key(s:register, idx)
            let idx += 1
        endwh
        return idx
    endif
endf


" Add signs for all locations in LIST. LIST must confirm with the 
" quickfix list format (see |getqflist()|; only the fields lnum and 
" bufnr are required).
"
" list:: a quickfix or location list
" sign:: a sign defined with |:sign-define|
function! s:PlaceSign(sign, list, ...) "{{{3
    " TAssertType a:sign, 'string'
    " TAssertType a:list, 'list'
    " TLogVAR a:sign, a:list
    let get_id = a:0 >= 1 ? a:1 : "<SID>SignId"
    " TLogVAR get_id
    let new_idxs = []
    for item in a:list
        " TLogVAR item
        if a:sign[0] == '*'
            let sign = call(a:sign[1 : -1], [item])
            " TLogVAR sign
        else
            let sign = a:sign
        endif
        let idx = call(get_id, [item])
        " TLogVAR idx, sign
        if idx > 0
            let bn   = get(item, 'bufnr')
            let sdef = {'sign': a:sign, 'bn': bn, 'item': item, 'idx': idx}
            call add(new_idxs, string(idx))
            if has_key(s:register, idx)
                if s:register[idx] == sdef
                    continue
                else
                    " TLogVAR item
                    " TLogDBG ':sign unplace '. idx .' buffer='. bn
                    exec ':sign unplace '. idx .' buffer='. bn
                    unlet s:register[idx]
                endif
            endif
            let lnum = get(item, 'lnum', 0)
            if lnum > 0
                " TLogVAR item
                " TLogDBG ':sign place '. idx .' line='. lnum .' name='. sign .' buffer='. bn
                exec ':sign place '. idx .' line='. lnum .' name='. sign .' buffer='. bn
                let s:register[idx] = {'sign': a:sign, 'bn': bn, 'item': item, 'idx': idx}
            endif
        endif
    endfor
    return new_idxs
endf


unlet s:signs s:signss


augroup QuickFixSigns
    autocmd!
    let s:ev_set = []
    for s:def in values(s:quickfixsigns_lists)
        for s:ev in get(s:def, 'event', ['BufEnter'])
            if index(s:ev_set, s:ev) == -1
                exec 'autocmd '. s:ev .' * call QuickfixsignsSet("'. s:ev .'")'
                call add(s:ev_set, s:ev)
            endif
        endfor
    endfor
    unlet s:ev_set s:ev s:def
    " autocmd BufRead,BufNewFile * exec 'sign place '. (s:base - 1) .' name=QFS_DUMMY line=1 buffer='. bufnr('%')
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release

0.2
- exists('b:quickfixsigns_balloonexpr')

0.3
- Old signs weren't always removed
- Avoid "flicker" etc.
- g:quickfixsigns_max: Don't display signs if the list is longer than n items.
Incompatible changes:
- Removed g:quickfixsigns_show_marks variable
- g:quickfixsigns_marks: Marks that should be used for signs
- g:quickfixsigns_lists: event field is a list
- g:quickfixsigns_lists: timeout field: don't re-display this list more often than n seconds

0.4
- FIX: Error when g:quickfixsigns_marks = [] (thanks Ingo Karkat)
- s:ClearBuffer: removed old code
- QuickfixsignsMarks(state): Switch the display of marks on/off.

0.5
- Set balloonexpr only if empty (don't try to be smart)
- Disable CursorMoved(I) events, when &lazyredraw isn't set.

0.6
- Don't require qfl.item.text to be set

0.7
- b:noquickfixsigns: If true, disable quickfixsigns for the current 
buffer (patch by Sergey Khorev; must be set before entering a buffer)
- b:quickfixsigns_ignore_marks: A list of ignored marks (per buffer)

0.8
- Support for relative line numbers
- QuickfixsignsSet command

