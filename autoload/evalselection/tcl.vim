" tcl.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.5

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#tcl#Init() "{{{3
    if !has('tcl')
        echoerr 'EvalSelection: +tcl support is required'
    endif
endf


if !exists("*EvalSelectionCalculate")
    function! EvalSelectionCalculate(formula) "{{{3
        call EvalSelection_mz_helper("puts [expr ". a:formula ."]")
    endf
endif

function! EvalSelection_tcl(cmd) "{{{3
    call evalselection#Eval("tcl", a:cmd, "call", "EvalSelection_tcl_helper('", "')")
endf

function! EvalSelection_tcl_helper(text) "{{{3
    redir @e
    exe "tcl ". a:text
    redir END
    let @e = substitute(@e, '\^M$', '', '')
endf

if !hasmapto("EvalSelection_tcl(")
    call EvalSelectionGenerateBindings("t", "tcl")
endif

if g:evalSelectionPluginMenu != ""
    exec "amenu ". g:evalSelectionPluginMenu ."TCL:\\ Command\\ Line :EvalSelectionCmdLine tcl<cr>"
end

command! EvalSelectionCmdLineTcl :EvalSelectionCmdLine tcl


let &cpo = s:save_cpo
unlet s:save_cpo
