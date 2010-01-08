" mzscheme.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-07.
" @Revision:    0.0.5

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#mzscheme#Init() "{{{3
    if !has('mzscheme')
        echoerr 'EvalSelection: +mzscheme support is required'
    endif
endf


if !exists("*EvalSelectionCalculate")
    function! EvalSelectionCalculate(formula) "{{{3
        call EvalSelection_mz_helper("(display (". a:formula ."))")
    endf
endif

function! EvalSelection_mz(cmd) "{{{3
    call evalselection#Eval("mz", a:cmd, "call", "EvalSelection_mz_helper('", "')")
endf

function! EvalSelection_mz_helper(text) "{{{3
    redir @e
    exe "mz ". a:text
    redir END
    let @e = substitute(@e, '\^M$', '', '')
endf

if !hasmapto("EvalSelection_mz(")
    call EvalSelectionGenerateBindings("z", "mz")
endif

if g:evalSelectionPluginMenu != ''
    exec 'amenu '. g:evalSelectionPluginMenu .'MzScheme:\ Command\ Line :EvalSelectionCmdLine mz<cr>'
end

command! EvalSelectionCmdLineMz :EvalSelectionCmdLine mz


let &cpo = s:save_cpo
unlet s:save_cpo
