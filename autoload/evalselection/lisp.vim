" lisp.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.6

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#lisp#Init() "{{{3
    if !has('ruby')
        echoerr 'EvalSelection: +ruby support is required'
    endif
endf


"Lisp
if exists("g:evalSelectionLispInterpreter") "{{{2
    if g:evalSelectionLispInterpreter ==? "CLisp"
        if !exists("g:evalSelectionLispCmdLine")
            let g:evalSelectionLispCmdLine = 'clisp --quiet'
        endif
    
        ruby << EOR
        class EvalSelectionLisp < EvalSelectionInterpreter
            def setup
                @iid            = VIM::evaluate("g:evalSelectionLispInterpreter")
                @interpreter    = VIM::evaluate("g:evalSelectionLispCmdLine")
                @printFn        = ":q(let ((rv (list (ignore-errors %{BODY})))) (if (= (length rv) 1) (car rv) rv))"
                @quitFn         = "(quit)"
                @recPromptRx    = "\n(Break \\d\\+ )?\\[\\d+\\]\\> "
                @recSkip        = 1
                @useNthRec      = 1
            end

            def postprocess(text)
                text.sub(/^\n/, "")
            end
        end
EOR
    endif

    function! EvalSelection_lisp(cmd) "{{{3
        let @e = escape(@e, '\"')
        call evalselection#Eval("lisp", a:cmd, "",  
                    \ 'call evalselection#Talk(g:evalSelectionLispInterpreter, "', '")')
    endf
    
    if !hasmapto("EvalSelection_lisp(")
        call EvalSelectionGenerateBindings("l", "lisp")
    endif
    
    command! EvalSelectionSetupLisp ruby EvalSelection.setup(VIM::evaluate("g:evalSelectionLispInterpreter"), EvalSelectionLisp)
    command! EvalSelectionQuitLisp  ruby EvalSelection.tear_down(VIM::evaluate("g:evalSelectionLispInterpreter"))
    command! EvalSelectionCmdLineLisp call evalselection#CmdLine("lisp")
    if g:evalSelectionPluginMenu != ""
        exec "amenu ". g:evalSelectionPluginMenu ."Lisp.Setup :EvalSelectionSetupLisp<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."Lisp.Command\\ Line :EvalSelectionCmdLineLisp<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."Lisp.Quit  :EvalSelectionQuitLisp<cr>"
    end
endif



let &cpo = s:save_cpo
unlet s:save_cpo
