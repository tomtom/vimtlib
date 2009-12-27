" ttagcomplete.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-11-02.
" @Last Change: 2009-12-26.
" @Revision:    0.0.217

if &cp || exists("loaded_ttagcomplete_autoload")
    finish
endif
let loaded_ttagcomplete_autoload = 1


let s:unsupported = {}


" function! ttagcomplete#On(?option="omni")
" If option is "complete", set 'completefunc' instead of 'omnifunc' (the 
" default).
" This will call ttagcomplete#{&filetype}#Init() if the variable 
" b:ttagcomplete_collect isn't already set. b:ttagcomplete_collect will 
" be set to a function that follows the protocol for |complete-functions|.
function! ttagcomplete#On(...) "{{{3
    TVarArg ['option', 'omni']
    if !get(s:unsupported, &filetype, 0)
        try
            if !exists('b:ttagcomplete_collect') && empty(b:ttagcomplete_collect)
                call ttagcomplete#{&filetype}#Init()
            endif
            if option == 'omni'
                let b:ttagcomplete_option_{option} = &omnifunc
                setlocal omnifunc=ttagcomplete#Complete
            elseif option == 'complete'
                let b:ttagcomplete_option_{option} = &completefunc
                setlocal completefunc=ttagcomplete#Complete
            else
                echoerr 'Unknown option: '. option
            endif
        catch
            let s:unsupported[&filetype] = 1
            echoerr 'Unsupported filetype: '. &filetype
        endtry
    endif
endf


function! ttagcomplete#Off(...) "{{{3
    TVarArg ['option', 'omni']
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
    " let pos = getpos('.')
    let view = winsaveview()
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
            " call setpos('.', pos)
            call winrestview(view)
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

