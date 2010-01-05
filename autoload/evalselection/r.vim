" r.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.10

let s:save_cpo = &cpo
set cpo&vim
" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


function! evalselection#r#Init() "{{{3
    if !has('ruby')
        echoerr 'EvalSelection: +ruby support is required'
    endif
endf




" R
if exists("g:evalSelectionRInterpreter") "{{{2
    if !exists("g:evalSelectionRCmdLine")
        if s:windows
            let g:evalSelectionRCmdLine = 'Rterm.exe --no-save --vanilla --ess'
        else
            let g:evalSelectionRCmdLine = 'R --no-save --vanilla --ess'
        endif
    endif

    command! EvalSelectionSetupR   ruby EvalSelection.setup("R", EvalSelectionR)
    command! EvalSelectionQuitR    ruby EvalSelection.tear_down("R")
    command! EvalSelectionCmdLineR call evalselection#CmdLine("r")
    autocmd FileType r call evalselection#ParagraphMappings(1)
    if g:evalSelectionPluginMenu != ""
        exec "amenu ". g:evalSelectionPluginMenu ."R.Setup :EvalSelectionSetupR<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."R.Command\\ Line :EvalSelectionCmdLineR<cr>"
        exec "amenu ". g:evalSelectionPluginMenu ."R.Quit  :EvalSelectionQuitR<cr>"
    end

    function! EvalSelection_r(cmd) "{{{3
        let @e = escape(@e, '\"')
        call evalselection#Eval("r", a:cmd, "", 'call evalselection#Talk("R", "', '")')
    endf

    if !hasmapto("EvalSelection_r(")
        call EvalSelectionGenerateBindings("R", "r")
    endif

    ruby <<EOR
    def escape_menu(text)
        text.gsub(/([-. &|\\"])/, "\\\\\\1")
        # text.gsub(/(\W)/, "\\\\\\1")
    end
EOR

    function! EvalSelectionGetWordCompletions_r(ArgLead, CmdLine, CursorPos) "{{{3
        let ls = ""
        ruby <<EOR
        i = $EvalSelectionTalkers["R"]
        if i and i.respond_to?(:complete_word)
            ls = i.complete_word(VIM::evaluate("a:ArgLead"))
            if ls
                ls = ls.join("\n")
                ls.gsub(/"/, '\\\\"')
                VIM::command(%{let ls="#{ls}"})
            end
        end
EOR
        return ls
    endf

    function! EvalSelectionCompleteCurrentWord_r(bit) "{{{3
        ruby <<EOR
        i = $EvalSelectionTalkers["R"]
        if i
            if i.respond_to?(:complete_word)
                ls = i.complete_word(VIM::evaluate("a:bit"))
                if ls
                    i.build_vim_menu("PopUp.EvalSelection", ls, 
                                   lambda {|x| %{:call evalselection#CompleteCurrentWordInsert("#{x}", 1)<CR>}},
                                   :extra => true)
                end
            else
                VIM::command(%Q{echoerr "EvalSelection: Wrong or incapable interpreter!"})
            end
        else
            VIM::command(%Q{echoerr "EvalSelection CCW: Set up interaction with R first!"})
        end
EOR
    endf
       
    ruby <<EOR
    module EvalSelectionRExtra
        if VIM::evaluate("g:evalSelectionRInterpreter") =~ /Clean$/
            def postprocess(text)
                text.sub(/^.*?\n([>+] .*?\n)*(\[\d\] )?/m, "")
            end
        else
            def postprocess(text)
                text.sub(/^.*?\n([>+] .*?\n)*/m, '')
            end
        end
    end
EOR
    if g:evalSelectionRInterpreter =~ '^RDCOM' && s:windows
        ruby << EOR
        require 'win32ole'
        require 'tmpdir'
        class EvalSelectionAbstractR < EvalSelectionOLE
            def setup
                @iid         = "R"
                @interpreter = "rdcom"
            end

            def build_menu(initial)
                ls = @ole_server.Evaluate(%{ls()})
                if ls
                    build_vim_menu("R", ls, 
                                   lambda {|x| %{a#{x}}}, 
                                   :exit   => %{:EvalSelectionQuitR<CR>},
                                   :update => %{:ruby EvalSelection.update_menu("R")<CR>},
                                   :remove_menu => %{:ruby EvalSelection.remove_menu("R")<cr>}
                                  )
                end
            end

            def complete_word(bit)
                bit = nil if bit == "\n"
                @ole_server.Evaluate(%{apropos("^#{Regexp.escape(bit) if bit}")})
            end

            def ole_tear_down
                begin
                    @ole_server.EvaluateNoReturn(%{q()})
                rescue
                end
                begin
                    @ole_server.Close
                rescue
                end
                return true
            end
            
            def clean_result(text)
                text.sub(/^\s*\[\d+\]\s*/, '')
            end

            if VIM::evaluate("g:evalSelectionRInterpreter") =~ /Clean$/
                def postprocess(result)
                    case result
                    when Array
                        result.collect {|l| clean_result(l)}
                    when String
                        clean_result(result)
                    else
                        result
                    end
                end
            end
        end
EOR
        if g:evalSelectionRInterpreter =~ 'Commander'
            ruby << EOR
            class EvalSelectionR < EvalSelectionAbstractR
                def ole_setup
                    @ole_server = WIN32OLE.new("StatConnectorSrv.StatConnector")
                    @ole_server.Init("R")
                    @ole_server.EvaluateNoReturn(%{options(chmhelp=TRUE)})
                    @ole_server.EvaluateNoReturn(%{library(Rcmdr)})
                end
                
                def ole_evaluate(text)
                    text.gsub!(/"/, '\\\\"')
                    text.gsub!(/\\/, '\\\\\\\\')
                    @ole_server.Evaluate(%{capture.output(doItAndPrint("#{text}"))})
                end
            end
EOR
        else
            ruby << EOR
            class EvalSelectionR < EvalSelectionAbstractR
                def ole_setup
                    @ole_server = WIN32OLE.new("StatConnectorSrv.StatConnector")
                    @ole_server.Init("R")
                    if VIM::evaluate("has('gui')")
                        @ole_server.EvaluateNoReturn(%{options(chmhelp=TRUE)})
                        @ole_server.EvaluateNoReturn(%{EvalSelectionPager <- function(f, hd, ti, del) {
    system(paste("cmd /c start #{VIM::evaluate("g:evalSelectionPager")} ", gsub(" ", "\\\\ ", f)))
    if (del) {
        Sys.sleep(5)
        unlink(f)
    }
}})
                        @ole_server.EvaluateNoReturn(%{options(pager=EvalSelectionPager)})
                        @ole_server.EvaluateNoReturn(%{options(show.error.messages=TRUE)})
                    end
                    d = VIM::evaluate(%{expand("%:p:h")})
                    d.gsub!(/\\/, "/")
                    @ole_server.EvaluateNoReturn(%{setwd("#{d}")})
                    rdata = File.join(d, ".Rdata")
                    if File.exist?(rdata)
                        @ole_server.EvaluateNoReturn(%{sys.load.image("#{rdata}", TRUE)})
                    end
                end
                
                def ole_evaluate(text)
                    @ole_server.EvaluateNoReturn(%{evalSelection.out <- textConnection("evalSelection.log", "w")})
                    @ole_server.EvaluateNoReturn(%{sink(evalSelection.out)})
                    @ole_server.EvaluateNoReturn(%{print(tryCatch({#{text}}, error=function(e) e))})
                    @ole_server.EvaluateNoReturn(%{sink()})
                    @ole_server.EvaluateNoReturn(%{close(evalSelection.out)})
                    @ole_server.EvaluateNoReturn(%{rm(evalSelection.out)})
                    @ole_server.Evaluate(%{if (is.character(evalSelection.log) & length(evalSelection.log) == 0) NULL else evalSelection.log})
                end
            end
EOR
        endif
    elseif g:evalSelectionRInterpreter =~ '^RFO'
        ruby << EOR
        require "tmpdir"
        class EvalSelectionR < EvalSelectionStdInFileOut
            include EvalSelectionRExtra
            def setup
                @iid            = "R"
                @interpreter    = VIM::evaluate("g:evalSelectionRCmdLine")
                @outfile        = File.join(Dir.tmpdir, "EvalSelection.Rout")
                @printFn        = <<EOFN
sink('#@outfile');
%{BODY};
sink();
EOFN
                @quitFn         = "q()"
            end
        end
EOR
    else
        ruby << EOR
        class EvalSelectionR < EvalSelectionInterpreter
            include EvalSelectionRExtra
            def setup
                @iid            = "R"
                @interpreter    = VIM::evaluate("g:evalSelectionRCmdLine")
                @printFn        = "%{BODY}"
                @quitFn         = "q()"
                @bannerEndRx    = "\n"
                @markFn         = "\nc(31983689, 32682634, 23682638)" 
                @recMarkRx      = "\n?\\> \\[1\\] 31983689 32682634 23682638"
                @recPromptRx    = "\n\\> "
            end
            
        end
EOR
    endif

endif



let &cpo = s:save_cpo
unlet s:save_cpo
