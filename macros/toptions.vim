" toptions.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim-toptions)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-02.
" @Last Change: 2009-02-15.
" @Revision:    0.1.15

if &cp || exists("loaded_toptions")
    finish
endif
let loaded_toptions = 1

"""""""" Custom Options.  {{{1

let g:toptions = {}
let g:toptions_etc = []
let g:toptions_labels = {
            \ 'fdl': 'F', 
			\ }
			" \ 'et': {'type': 'bool'},
			" \ 'bin': {'type': 'bool'},
			" \ 'ai': {'type': 'bool'},

fun s:SetOptionLabel(option, field, value)
    if !has_key(g:toptions_labels, a:option)
        let g:toptions_labels[a:option] = {}
    endif
    let g:toptions_labels[a:option][a:field] = a:value
endf

fun! TResetOptions(options)
    if empty(a:options)
        let options = keys(g:toptions)
    else
        let options = a:options
    endif
    for name in options
        exec 'let &'. name .' = g:toptions[name]'
    endfor
endf

command! -nargs=* -bar TResetOptions :call TResetOptions([<f-args>])
command! -nargs=+ TSet let s:tmlargs=[<f-args>] 
            \ | for arg in s:tmlargs[1:-1]
                \ | if arg =~ '^[+-]\?='
                    \ | exec 'set '.s:tmlargs[0] . arg
                \ | elseif arg =~ '^:='
                    \ | call s:SetOptionLabel(s:tmlargs[0], 'type', 'bool')
                    \ | if arg =~ '^:=yes'
                        \ | exec 'set '.s:tmlargs[0]
                    \ | elseif arg =~ ':=no'
                        \ | exec 'set no'.s:tmlargs[0]
                    \ | endif
                \ | else
                    \ | exec 'let &'.s:tmlargs[0] .'='. arg
                \ | endif
            \ | endfor
            \ | exec 'let g:toptions[s:tmlargs[0]] = &'. s:tmlargs[0]
            \ | unlet s:tmlargs
" TSet cpo +=my -=M
" TSet ts 4
" TSet tw

" Diese Funktion wird von der Statuszeile gebraucht - da sie nur hier
" und sonst nirgends gebraucht wird, ist sie hier (sonst gehörte sie
" zu den Makros). Diese Funktion gibt in einem String zurück, welche
" der hier ausgewählten Funktionen gesetzt sind -> sieht nett aus, auf
" der Statuszeile.
fun! TOptionsSummary(...)
    let opt = "<". &syntax ."/". &fileformat .">"

    for [o, v] in items(g:toptions)
        exec 'let ov = &'.o
        if ov != v
            let type = ''
            if has_key(g:toptions_labels, o)
                let ol = g:toptions_labels[o]
				if type(ol) == 3 && type(o) == 0
                    let lab  = get(ol, o, '')
                elseif type(ol) == 4
					let type = get(ol, 'type', '')
					let lab  = get(ol, 'label', '')
				else
					let lab = ol
				endif
                unlet ol
            else
                let lab = o.'='
            endif
            if type == 'bool'
                if empty(lab)
                    " let opt .= ' ['. (ov ? '' : 'no') . o .']'
                    let opt .= ' '. (ov ? '+' : '-') . o
                else
                    let opt .= ' '. lab
                endif
            else
                let opt .= ' '. lab . ov
            endif
        endif
    endfor

    for o in g:toptions_etc
        exec o
    endfor
    " if &co > 80
        let opt=opt." | ".strftime(a:0 >= 1 ? a:1 : '%d-%b-%Y %H:%M')
    " endif
    return opt
endf

