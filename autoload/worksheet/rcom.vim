" rcom.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-18.
" @Last Change: 2010-02-19.
" @Revision:    0.0.170

if &cp || exists("loaded_worksheet_rcom_autoload")
    finish
endif
if !has('ruby')
    echoerr 'Worksheet rcom: +ruby required'
    finish
endif
let loaded_worksheet_rcom_autoload = 1
let s:save_cpo = &cpo
set cpo&vim


if !exists('g:worksheet#rcom#help')
    " Handling of help commands.
    "
    "   0 ... disallow
    "   1 ... allow
    "   2 ... Use RSiteSearch() instead of help() (this option requires 
    "         Internet access)
    let g:worksheet#rcom#help = 1   "{{{2
endif


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


function! worksheet#rcom#InitializeInterpreter(worksheet) "{{{3
    ruby <<EOR
    require 'win32ole'
    require 'tmpdir'
        
    class WorksheetRCOM
        def initialize
            @ole_server = WIN32OLE.new("StatConnectorSrv.StatConnector")
            @ole_server.Init("R")
            @ole_printer = WIN32OLE.new("StatConnTools.StringLogDevice")
            @ole_printer.BindToServerOutput(@ole_server)
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
            log = ""
            text = text.sub(/^\s*\?([^\?].*)/) {"help(#{escape_help($1)})"}
            text = text.sub(/^\s*(help\(.*?\))/) {"print(#$1)"}
            if text =~ /^\s*(print\()?help(\.\w+)?\b/m
                return if VIM::evaluate("g:worksheet#rcom#help") == "0"
                meth = :r_send
                if VIM::evaluate("g:worksheet#rcom#help") == "2"
                    text.sub!(/^\s*(print\()?help(\.\w+)?\s*\(/m, 'RSiteSearch(')
                end
            else
                meth = :r_sendw
            end
            # log << "DBG #{meth}(#{text})\n"
            # rv = send(meth, %{{#{text}}})
            rv = send(meth, %{tryCatch({#{text}}, error = function(e) {e$message})})
            log << @ole_printer.Text
            if log.empty?
                log << rv.to_s
            else
                log.gsub!(/\r\n/, "\n")
                log.sub!(/^\s+/, "")
                log.sub!(/\s+$/, "")
                log.gsub!(/^(\[\d+\])\n /m, "\\1 ")
                @ole_printer.Text = ""
            end
            log
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


function! worksheet#rcom#InitializeBuffer(worksheet) "{{{3
    call extend(a:worksheet, s:prototype)
    setlocal omnifunc=worksheet#rcom#Complete
    " noremap <silent> <buffer> K :call b:worksheet.Evaluate(['help("'. expand('<cword>') .'")'])<cr>
    setlocal iskeyword+=.
endf


function! worksheet#rcom#Complete(findstart, base) "{{{3
    if a:findstart
        let line = getline('.')
        let start = col('.') - 1
        while start > 0 && line[start - 1] =~ '[._[:alnum:]]'
            let start -= 1
        endwhile
        return start
    else
        let completions = b:worksheet.Evaluate(['print(apropos("^'. escape(a:base, '^$.*\[]~') .'"))'])
        " TLogVAR completions
        if type(completions) == 1
            " TLogVAR completions
            let completions = substitute(completions, '^[^"]*"', '', '')
            " TLogVAR completions
            let completions = substitute(completions, '"[^"]*$', '', '')
            " TLogVAR completions
            let clist = split(completions, '"[^"]*"')
            " TLogVAR clist
        elseif type(completions) == 3
            let clist = completions
            call map(clist, 'matchstr(v:val, ''"\zs.\{-}\ze"'')')
        else
            echorr 'Worksheet rcom: Unexpected type: '. string(completions)
        endif
        return clist
    endif
endf


let &cpo = s:save_cpo
unlet s:save_cpo
