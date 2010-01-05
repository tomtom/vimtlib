" smartcasereplace.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.4

let s:save_cpo = &cpo
set cpo&vim
" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


function! s:SmartCaseReplaceGetText(text, pattern, replace, transformer)
    if g:smartCaseReplaceFeedback
        let line = line('.')
        if line - s:line > g:smartCaseReplaceFeedback
            let s:count += 1
            let s:line = line
            let &statusline = 'SmartCaseReplace: '. s:count .' @ '. line
            redrawstatus
        endif
    endif
    let text = submatch(0)
    let ee   = ''
    let rpl  = substitute(text, a:pattern, a:replace, '')
    if g:smartCaseReplaceInversion
        let tlow = tolower(rpl)
        let inv = (a:replace[0] == toupper(a:replace[0]))
    else
        let tlow = rpl
        let inv = 0
    endif
    let tupp = toupper(rpl)
    let low  = inv
    let upp  = !inv
    let i    = 0
    let me   = strlen(text)
    let mt   = strlen(rpl)
    let m    = me < mt ? me : mt
    while i < m
        let c = text[i]
        if (inv ? c ==# toupper(c) : c ==# tolower(c))
            let low = !inv
            let ee  = ee . tlow[i]
        else
            let upp = inv
            let ee  = ee . tupp[i]
        endif
        let i = i + 1
    endwh
    if i < mt
        if (!inv && low) || (inv && !upp)
            let ee = ee . strpart(tlow, i)
        else
            let ee = ee . strpart(tupp, i)
        endif
    endif
    if !empty(a:transformer)
        exec 'let ee = '. substitute(a:transformer, 'v:val', string(ee), 'g')
    endif
    return ee
endf

function! smartcasereplace#Replace(line1, line2, findreplace)
    if g:smartCaseReplaceFeedback
        let sl = &statusline
        let s:line  = a:line1
        let s:count = 0
    endif
    try
        let sep0 = a:findreplace[0]
        let sepp = '\V\[^\\]\zs'. escape(sep0, '\')
        let args        = split(a:findreplace[1:-1], sepp)
        let find        = get(args, 0, '')
        let replace     = get(args, 1, '')
        let mode        = get(args, 2, 'gc')
        let transformer = get(args, 3, '')
        if &smartcase
            let find = tolower(find)
        endif
        let find = '\c'.find
        let x = a:line1.','.a:line2.'s'. sep0 
                    \ .find
                    \ .sep0.'\=s:SmartCaseReplaceGetText(submatch(0), '. string(find) .', '. string(replace) .', '. string(transformer) .')'
                    \ .sep0.mode
        " echom x
        exec x
    finally
        if g:smartCaseReplaceFeedback
            let &statusline = sl
        endif
    endtry
endf



let &cpo = s:save_cpo
unlet s:save_cpo
