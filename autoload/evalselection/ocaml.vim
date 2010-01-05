" ocaml.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.8

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#ocaml#Init() "{{{3
    if !has('ruby')
        echoerr 'EvalSelection: +ruby support is required'
    endif
endf


" OCaml
if exists("g:evalSelectionOCamlInterpreter") "{{{2
    if !exists("g:evalSelectionOCamlCmdLine")
        let g:evalSelectionOCamlCmdLine = 'ocaml'
    endif

    function! EvalSelection_ocaml(cmd) "{{{3
        let @e = escape(@e, '\"')
        call evalselection#Eval("ocaml", a:cmd, "",  
                    \ 'call evalselection#Talk(g:evalSelectionOCamlInterpreter, "', '")')
    endf
    if !hasmapto("EvalSelection_ocaml(")
        call EvalSelectionGenerateBindings("o", "ocaml")
    endif

    command! EvalSelectionSetupOCaml   ruby EvalSelection.setup("OCaml", EvalSelectionOCaml)
    command! EvalSelectionQuitOCaml    ruby EvalSelection.tear_down("OCaml")
    command! EvalSelectionCmdLineOCaml call evalselection#CmdLine("ocaml")
    if g:evalSelectionPluginMenu != ""
        exec "amenu ". g:evalSelectionPluginMenu ."OCaml.Setup :EvalSelectionSetupOCaml<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."OCaml.Command\\ Line :EvalSelectionCmdLineOCaml<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."OCaml.Quit  :EvalSelectionQuitOCaml<cr>"
    end

    ruby << EOR
    class EvalSelectionOCaml < EvalSelectionInterpreter
        def setup
            @iid            = "OCaml"
            @interpreter    = VIM::evaluate("g:evalSelectionOCamlCmdLine")
            @printFn        = "%{BODY}"
            @quitFn         = "exit 0;;"
            @bannerEndRx    = "\n"
            @markFn         = "\n745287134.536216736;;"
            @recMarkRx      = "\n# - : float = 745287134\\.536216736"
            @recPromptRx    = "\n# "
        end
        
        if VIM::evaluate("g:evalSelectionOCamlInterpreter") == "OCamlClean"
            def postprocess(text)
                text.sub(/^\s*- : .+? = /, "")
            end
        end
    end
EOR
endif


let &cpo = s:save_cpo
unlet s:save_cpo
