" calculate.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.4

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#calculate#Init() "{{{3
endf

" Use vim as a fallback for performing calculations
if !exists("*EvalSelectionCalculate") "{{{2
    function! EvalSelectionCalculate(formula) "{{{3
        exec "echo ". a:formula
    endf    
endif

function! EvalSelection_calculate(cmd) "{{{3
    if @e =~ '\s*=\s*$'
        let @e = substitute(@e, '\s*=\s*$', '', '')
    endif
    call evalselection#Eval("calculate", a:cmd, "", "call EvalSelectionCalculate('", "')")
    let @e = substitute(@e, '^\s\+', '', '')
    return @e
endf

if !hasmapto("EvalSelection_calculate(") "{{{2
    call EvalSelectionGenerateBindings("e", "calculate")
endif

if g:evalSelectionPluginMenu != ""
    exec "amenu ". g:evalSelectionPluginMenu ."Calculator:\\ Command\\ Line :EvalSelectionCmdLine calculate<cr>"
    exec "amenu ". g:evalSelectionPluginMenu ."--SepEvalSelectionMenu-- :"
end

command! EvalSelectionCmdLineCalculator :EvalSelectionCmdLine calculate


let &cpo = s:save_cpo
unlet s:save_cpo
