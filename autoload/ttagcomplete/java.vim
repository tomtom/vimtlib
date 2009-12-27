" java.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-12-26.
" @Last Change: 2009-12-26.
" @Revision:    0.0.5

let s:save_cpo = &cpo
set cpo&vim


function! ttagcomplete#java#Init() "{{{3
    let b:ttagcomplete_collect = 'ttagcomplete#java#Collect'
endf


function! ttagcomplete#java#Collect(constraints, base, context) "{{{3
    " TLogVAR a:constraints, a:base, a:context
    let ml = matchstr(a:context, '\C\<\zs\u\w*\ze\.\w*$')
    if !empty(ml)
        " TLogDBG 'Class or constant'
        " TLogVAR ml
        let a:constraints.class = ml
        " TLogVAR a:constraints.class
        return a:constraints
    endif

    let ml = matchstr(a:context, '\C\<\zs\l\w*\ze\.\w*$')
    if !empty(ml) && ml != 'this'
        " TLogDBG 'Method or field'
        " TLogVAR ml
        let class = ttagcomplete#java#FindClass(ml)
        " TLogVAR class
        if !empty(class)
            let a:constraints.class = class
            " TLogVAR a:constraints.class
        else
            let class = ttagcomplete#java#FindClassInTags(ml)
            if !empty(class)
                let a:constraints.class = class
                " TLogVAR a:constraints.class
            endif
        endif
        return a:constraints
    endif

    if a:base =~ '\C^\u'
        " TLogDBG 'base is a class or constant'
        let a:constraints.kind = 'cf'
        " TLogVAR a:constraints.kind
        return a:constraints
    endif

    " TLogDBG 'Current method or field'
    " import statements are currently ignored.
    let a:constraints.class = expand('%:t:r')
    let a:constraints.kind = 'mf'
    " TLogVAR a:constraints.class, a:constraints.kind
    return a:constraints
endf


function! ttagcomplete#java#FindClass(name) "{{{3
    " let pos = getpos('.')
    let view = winsaveview()
    try
        let rx   = '\(^\C\s*\(\(@\w\+\((.\{-})\)\?\|final\|public\|private\|protected\)\s\+\)*\|(\([^,]\+,\s*\)*\)\(\u\w*\|void\|int\|boolean\|double\|float\|byte\|char\)\(<.\{-}>\)*\(\[\]\)*\s\+'.tlib#rx#Escape(a:name)
        let line = search(rx, 'bnw')
        " TLogVAR rx, line
        if line
            let ml = matchlist(getline(line), rx)
            " TLogVAR ml
            return ml[6]
        endif
    finally
        " call setpos('.', pos)
        call winrestview(view)
    endtry
    return ''
endf


function! ttagcomplete#java#FindClassInTags(name) "{{{3
    let trx  = tlib#rx#Escape(a:name)
    let tags = tlib#tag#Collect({'name': trx}, g:ttagecho_use_extra)
    " TLogVAR a:name, trx, tags
    let rx   = []
    for tag in tags
        let ml = matchstr(tag.cmd, '\C\<\u\w*\(<.\{-}>\)*\(\[\]\)*\ze\s\+'. trx)
        " TLogVAR ml, tag
        if !empty(ml)
            call add(rx, tlib#rx#Escape(ml))
        endif
    endfor
    " TLogVAR rx
    return join(rx, '\|')
endf


let &cpo = s:save_cpo
unlet s:save_cpo
