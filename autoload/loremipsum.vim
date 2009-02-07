" loremipsum.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-10.
" @Last Change: 2008-07-11.
" @Revision:    0.0.138

if &cp || exists("loaded_loremipsum_autoload")
    finish
endif
let loaded_loremipsum_autoload = 1
let s:save_cpo = &cpo
set cpo&vim

" http://www.lorem-ipsum-dolor-sit-amet.com/lorem-ipsum-dolor-sit-amet.html
let s:data = expand('<sfile>:p:h') .'/loremipsum.txt'


function! s:GetWords(nwords, splitrx, join) "{{{3
    if exists('b:loremipsum_file')
        let file = b:loremipsum_file
    else
        let file = get(g:loremipsum_files, &spelllang, s:data)
    endif
    let text  = split(join(readfile(file), "\n"), a:splitrx)
    let start = (localtime() * -23) % (len(text) - a:nwords)
    let start = start < 0 ? -start : start
    let out   = join(text[start : start + a:nwords], a:join)
    let out   = substitute(out, '^\s*\zs\S', '\u&', '')
    if out !~ '\.\s*$'
        let out = substitute(out, '[[:punct:][:space:]]*$', '.', '')
    endif
    return out
endf


function! s:NoInline(flags) "{{{3
    return get(a:flags, 0, 0)
endf


function! s:WrapMarker(marker, text) "{{{3
    if len(a:marker) >= 2
        let [pre, post; flags] = a:marker
        if type(a:text) == 1
            if s:NoInline(flags)
                return a:text
            else
                return pre . a:text . post
            endif
        else
            call insert(a:text, pre)
            call add(a:text, post)
            return a:text
        endif
    else
        return a:text
    endif
endf


function! loremipsum#Generate(nwords, template) "{{{3
    let out = s:GetWords(a:nwords, '\s\+\zs', '')
    let paras = split(out, '\n')
    if empty(a:template) || a:template == '*'
        let template = get(g:loremipsum_paragraph_template, &filetype, '')
    elseif a:template == '_'
        let template = ''
    else
        let template = a:template
    endif
    if !empty(template)
        call map(paras, 'v:val =~ ''\S'' ? printf(template, v:val) : v:val')
    end
    return paras
endf


function! loremipsum#GenerateInline(nwords) "{{{3
    let out = s:GetWords(a:nwords, '[[:space:]\n]\+', ' ')
    " let out = substitute(out, '[[:punct:][:space:]]*$', '', '')
    " let out = substitute(out, '[.?!]\(\s*.\)', ';\L\1', 'g')
    return out
endf


" :display: loremipsum#Insert(?inline=0, ?nwords=100, " ?template='', ?pre='', ?post='')
function! loremipsum#Insert(...) "{{{3
    let inline = a:0 >= 1 ? !empty(a:1) : 0
    let nwords = a:0 >= 2 ? a:2 : g:loremipsum_words
    let template = a:0 >= 3 ? a:3 : ''
    if a:0 >= 5
        let marker = [a:4, a:5]
    elseif a:0 >= 4
        if a:4 == '_'
            let marker = []
        else
            echoerr 'Loremipsum: No postfix defined'
        endif
    else
        let marker = get(g:loremipsum_marker, &filetype, [])
    endif
    " TLogVAR inline, nwords, template
    if inline
        let t = @t
        try
            let @t = s:WrapMarker(marker, loremipsum#GenerateInline(nwords))
            norm! "tp
        finally
            let @t = t
        endtry
    else
        let text = s:WrapMarker(marker, loremipsum#Generate(nwords, template))
        let lno  = line('.')
        if getline(lno) !~ '\S'
            let lno -= 1
        endif
        call append(lno, text)
        exec 'norm! '. lno .'gggq'. len(text) ."j"
    endif
endf


function! loremipsum#Replace(...) "{{{3
    let replace = a:0 >= 1 ? a:1 : ''
    if a:0 >= 3
        let marker = [a:2, a:3]
    else
        let marker = get(g:loremipsum_marker, &filetype, [])
    endif
    if len(marker) >= 2
        let [pre, post; flags] = marker
        let pre  = escape(pre, '\/')
        let post = escape(post, '\/')
        if s:NoInline(flags)
            let pre  = '\^\s\*'. pre  .'\s\*\n'
            let post = '\n\s\*'. post .'\s\*\n'
            let replace .= "\<c-m>"
        endif
        let rx  = '\V'. pre .'\_.\{-}'. post
        let rpl = escape(replace, '\&~/')
        let sr  = @/
        try
            " TLogVAR rx, rpl
            exec '%s/'. rx .'/'. rpl .'/ge'
        finally
            let @/ = sr
        endtry
    else
        echoerr 'Loremipsum: No marker for '. &filetype
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
