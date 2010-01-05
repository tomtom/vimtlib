" ruby.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.6

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#ruby#Init() "{{{3
    if !has('ruby')
        echoerr 'EvalSelection: +ruby support is required'
    endif
endf


if !exists("*EvalSelectionCalculate")
    function! EvalSelectionCalculate(formula) "{{{3
        exec "ruby p ". a:formula
    endf
endif

function! EvalSelection_ruby(cmd) "{{{3
    let @e = substitute(@e, '\_^#.*\_$', "", "g")
    call evalselection#Eval("ruby", a:cmd, "ruby")
endf

if !hasmapto("EvalSelection_ruby(")
    call EvalSelectionGenerateBindings("r", "ruby")
endif

if g:evalSelectionPluginMenu != ""
    exec "amenu ". g:evalSelectionPluginMenu ."Ruby:\\ Command\\ Line :EvalSelectionCmdLine ruby<cr>"
end

command! EvalSelectionCmdLineRuby :EvalSelectionCmdLine ruby


let &cpo = s:save_cpo
unlet s:save_cpo
