" quickfixsigns.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-14.
" @Last Change: 2009-03-15.
" @Revision:    0.0.165

let s:save_cpo = &cpo
set cpo&vim


sign define QFS_QFL text=* texthl=WarningMsg
sign define QFS_LOC text=> texthl=Special

" let s:marks = split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ<>''`^.(){}[]', '\zs')
let s:marks = split('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', '\zs')

for s:i in s:marks
    exec 'sign define QFS_Mark_'. s:i .' text='. s:i .' texthl=Identifier'
endfor
unlet s:i


function! quickfixsigns#Set(event) "{{{3
    let bn = bufnr('%')
    for def in g:quickfixsigns_lists
        if def.event ==# a:event
            let get_id = get(def, 'id', '<SID>SignId')
            if empty(get_id)
                call quickfixsigns#ClearBuffer(def.sign, bn)
            endif
            let list = eval(def.get)
            " TLogVAR list
            call filter(list, 'v:val.bufnr == bn')
            " TLogVAR list
            if !empty(list)
                call quickfixsigns#Mark(def.sign, list, get_id)
                if has('balloon_eval')
                    let use_balloon = exists('b:quickfixsigns_balloon') ? b:quickfixsigns_balloon : g:quickfixsigns_balloon
                    if &balloonexpr != 'quickfixsigns#Balloon()' && use_balloon
                        let b:quickfixsigns_ballooneval = &ballooneval
                        let b:quickfixsigns_balloonexpr = &balloonexpr
                        setlocal ballooneval balloonexpr=quickfixsigns#Balloon()
                    endif
                endif
            " elseif exists('b:quickfixsigns_balloonexpr')
            "     let &l:balloonexpr = b:quickfixsigns_balloonexpr
            "     let &l:ballooneval = b:quickfixsigns_ballooneval
            "     unlet! b:quickfixsigns_balloonexpr b:quickfixsigns_ballooneval
            endif
        endif
    endfor
endf


function! quickfixsigns#Balloon() "{{{3
    " TLogVAR v:beval_lnum, v:beval_col
    if v:beval_col <= 1
        let lnum = v:beval_lnum
        let bn = bufnr('%')
        let acc = []
        for def in g:quickfixsigns_lists
            let list = eval(def.get)
            call filter(list, 'v:val.bufnr == bn && v:val.lnum == lnum')
            if !empty(list)
                let acc += list
            endif
        endfor
        " TLogVAR acc
        return join(map(acc, 'v:val.text'), "\n")
    endif
    if !empty(b:quickfixsigns_balloonexpr)
        return eval(b:quickfixsigns_balloonexpr)
    else
        return ''
    endif
endf


function! quickfixsigns#Marks() "{{{3
    let acc = []
    let bn  = bufnr('%')
    for mark in s:marks
        let pos = getpos("'". mark)
        if pos[0] == 0 || pos[0] == bn
            call add(acc, {'bufnr': bn, 'lnum': pos[1], 'col': pos[2], 'text': 'Mark_'. mark})
        endif
    endfor
    return acc
endf


function! quickfixsigns#MarkSign(item) "{{{3
    return 'QFS_'. a:item.text
endf


function! quickfixsigns#MarkId(item) "{{{3
    let bn = bufnr('%')
    let item = filter(values(s:register), 'v:val.bn == bn && v:val.item.text ==# a:item.text')
    if empty(item)
        return s:base + a:item.bufnr * 67 + char2nr(a:item.text[-1 : -1]) - 65
    else
        " TLogVAR item
        return item[0].idx
    endif
endf


let s:base = 5272
let s:register = {}


" Clear all signs with name SIGN in buffer BUFNR.
function! quickfixsigns#ClearBuffer(sign, bufnr) "{{{3
    for bn in keys(s:register)
        let idxs = keys(s:register)
        call filter(idxs, 's:register[v:val].sign ==# a:sign && s:register[v:val].bn == a:bufnr')
        " TLogVAR bns
        for idx in idxs
            exec 'sign unplace '. idx .' buffer='. s:register[idx].bn
            call remove(s:register, idx)
        endfor
    endfor
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
function! quickfixsigns#Mark(sign, list, ...) "{{{3
    " TAssertType a:sign, 'string'
    " TAssertType a:list, 'list'
    " TLogVAR a:sign, a:list
    let get_id = a:0 >= 1 ? a:1 : "<SID>SignId"
    " TLogVAR get_id
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
            let bn = get(item, 'bufnr')
            if has_key(s:register, idx)
                " TLogVAR item
                " TLogDBG ':sign unplace '. idx .' buffer='. bn
                exec ':sign unplace '. idx .' buffer='. bn
                unlet s:register[idx]
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
endf



let &cpo = s:save_cpo
unlet s:save_cpo
