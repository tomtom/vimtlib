" r_com.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-18.
" @Last Change: 2010-02-15.
" @Revision:    0.0.110

if &cp || exists("loaded_worksheet_r_com_autoload")
    finish
endif
if !has('ruby')
    echoerr 'Worksheet r_com: +ruby required'
    finish
endif
let loaded_worksheet_r_com_autoload = 1
let s:save_cpo = &cpo
set cpo&vim


let s:prototype = {'syntax': 'r'}


function! s:prototype.Evaluate(lines) dict "{{{3
    let ruby = join(a:lines, "\n")
    " TLogVAR ruby
    ruby <<EOR
    input = VIM.evaluate('ruby')
    value = WorksheetRCOM::INTERPRETER.evaluate(input)
    VIM.command(%{let value=#{(value || '').inspect}})
EOR
    redir END
    " TLogVAR value
    return value
endf


function! s:prototype.Keyword() dict "{{{3
    let word = expand("<cword>")
    " TLogVAR word
    ruby <<EOR
    WorksheetRCOM::INTERPRETER.evaluate(%{help(#{VIM.evaluate('word')})}, false)
EOR
endf


function! s:prototype.Quit() dict "{{{3
    ruby WorksheetRCOM::INTERPRETER.quit
endf


function! worksheet#r_com#InitializeInterpreter(worksheet) "{{{3
    ruby <<EOR
    require 'win32ole'
    require 'tmpdir'
        
    class WorksheetRCOM
        def initialize
            @ole_server = WIN32OLE.new("StatConnectorSrv.StatConnector")
            @ole_server.Init("R")
            if VIM::evaluate("has('gui')")
                r_send(%{options(chmhelp=TRUE)})
                r_send(%{options(show.error.messages=TRUE)})
            end
            d = VIM::evaluate(%{expand("%:p:h")})
            d.gsub!(/\\/, '/')
            r_send(%{setwd("#{d}")})
            rdata = File.join(d, '.Rdata')
            if File.exist?(rdata)
                r_send(%{sys.load.image("#{rdata}", TRUE)})
            end
        end

        def r_send(text)
            @ole_server.EvaluateNoReturn(text)
        end

        def r_sendw(text)
            @ole_server.Evaluate(text)
        end
   
        def escape_help(text)
            text =~ /^".*?"$/ ? text : text.inspect
        end

        def evaluate(text, save=true)
            text = text.sub(/^\?([^\?].*)/) {"help(#{escape_help($1)})"}
            meth = text =~ /^\s*help\b/ ? :r_sendw : :r_send
            p "DBG", text, meth
            r_send(%{worksheet.out <- textConnection("worksheet.log", "w")})
            r_send(%{sink(worksheet.out)})
            if save
                # p %{print(tryCatch({#{text}}, error=function(e) e))}
                send(meth, %{print(tryCatch({#{text}}, error=function(e) e))})
            else
                send(meth, %{{#{text}}})
            end
            r_send(%{sink()})
            r_send(%{close(worksheet.out)})
            r_send(%{rm(worksheet.out)})
            r_sendw(%{if (is.character(worksheet.log) & length(worksheet.log) == 0) NULL else worksheet.log})
        end

        def quit
            begin
                r_send(%{q()})
            rescue
            end
            begin
                @ole_server.Close
            rescue
            end
            return true
        end

        INTERPRETER = WorksheetRCOM.new
    end
EOR
endf


function! worksheet#r_com#InitializeBuffer(worksheet) "{{{3
    call extend(a:worksheet, s:prototype)
    setlocal omnifunc=worksheet#r_com#Complete
    " noremap <silent> <buffer> K :call b:worksheet.Evaluate(['help("'. expand('<cword>') .'")'])<cr>
    setlocal iskeyword+=.
endf


function! worksheet#r_com#Complete(findstart, base) "{{{3
    if a:findstart
        let line = getline('.')
        let start = col('.') - 1
        while start > 0 && line[start - 1] =~ '[._[:alnum:]]'
            let start -= 1
        endwhile
        return start
    else
        let completions = b:worksheet.Evaluate(['apropos("^'. escape(a:base, '^$.*\[]~') .'")'])
        if type(completions) == 1
            " TLogVAR completions
            let completions = substitute(completions, '^[^"]*"', '', '')
            " TLogVAR completions
            let completions = substitute(completions, '"\s*$', '', '')
            " TLogVAR completions
            let clist = split(completions, '"\s[^"]\{-}"')
            " TLogVAR clist
        elseif type(completions) == 3
            let clist = completions
            call map(clist, 'matchstr(v:val, ''"\zs.\{-}\ze"'')')
        else
            echorr 'Worksheet r_com: Unexpected type: '. string(completions)
        endif
        return clist
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
