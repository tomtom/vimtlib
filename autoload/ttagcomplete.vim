" ttagcomplete.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-11-02.
" @Last Change: 2007-11-11.
" @Revision:    0.0.197

if &cp || exists("loaded_ttagcomplete_autoload")
    finish
endif
let loaded_ttagcomplete_autoload = 1


" function! ttagcomplete#On(?option="omni")
" If option is "complete", set 'completefunc' instead of 'omnifunc' (the 
" default).
function! ttagcomplete#On(...) "{{{3
    TVarArg ['option', 'omni']
    let var = 'option_'. option
    if option == 'omni'
        let b:ttagcomplete_option_{option} = &omnifunc
        setlocal omnifunc=ttagcomplete#Complete
    elseif option == 'complete'
        let b:ttagcomplete_option_{option} = &completefunc
        setlocal completefunc=ttagcomplete#Complete
    else
        echoerr 'Unknown option: '. option
    endif
endf


function! ttagcomplete#Off(...) "{{{3
    TVarArg ['option', 'omni']
    let var = 'option_'. option
    if option == 'omni'
        if exists('b:ttagcomplete_option_'.option)
            let &l:omnifunc=b:ttagcomplete_option_{option}
        endif
    elseif option == 'complete'
        if exists('b:ttagcomplete_option_'.option)
            let &l:completefunc=b:ttagcomplete_option_{option}
        endif
    else
        echoerr 'Unknown option: '. option
    endif
endf


function! ttagcomplete#CompleteSkeletons(...) "{{{3
    TVarArg ['expand_kinds', '[:alnum:]']
    let pos = getpos('.')
    let start  = s:Complete(1, '')
    let lineno = line('.')
    let line   = getline(lineno)
    let col    = col('.')
    let base   = strpart(line, start)
    if g:ttagecho_min_chars > 0 && len(base) < g:ttagecho_min_chars
        echohl error
        echom 'Too few characters (min: '. g:ttagecho_min_chars .'): '. string(base)
        echohl NONE
        return
    endif
    let tags   = s:Complete(0, base)
    if !empty(tags)
        if len(tags) > 1
            let taglist = copy(tags)
            call map(taglist, 'printf("%-'. (&co / 3) .'s | %s (%s)", tlib#tag#Format(v:val), fnamemodify(v:val.filename, ":t"), fnamemodify(v:val.filename, ":p:h"))')
            " , [{'filter': base}]
            let tagidx  = tlib#input#List('si', 'Select tag', taglist)
            " TLogVAR tagidx
            if tagidx > 0
                let tag = tags[tagidx - 1]
            else
                let tag = {}
            endif
        else
            let tag = tags[0]
        endif
        if !empty(tag)
            if !empty(expand_kinds) && exists('g:loaded_tskeleton') && g:loaded_tskeleton >= 402
                let text = s:TSkeletonTemplate(expand_kinds, tag, '\.\.\.')
            else
                let text = tag.name
            endif
            let line = line[0 : start - 1] . text
            call tlib#buffer#ReplaceRange(lineno, lineno, [line])
            call setpos('.', pos)
            call tskeleton#SetCursor(lineno, lineno)
        endif
    endif
endf


function! ttagcomplete#Complete(findstart, base) "{{{3
    if a:findstart
        return s:Complete(a:findstart, a:base)
    else
        let tags = s:Complete(a:findstart, a:base)
        call map(tags, 'v:val.name')
        return tags
    endif
endf

function! s:Complete(findstart, base) "{{{3
    " TLogVAR a:findstart, a:base
    let line = getline('.')
    let start = col('.')
    if a:findstart
        let start -= 1
        while start > 0 && line[start - 1] =~ '\a'
            let start -= 1
        endwhile
        return start
    else
        let constraints = copy(tlib#var#Get('ttagcomplete_constraints', 'bg'))
        let constraints.name = tlib#rx#Escape(a:base)
        let context = strpart(line, 0, start)
        if exists('b:ttagcomplete_collect')
            call call(b:ttagcomplete_collect, [constraints, a:base, context])
        endif
        if exists('*TTagcomplete_collect_'. &filetype)
            call TTagcomplete_{&filetype}(constraints, a:base, context)
        endif
        " TLogVAR constraints
        let tags = tlib#tag#Collect(constraints, g:ttagecho_use_extra, 0)
        " TLogDBG len(tags)
        return tags
    endif
endf


function! s:TSkeletonTemplate(kinds, tag, restarg) "{{{3
    let dict = {}
    let rv = tskeleton#ProcessTag_functions_with_parentheses(a:kinds, dict, a:tag, a:restarg)
    " TLogVAR a:tag, rv, dict
    if empty(rv)
        return a:tag.name . tskeleton#CursorMarker()
    else
        return get(dict[rv], 'text', a:tag.name)
    endif
endf


function! ttagcomplete#Java(constraints, base, context) "{{{3
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
        let class = ttagcomplete#FindJavaClass(ml)
        if !empty(class)
            let a:constraints.class = class
            " TLogVAR a:constraints.class
        else
            let class = ttagcomplete#FindJavaClassInTags(ml)
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


function! ttagcomplete#FindJavaClass(name) "{{{3
    let pos = getpos('.')
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
        call setpos('.', pos)
    endtry
    return ''
endf


function! ttagcomplete#FindJavaClassInTags(name) "{{{3
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


