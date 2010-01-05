" spss.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.6

let s:save_cpo = &cpo
set cpo&vim


function! evalselection#spss#Init() "{{{3
    if !has('ruby')
        echoerr 'EvalSelection: +ruby support is required'
    endif
endf


if exists("g:evalSelectionSpssInterpreter") "{{{2
    command! EvalSelectionSetupSPSS   ruby EvalSelection.setup("SPSS", EvalSelectionSPSS)
    command! EvalSelectionQuitSPSS    ruby EvalSelection.tear_down("SPSS")
    command! EvalSelectionCmdLineSPSS call evalselection#CmdLine("sps")
    autocmd FileType sps call evalselection#ParagraphMappings(0, "$(v)")
    if g:evalSelectionPluginMenu != ""
        exec "amenu ". g:evalSelectionPluginMenu ."SPSS.Setup :EvalSelectionSetupSPSS<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."SPSS.Command\\ Line :EvalSelectionCmdLineSPSS<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."SPSS.Quit  :EvalSelectionQuitSPSS<cr>"
    end

    function! EvalSelection_sps(cmd) "{{{3
        let @e = escape(@e, '\"')
        call evalselection#Eval("sps", a:cmd, "", 
                    \ 'call evalselection#Talk(g:evalSelectionSpssInterpreter, "', '")')
    endf

    if !hasmapto("EvalSelection_sps(")
        call EvalSelectionGenerateBindings("S", "sps")
    endif

    if !exists("g:evalSelectionSpssCmdLine") && s:windows
        function! EvalSelectionRunSpssMenu(menuEntry) "{{{3
            echo "Be careful with this. Some menu entries simply don't work this way.\n".
                        \ "Press the <OK> button when finished, not the <Insert> button."
            let formatoptions = &formatoptions
            " let smartindent   = &smartindent
            let autoindent    = &autoindent
            set formatoptions&
            " set nosmartindent&
            set noautoindent
            try
                ruby <<EOR
                i = $EvalSelectionTalkers["SPSS"]
                if i
                    m = VIM::evaluate("a:menuEntry")
                    begin
                        # i.data.InvokeDialogAndExecuteSyntax(m, 1, false)
                        rv = i.data.InvokeDialogAndReturnSyntax(m, 1)
                        if rv and rv != ""
                            # VIM::command(%{echom "#{rv}"})
                            VIM::command(%{norm! a #{rv}})
                        end
                    rescue WIN32OLERuntimeError => e
                        VIM::command(%{echohl Error})
                        for l in e.to_s
                            VIM::command(%{echo "#{l.gsub(/"/, '\\\\"')}"})
                        end
                        VIM::command(%{echohl None})
                    end
                else
                    VIM::command(%Q{echoerr "EvalSelection RSM: Set up interaction with SPSS first!"})
                end
EOR
            finally
                let &formatoptions = formatoptions
                " let &smartindent   = smartindent
                let &autoindent    = autoindent
            endtry
        endf
        
        function! EvalSelectionBuildMenu_sps() "{{{3
            if has("menu")
                ruby <<EOR
                i = $EvalSelectionTalkers["SPSS"]
                if i
                end
EOR
            endif
        endf
    
        ruby << EOR
        require 'win32ole'
        class EvalSelectionSPSS < EvalSelectionOLE
            attr :data
            
            def setup
                @iid         = "SPSS"
                @interpreter = "ole"
                @spss_syntax_menu   = false
            end

            def ole_setup
                @ole_server = WIN32OLE.new("spss.application")
                @options    = @ole_server.Options
                # 0	SPSSObjectOutput
                # 1	SPSSDraftOutput
                # if VIM::evaluate(%{exists("g:evalSelection_SPSS_DraftOutput")})
                #     @options.OutputType = VIM::evaluate(%{g:evalSelection_SPSS_DraftOutput})
                # end
                # if VIM::evaluate(%{g:evalSelection_SPSS_DraftOutput}) == "1"
                #     @output = @ole_server.NewDraftDoc
                # else
                #     @output = @ole_server.NewOutputDoc
                # end
                # @output.visible = true
                @data         = @ole_server.NewDataDoc
                @data.visible = true
            end

            def ole_tear_down
                @ole_server.Quit
                return true
            end

            def ole_evaluate(text)
                # run commands asynchronously as long as I don't know how to 
                # retrieve the output
                @ole_server.ExecuteCommands(text, false)
                if VIM::evaluate(%{g:evalSelection_SPSS_DraftOutput}) == "1"
                    @output = @ole_server.GetDesignatedDraftDoc
                else
                    @output = @ole_server.GetDesignatedOutputDoc
                end
                @output.visible = true
                nil
            end

            # this doesn't quite work yet
            def build_spss_syntax_menu
                if !@spss_syntax_menu and VIM::evaluate(%{has("menu")})
                    menu = @data.GetMenuTable
                    VIM::command(%{amenu SPSS\\ Syntax.Some\\ menus\\ cause\\ vim\\ to\\ hang :})
                    VIM::command(%{amenu SPSS\\ Syntax.Press\\ the\\ *OK*\\ button\\ to\\ insert\\ the\\ syntax :})
                    VIM::command(%{amenu SPSS\\ Syntax.--Sep-SPSS-- :})
                    for e in menu
                        if e =~ /\>/ and !menu.any? {|m| m =~ /^#{Regexp.escape(e)}\>/}
                            m = e.gsub(/([.\\ ])/, '\\\\\\1')
                            m.gsub!(/\>/, '.')
                            VIM::command(%{amenu SPSS\\ Syntax.#{m} :call EvalSelectionRunSpssMenu('#{e}')<CR>})
                        end
                    end
                    @spss_syntax_menu = true
                end
            end
            
            def build_menu(initial=false)
                variables = initial ? [] : @data.GetVariables(true)
                if variables
                    variables.each {|v| v.gsub!(/\t/, " - ")}
                    build_vim_menu("SPSS", variables, 
                                   lambda {|x| "a" + x.gsub(/^(\S+) - .*$/, "\\1")},
                                   :exit   => %{:EvalSelectionQuitSPSS<CR>},
                                   :update => %{:ruby EvalSelection.update_menu("SPSS")<CR>},
                                   :remove_menu => %{:ruby EvalSelection.remove_menu("SPSS")<cr>}
                                  )
                end
                build_spss_syntax_menu
            end

            def remove_menu
                if VIM::evaluate(%{has("menu")})
                    if @spss_syntax_menu
                        VIM::command(%{aunmenu SPSS\\ Syntax})
                        @spss_syntax_menu = false
                    end
                    super
                end
            end
        end
EOR
    endif
endif



let &cpo = s:save_cpo
unlet s:save_cpo
