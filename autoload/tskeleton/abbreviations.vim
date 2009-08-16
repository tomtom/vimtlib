" abbreviations.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-09-15.
" @Last Change: 2009-08-11.
" @Revision:    0.0.62

if &cp || exists("loaded_tskeleton_abbreviations_autoload")
    finish
endif
let loaded_tskeleton_abbreviations_autoload = 1


function! tskeleton#abbreviations#Reset() "{{{3
    let s:abbrevs = tlib#cmd#OutputAsList('abbrev')
endf


function! tskeleton#abbreviations#Initialize() "{{{3
    call tskeleton#abbreviations#Reset()
endf


function! tskeleton#abbreviations#GetAbbreviations() "{{{3
    if !exists('s:abbrev')
        call tskeleton#abbreviations#Reset()
    endif
    return s:abbrev
endf


function! tskeleton#abbreviations#BufferBits(dict, filetype) "{{{3
    call filter(s:abbrevs, 'v:val =~ ''^[i!]''')
    let rx = '^\(.\)\s\+\(\S\+\)\s\+\(.\+\)$'
    for abbr in sort(s:abbrevs)
        let matches = matchlist(abbr, rx)
        " TLogVAR abbr, rx, matches
        let name = matches[2]
        " TLogVAR name
        " TLogDBG has_key(a:dict, name.g:tskelAbbrevPostfix)
        let text = matches[3]
        if text !~ printf(tlib#rx#Escape(tskeleton#ExpandedAbbreviationTemplate()), '.\{-}')
            let a:dict[name] = {
                        \ 'text': text,
                        \ 'abbrev_type': matches[1],
                        \ 'abbrev': '',
                        \ 'menu': 'Abbreviation.'. escape(name, '.\'),
                        \ 'type': 'abbreviations'
                        \ }
        endif
    endfor
endf


function! tskeleton#abbreviations#Retrieve(bit, indent, ft) "{{{3
    let def = tskeleton#BitDef(a:bit)
    let text = def.text
    " let text .= tskeleton#CursorMarker()
    " TLogVAR a:bit, a:def
    " if text[0] == '@'
    "     exec 'norm! i'. text[1:-1]
    " else
    "     exec 'norm! i'. text
    " endif
    exec 'norm i'. a:bit
    call tlib#buffer#InsertText0(tskeleton#CursorMarker())
    return line('.')
endf


