" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-01.
" @Last Change: 2009-03-06.
" @Revision:    112

let s:save_cpo = &cpo
set cpo&vim


function! s:Init(options) "{{{3
    " TLogVAR a:options
    let s:options_initial = {}
    for o in keys(a:options)
        exec 'let s:options_initial[o] = '. o
    endfor
endf


function! spec#speckiller#Reset() "{{{3
    " TLog "SpecKiller: Reset"
    if exists('s:options_initial')
        for o in keys(s:options_initial)
            exec 'let '. o .' = s:options_initial[o]'
        endfor
    endif
endf


" Return the i'th option set.
function! spec#speckiller#OptionSets(options, i) "{{{3
    " TLog "spec#speckiller#OptionSets"
    " TLogVAR a:options, a:i
    if a:i >= len(a:options)
        return 0
    endif
    let options = a:options[a:i]
    call s:Init(options)
    for [name, value] in items(options)
        exec 'let '. name .' = value'
        " TLog name
    endfor
    return 1
endf


let &cpo = s:save_cpo
unlet s:save_cpo
