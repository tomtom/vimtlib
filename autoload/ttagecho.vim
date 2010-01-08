" ttagecho.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-10-28.
" @Last Change: 2010-01-05.
" @Revision:    0.0.215

" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


if !exists('g:ttagecho_char_rx')
    " Regexps to match keyword characters (in case you don't want to 
    " change iskeyword.
    " :read: let g:ttagecho_char_rx = {} "{{{2
    let g:ttagecho_char_rx = {
                \ 'vim': '\(\w\|#\)',
                \ }
endif


if !exists('g:ttagecho_balloon_limit')
    " The number of items to be displayed in the balloon popup. It will be 
    " evaluated with |eval()|, which is why it can also be a vim expression.
    let g:ttagecho_balloon_limit = '&lines * 2 / 3'   "{{{2
endif


if !exists('g:ttagecho_tagwidth')
    " The width of the tag "column". It will be evaluated with |eval()|, which 
    " is why it can also be a vim expression.
    let g:ttagecho_tagwidth = '&co / 3'  "{{{2
endif


if !exists('g:ttagecho_matchbeginning')
    " If true, match only the beginning of a tag (i.e. don't add '$' to 
    " the regexp).
    let g:ttagecho_matchbeginning = 0   "{{{2
endif


let s:echo_constraints = ''
let s:echo_index       = -1
let s:echo_tags        = []


" :def: function! ttagecho#Expr(rx, ?many_lines=0, ?bang=0, ?compact=0)
" Return a string representing the tags matching rx.
function! ttagecho#Expr(rx, ...) "{{{3
    let many_lines = a:0 >= 1 ? a:1 : 0
    let bang       = a:0 >= 2 ? a:2 : 0
    let compact    = a:0 >= 3 ? a:3 : 0
    let constraint = a:rx . bang
    " TLogVAR a:rx, many_lines, bang, compact
    if s:echo_constraints != constraint
	    let s:echo_constraints = constraint
        let s:echo_index       = -1
        let s:echo_tags = tlib#tag#Collect({'name': a:rx}, bang, 0)
	endif
    if !empty(s:echo_tags)
        let max_index    = len(s:echo_tags)
        let s:echo_index = (s:echo_index + 1) % max_index
        " TLogVAR tag
        if many_lines != 0
            let lines = len(s:echo_tags)
            if many_lines < 0
                let not_compact = lines > 1
                let many_lines = -many_lines
            else
                let not_compact = 1
            endif
            if many_lines > 0 && many_lines < lines
                let lines = many_lines
                let extra = '...'
            else
                let extra = ''
            endif
            " TLogVAR many_lines, lines
            let rv = map(range(lines), 's:FormatTag(v:val + 1, max_index, s:echo_tags[v:val], not_compact, compact)')
            if !empty(extra)
                call add(rv, extra)
            endif
            return join(rv, "\n")
        else
            let tag = s:echo_tags[s:echo_index]
            return s:FormatTag(s:echo_index + 1, max_index, tag, many_lines, compact)
        endif
    endif
    return ''
endf


function! s:FormatName(tag) "{{{3
    if exists('*TTagechoFormat_'. &filetype)
        let name = TTagechoFormat_{&filetype}(a:tag)
    else
        let name = tlib#tag#Format(a:tag)
    endif
    " TLogVAR a:tag, name
    return name
endf


function! s:FormatTag(index, max_index, tag, many_lines, compact) "{{{3
    let name = s:FormatName(a:tag)
    let wd = a:compact && !a:many_lines ? '' : '-'. eval(g:ttagecho_tagwidth)
    " TLogVAR a:compact, a:many_lines, a:max_index, wd
    let fmt  = '%s: %'. wd .'s | %s'
    if a:max_index == 1
        let rv = printf(fmt, a:tag.kind, name, fnamemodify(a:tag.filename, ":t"))
    else
        let rv = printf('%0'. len(a:max_index) .'d:'. fmt, a:index, a:tag.kind, name, fnamemodify(a:tag.filename, ":t"))
    endif
    return rv
endf


function! s:WordRx(word) "{{{3
    let rv = '\V\C\^'. escape(a:word, '\')
    if !g:ttagecho_matchbeginning
        let rv .= '\$'
    endif
    return rv
endf


" Echo the tag(s) matching rx.
function! ttagecho#Echo(rx, many_lines, bang) "{{{3
    " TLogVAR a:rx, a:many_lines, a:bang
    let expr = ttagecho#Expr(a:rx, a:many_lines, a:bang)
    if empty(expr)
        redraw
        " echo
    else
        redraw
        echohl Type
        if a:many_lines != 0
            echo expr
        else
            echo tlib#notify#TrimMessage(expr)
            " call tlib#notify#Echo(expr)
            " echo strpart(expr, 0, &columns - &fdc - 10)
        endif
        echohl NONE
    endif
endf


" Echo one match for the tag under cursor.
function! ttagecho#EchoWord(bang) "{{{3
    " TLogVAR a:bang
    call ttagecho#Echo('\V\C\^'. expand('<cword>') .'\$', 0, a:bang)
endf


" Echo all matches for the tag under cursor.
function! ttagecho#EchoWords(bang) "{{{3
    " TLogVAR a:bang
    call ttagecho#Echo('\V\C\^'. expand('<cword>') .'\$', -1, a:bang)
endf


" Echo the tag in front of an opening round parenthesis.
function! ttagecho#OverParanthesis(mode) "{{{3
    let line = getline('.')
    let scol = col('.') - 1
    let char = line[scol]
    if char == ')'
        let view = winsaveview()
        call searchpair('(', '', ')', 'bW')
        let scol = col('.') - 1
        call winrestview(view)
    endif
    " TLogVAR scol
    let line = strpart(line, 0, scol)
    let chrx = s:GetCharRx() .'\+$'
    let text = matchstr(line, chrx)
    " TLogVAR char, chrx, text, line
    if &showmode && a:mode == 'i' && g:ttagecho_restore_showmode != -1 && &cmdheight == 1
        let g:ttagecho_restore_showmode = 1
        " TLogVAR g:ttagecho_restore_showmode
        set noshowmode
    endif
    " TLogDBG 'Do the echo'
    call ttagecho#Echo(s:WordRx(text), 0, 0)
endf


" Return tag information for the tag under the mouse pointer (see 'balloonexpr')
function! ttagecho#Balloon() "{{{3
    " TLogVAR v:beval_lnum, v:beval_col
    let line = getline(v:beval_lnum)
    let chrx = s:GetCharRx()
    let text = matchstr(line, chrx .'*\%'. v:beval_col .'c'. chrx .'*')
    " TLogVAR text
    let balloon = ttagecho#Expr(s:WordRx(text), -eval(g:ttagecho_balloon_limit), 0, 1)
    if !empty(balloon)
        return balloon
    elseif exists('b:ttagecho_bexpr') && !empty(b:ttagecho_bexpr)
        return eval(b:ttagecho_bexpr)
    else
        return ''
    endif
endf


function! s:GetCharRx() "{{{3
    let chrx = tlib#var#Get('ttagecho_char_rx', 'wb', '')
    if empty(chrx)
        let chrx = get(g:ttagecho_char_rx, 'vim', '\w')
    endif
    " TLogVAR chrx
    return chrx
endf

