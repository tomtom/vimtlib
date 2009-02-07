" linglang.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-11.
" @Last Change: 2008-07-12.
" @Revision:    0.0.131

if &cp || exists("loaded_linglang_autoload")
    finish
endif
let loaded_linglang_autoload = 1
let s:save_cpo = &cpo
set cpo&vim

let s:language_rx = {}
let s:dir = expand('<sfile>:p:h')

function! s:Initialize(langenc) "{{{3
    if has_key(s:language_rx, a:langenc)
        return
    endif

    " TLogVAR a:langenc
    let words = []
    let patts = []
    let file  = s:dir .'/linglang/'. a:langenc
    if filereadable(file)
        for line in readfile(file)
            " TLogVAR line
            if line =~ '^\s*/.\{-}/\s*$'
                call add(patts, substitute(line, '^\s*/\(.\{-}\)/\s*$', '\1', ''))
            else
                call add(words, line)
            endif
        endfor
        " TLogVAR words
        if !empty(words)
            call add(patts, '\<\('. join(words, '\|') .'\)\>')
        endif
        " TLogVAR patts
        if !empty(patts)
            let s:language_rx[a:langenc] = '\c'. join(patts, '\|')
        endif
    endif
endf


function! linglang#Linglang(...) "{{{3
    let verbose = a:0 >= 1 ? a:1 : 1
    if exists('b:linglang')
        call hookcursormoved#Register("linechange", "linglang#Set", '', 1)
        unlet b:linglang
        if verbose
            echom 'Linglang off'
        endif
    else
        call hookcursormoved#Register("linechange", "linglang#Set")
        if a:0 >= 2
            let b:linglang = []
            for i in range(2, a:0)
                let langenc = a:{i} .'.'. &encoding
                call s:Initialize(langenc)
                call add(b:linglang, langenc)
            endfor
        else
            for lang in keys(g:linglang_actions)
                call s:Initialize(lang)
            endfor
            let b:linglang = map(keys(s:language_rx), 'v:val .".". &encoding')
        endif
        if verbose
            echom 'Linglang on'
        endif
    endif
endf


" :def: function! linglang#Set(mode, ?condition_name=b:hookcursormoved_syntax)
function! linglang#Set(mode, ...) "{{{3
    " let condition_name = a:0 >= 1 ? a:1 : b:hookcursormoved_linechange
    " TLogVAR a:mode
    let line = getline('.')
    " TLogVAR line, b:linglang
    " call TLogDBG(string(s:language_rx))
    let lang = filter(copy(b:linglang), 'line =~ s:language_rx[v:val]')
    " TLogVAR lang
    if len(lang) == 1
        call s:Set(lang[0])
    else
        let score0 = 0
        let lang0 = ''
        let words = split(line, '[[:space:][:punct:]]\+')
        for lang1 in b:linglang
            let rx1 = s:language_rx[lang1]
            let score1 = len(filter(copy(words), 'v:val =~ rx1'))
            if score1 > score0
                " TLogVAR lang1, score1
                let lang0 = lang1
                let score0 = score1
            endif
        endfor
        if !empty(lang0)
            call s:Set(lang0)
        endif

    endif
endf


function! s:Set(langenc) "{{{3
    if !exists('b:linglang_last') || b:linglang_last != a:langenc
        let b:linglang_last = a:langenc
        let lang = substitute(a:langenc, '\..*$', '', '')
        " TLogVAR a:langenc, lang
        exec get(g:linglang_actions, lang, '')
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
