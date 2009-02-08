" concordance.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-13.
" @Last Change: 2008-07-13.
" @Revision:    0.0.29

if &cp || exists("loaded_concordance_autoload")
    finish
endif
let loaded_concordance_autoload = 1
let s:save_cpo = &cpo
set cpo&vim


function! concordance#Concordance() "{{{3
    let w = copy(g:concordance_world)
    let w.base = concordance#Collect(w)
    call tlib#input#ListD(w)
endf


function! concordance#Collect(world) "{{{3
    let s:data = {}
    let lno = 1
    for line in getline(0, '$')
        let wno = 1
        for word in split(line, '[[:punct:][:space:][:digit:]]\+')
            let wid = lno .'-'. wno
            if has_key(s:data, word)
                call add(s:data[word], wid)
            else
                let s:data[word] = [wid]
            endif
            let wno += 1
        endfor
        let lno += 1
    endfor
    let s:words = map(copy(items(s:data)), 'v:val[0] ." (". len(v:val[1]) ."): ". join(v:val[1], " ")')
    return s:words
endf


let &cpo = s:save_cpo
unlet s:save_cpo
