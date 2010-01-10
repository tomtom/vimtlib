" tinymode_tml.vim
" @Author:      Tom Link (micathom AT gmail com)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-09.
" @Last Change: 2010-01-09.
" @Revision:    3

if &cp || exists("loaded_tinymode_tml")
    finish
endif
let loaded_tinymode_tml = 1

let s:save_cpo = &cpo
set cpo&vim


" Move paragraphs
call tinymode#EnterMap("para_move", "gp")
call tinymode#ModeMsg("para_move", "Move paragraph: j/k")
call tinymode#Map("para_move", "j", "silent call tlib#paragraph#Move('Down', '[N]')")
call tinymode#Map("para_move", "k", "silent call tlib#paragraph#Move('Up', '[N]')")
call tinymode#ModeArg("para_move", "owncount", 1)


let &cpo = s:save_cpo
unlet s:save_cpo
