" sh.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.4

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#sh#Init() "{{{3
endf

function! EvalSelection_sh(cmd) "{{{3
    let @e = substitute(@e, '\_^#.*\_$', "", "g")
    let @e = substitute(@e, "\\_^\\s*\\|\\s*\\_$\\|\n$", "", "g")
    let @e = substitute(@e, "\n\\+", "; ", "g")
    call evalselection#Eval("sh", a:cmd, "", "echo evalselection#System('", "')", "; ")
endf

if !hasmapto("EvalSelection_sh(") "{{{2
    call EvalSelectionGenerateBindings("s", "sh")
endif

if g:evalSelectionPluginMenu != ""
    exec "amenu ". g:evalSelectionPluginMenu ."Shell:\\ Command\\ Line :EvalSelectionCmdLine sh<cr>"
end

command! EvalSelectionCmdLineSh :EvalSelectionCmdLine sh


let &cpo = s:save_cpo
unlet s:save_cpo
