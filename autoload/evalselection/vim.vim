" vim.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.4

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#vim#Init() "{{{3
endf


function! EvalSelection_vim(cmd) "{{{3
    let @e = substitute("\n". @e ."\n", '\n\s*".\{-}\ze\n', "", "g")
    " let @e = substitute(@e, "^\\(\n*\\s\\+\\)\\+\\|\\(\\s\\+\n*\\)\\+$", "", "g")
    let @e = substitute(@e, "\n\\s\\+\\\\", " ", "g")
    " let @e = substitute(@e, "\n\\s\\+", "\n", "g")
    call evalselection#Eval("vim", a:cmd, "normal", ":", "\n", "\n:")
    " call evalselection#Eval("vim", a:cmd, "")
endf

if !hasmapto("EvalSelection_vim(") "{{{2
    call EvalSelectionGenerateBindings("v", "vim")
endif


let &cpo = s:save_cpo
unlet s:save_cpo
