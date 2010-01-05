" scheme.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.7

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#scheme#Init() "{{{3
    if !has('ruby')
        echoerr 'EvalSelection: +ruby support is required'
    endif
endf



if exists("g:evalSelectionSchemeInterpreter") "{{{2
    if g:evalSelectionSchemeInterpreter ==? 'Gauche'
        if !exists("g:evalSelectionSchemeCmdLine")
            let s:evalSelectionSchemeCmdLine = 'gosh'
        endif
        let s:evalSelectionSchemePrint = '(display (begin %{BODY})) (display #\escape) (flush)'
    elseif g:evalSelectionSchemeInterpreter ==? 'Chicken'
        if !exists("g:evalSelectionSchemeCmdLine")
            let g:evalSelectionSchemeCmdLine = 'csi -quiet'
        endif
        let s:evalSelectionSchemePrint = 
                    \ '(display (begin %{BODY})) (display (integer->char 27)) (flush-output)'
    endif

    function! EvalSelection_scheme(cmd) "{{{3
        let @e = escape(@e, '\"')
        call evalselection#Eval("scheme", a:cmd, "", 
                    \ 'call evalselection#Talk(g:evalSelectionSchemeInterpreter, "', '")')
    endf
    
    if !hasmapto("EvalSelection_scheme(")
        call EvalSelectionGenerateBindings("c", "scheme")
    endif

    command! EvalSelectionSetupScheme   ruby EvalSelection.setup(VIM::evaluate("g:evalSelectionSchemeInterpreter"), EvalSelectionScheme)
    command! EvalSelectionQuitScheme    ruby EvalSelection.tear_down(VIM::evaluate("g:evalSelectionSchemeInterpreter"))
    command! EvalSelectionCmdLineScheme call evalselection#CmdLine("scheme")
    if g:evalSelectionPluginMenu != ""
        exec "amenu ". g:evalSelectionPluginMenu ."Scheme.Setup :EvalSelectionSetupScheme<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."Scheme.Command\\ Line :EvalSelectionCmdLineScheme<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."Scheme.Quit  :EvalSelectionQuitScheme<cr>"
    end

    ruby << EOR
    class EvalSelectionScheme < EvalSelectionInterpreter
        def setup
            @iid            = VIM::evaluate("g:evalSelectionSchemeInterpreter")
            @interpreter    = VIM::evaluate("g:evalSelectionSchemeCmdLine")
            @printFn        = VIM::evaluate("s:evalSelectionSchemePrint")
            @quitFn         = "(exit)"
            @recEndChar     = 27
        end
    end
EOR
endif


let &cpo = s:save_cpo
unlet s:save_cpo
