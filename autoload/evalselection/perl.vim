" perl.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.4

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#perl#Init() "{{{3
    if !has('perl')
        echoerr 'EvalSelection: +perl support is required'
    endif
endf


if !exists("*EvalSelectionCalculate")
    function! EvalSelectionCalculate(formula) "{{{3
        exec "perl VIM::Msg(". a:formula .")"
    endf
endif

function! EvalSelection_perl(cmd) "{{{3
    call evalselection#Eval("perl", a:cmd, "perl")
endf

if !hasmapto("EvalSelection_perl(")
    call EvalSelectionGenerateBindings("p", "perl")
endif

if g:evalSelectionPluginMenu != ""
    exec "amenu ". g:evalSelectionPluginMenu ."Perl:\\ Command\\ Line :EvalSelectionCmdLine perl<cr>"
end

command! EvalSelectionCmdLinePerl :EvalSelectionCmdLine perl


let &cpo = s:save_cpo
unlet s:save_cpo
