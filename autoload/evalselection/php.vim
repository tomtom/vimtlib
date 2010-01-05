" php.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.7

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#php#Init() "{{{3
    if !has('ruby')
        echoerr 'EvalSelection: +ruby support is required'
    endif
endf




" Php
if exists("g:evalSelectionPhpInterpreter") "{{{2
    if !exists("g:evalSelectionPhpCmdLine")
        let g:evalSelectionPhpCmdLine = 'php -a'
    endif

    ruby << EOR
    class EvalSelectionPhp < EvalSelectionInterpreter
        def setup
            @iid            = VIM::evaluate("g:evalSelectionPhpInterpreter")
            @interpreter    = VIM::evaluate("g:evalSelectionPhpCmdLine")
            @printFn        = "<?php %{BODY} ?>\n"
            @bannerEndRx    = "Interactive mode enabled";
            @quitFn         = "<?php exit; ?>\n"
            @markFn         = "<?php echo '745287134.5362\\n'; ?>\n"
            @recMarkRx      = "745287134.5362\n"
            @recPromptRx    = ""
        end
    end
EOR

    function! EvalSelection_php(cmd) "{{{3
        let @e = escape(@e, '\"')
        call evalselection#Eval("php", a:cmd, "",  
                    \ 'call evalselection#Talk(g:evalSelectionPhpInterpreter, "', '")')
    endf
    
    if !hasmapto("EvalSelection_php(")
        call EvalSelectionGenerateBindings("P", "php")
    endif
    
    command! EvalSelectionSetupPhp ruby EvalSelection.setup(VIM::evaluate("g:evalSelectionPhpInterpreter"), EvalSelectionPhp)
    command! EvalSelectionQuitPhp  ruby EvalSelection.tear_down(VIM::evaluate("g:evalSelectionPhpInterpreter"))
    command! EvalSelectionCmdLinePhp call evalselection#CmdLine("php")
    if g:evalSelectionPluginMenu != ""
        exec "amenu ". g:evalSelectionPluginMenu ."Php.Setup :EvalSelectionSetupPhp<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."Php.Command\\ Line :EvalSelectionCmdLinePhp<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."Php.Quit  :EvalSelectionQuitPhp<cr>"
    end
endif


let &cpo = s:save_cpo
unlet s:save_cpo
