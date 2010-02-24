" rcom.vim -- Execute R code via rcom
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-02-23.
" @Last Change: 2010-02-24.
" @Revision:    0.0.241

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:rcom#help')
    " Handling of help commands.
    "
    "   0 ... disallow
    "   1 ... allow
    "   2 ... Use RSiteSearch() instead of help() (this option requires 
    "         Internet access)
    let g:rcom#help = 1   "{{{2
endif


if !exists('#RCom')
    augroup RCom
        autocmd!
    augroup END
endif


let s:init = 0
let s:rcom = {}
let s:log  = {}


" :display: rcom#Initialize(?reuse=0)
function! rcom#Initialize(...) "{{{3
    " TLogVAR a:000

    if !s:init
        let reuse = a:0 >= 1 ? a:1 : 0

        ruby <<CODE

        require 'win32ole'
        require 'tmpdir'
            
        class RCom
            @interpreter = nil
            @connections = 0

            class << self
                attr_reader :interpreter

                def connect
                    if @interpreter.nil?
                        @interpreter = RCom.new
                    end
                    @connections += 1
                end

                def disconnect
                    if @connections > 0
                        @connections -= 1
                    end
                    unless @interpreter.nil?
                        if @connections == 0
                            @interpreter.quit
                        end
                    end
                end
            end

            def initialize
                @reuse = VIM::evaluate("reuse").to_i
                case @reuse
                when 0
                    @ole_server = WIN32OLE.new("StatConnectorSrv.StatConnector")
                    @ole_server.Init("R")
                    @ole_printer = WIN32OLE.new("StatConnTools.StringLogDevice")
                    @ole_printer.BindToServerOutput(@ole_server)
                when 1
                    begin
                        @ole_server = WIN32OLE.new("RCOMServerLib.StatConnector")
                    rescue Exception => e
                        throw "Error when connecting to R. Make sure it is already running. #{e}"
                    end
                    @ole_server.Init("R")
                    @ole_printer = nil
                else
                    throw "Unsupported R reuse mode: #{@reuse}"
                end
                if VIM::evaluate("has('gui')")
                    r_send(%{options(chmhelp=TRUE)})
                    r_send(%{options(show.error.messages=TRUE)})
                end
                r_send(%{options(error=function(e) {cat(e$message)})})
                d = VIM::evaluate(%{expand("%:p:h")})
                d.gsub!(/\\/, '/')
                r_send(%{setwd("#{d}")})
                @rdata = File.join(d, '.Rdata')
                if @reuse == 0 and File.exist?(@rdata)
                    r_send(%{sys.load.image("#{@rdata}", TRUE)})
                end
                @rhist = File.join(d, '.Rhistory')
                if @reuse != 0 and File.exist?(@rhist)
                    r_send(%{loadhistory("#{@rhist}")})
                else
                    @rhist = nil
                end
            end

            def r_send(text)
                # VIM.command(%{call inputdialog('EvaluateNoReturn #{text}')})
                @ole_server.EvaluateNoReturn(text)
            end

            def r_sendw(text)
                # VIM.command(%{call inputdialog('Evaluate #{text}')})
                @ole_server.Evaluate(text)
            end
       
            def escape_help(text)
                text =~ /^".*?"$/ ? text : text.inspect
            end

            def evaluate(text, mode=0)
                log = ""
                text = text.sub(/^\s*\?([^\?].*)/) {"help(#{escape_help($1)})"}
                text = text.sub(/^\(/) {"print("}
                text = text.sub(/^\s*(help\(.*?\))/) {"print(#$1)"}
                if text =~ /^\s*(print\()?help(\.\w+)?\b/m
                    return if VIM::evaluate("g:rcom#help") == "0"
                    meth = :r_send
                    if VIM::evaluate("g:rcom#help") == "2"
                        text.sub!(/^\s*(print\()?help(\.\w+)?\s*\(/m, 'RSiteSearch(')
                    end
                else
                    meth = :r_sendw
                    if mode == "p" and text =~ /^\s*(print|str|cat)\s*\(/
                        mode = ""
                    end
                    text = %{eval(parse(text=#{text.inspect}))}
                    # VIM.command(%{call inputdialog('text = #{text}')})
                end
                case mode
                when 'r'
                    meth = :r_sendw
                else
                    if @reuse != 0
                        meth = :r_send
                    end
                end
                # VIM.command(%{call inputdialog('mode = #{mode}; text = #{text}; meth = #{meth}; reuse = #@reuse')})
                begin
                    if mode == 'p'
                        # rv = send(meth, %{do.call(cat, c(as.list(parse(text=#{text.inspect})), sep="\n"))})
                        rv = send(meth, %{print(#{text})})
                    else
                        rv = send(meth, text)
                    end
                rescue Exception => e
                    log(e.to_s)
                end
                log << @ole_printer.Text if @ole_printer
                if log.empty?
                    log << rv.to_s if rv
                else
                    log.gsub!(/\r\n/, "\n")
                    log.sub!(/^\s+/, "")
                    log.sub!(/\s+$/, "")
                    log.gsub!(/^(\[\d+\])\n /m, "\\1 ")
                    @ole_printer.Text = "" if @ole_printer
                end
                log
            end

            def log(text)
                VIM.command(%{let s:log[s:LogID()] = #{text.inspect}})
            end

            def quit
                begin
                    if @rhist
                        r_send(%{try(savehistory("#{@rhist}"))})
                    end
                    if !@reuse
                        r_send(%{q()})
                    end
                rescue
                end
                begin
                    @ole_server.Close
                rescue
                end
                return true
            end
        end
CODE
        let s:init = 1
    endif

    let bn = bufnr('%')
    " TLogVAR bn
    if !has_key(s:rcom, bn)
        ruby RCom.connect
        exec 'autocmd RCom BufUnload <buffer> call rcom#Quit('. bn .')'
        let s:rcom[bn] = 1
    endif
    " echom "DBG ". string(keys(s:rcom))
endf


function! rcom#EvaluateInBuffer(...) range "{{{3
    " TLogVAR a:000
    let bn = bufnr('%')
    if !has_key(s:rcom, bn)
        call rcom#Initialize(1)
    endif
    " echo "Evaluate ..."
    let rv = call('rcom#Evaluate', a:000)
    " redraw
    " echo "Done"
    return rv
endf


" :display: rcom#Evaluate(rcode, ?mode='')
" Mode can be one of
"   p ... Print the result
"   r ... Always return a result
"   . ... Behaviour depends on the context
function! rcom#Evaluate(rcode, ...) "{{{3
    let mode = a:0 >= 1 ? a:1 : ''
    if type(a:rcode) == 3
        let rcode = join(a:rcode, "\n")
    else
        let rcode = a:rcode
    endif
    " TLogVAR ruby
    let logn = s:LogN()
    let value = ''
    redir => log
    silent ruby <<CODE
        rcode = VIM.evaluate('rcode')
        mode = VIM.evaluate('mode')
        value = RCom.interpreter.evaluate(rcode, mode)
        VIM.command(%{let value=#{(value || '').inspect}})
CODE
    redir END
    if exists('log') && !empty(log)
        let s:log[s:LogID()] = log
    endif
    if logn != s:LogN()
        redraw
        echohl WarningMsg
        echo 'RCom: '. len(keys(s:log)) .' messages in the log'
        echohl NONE
    endif
    " TLogVAR value
    return value
endf


function! s:LogN() "{{{3
    return len(keys(s:log))
endf


function! s:LogID() "{{{3
    return printf('%05d %s', s:LogN(), strftime('%Y-%m-%d %H:%M:%S'))
endf


function! rcom#Quit(...) "{{{3
    " TLogVAR a:000
    if a:0 >= 1
        let bufnr = a:1
    else
        let bufnr = expand('<abuf>')
        if empty(bufnr)
            let bufnr = bufnr('%')
        endif
    endif
    " TLogVAR bufnr
    if has_key(s:rcom, bufnr)
        ruby RCom.disconnect
        call remove(s:rcom, bufnr)
    else
        " echom "DBG ". string(keys(s:rcom))
        throw "RCOm: Not an R buffer. Call rcom#Initialize() first."
    endif
endf


function! rcom#Complete(findstart, base) "{{{3
    let bufnr = bufnr('%')
    if !has_key(s:rcom, bufnr)
        call rcom#Initialize(1)
        " throw "RCOm: Not an R buffer. Call rcom#Initialize() first."
    endif
    if a:findstart
        let line = getline('.')
        let start = col('.') - 1
        while start > 0 && line[start - 1] =~ '[._[:alnum:]]'
            let start -= 1
        endwhile
        return start
    else
        let completions = rcom#Evaluate(['paste(apropos("^'. escape(a:base, '^$.*\[]~') .'"), collapse="\n")'], 'r')
        let clist = split(completions, '\n')
        return clist
    endif
endf


function! rcom#Keyword(...) "{{{3
    let bufnr = bufnr('%')
    if !has_key(s:rcom, bufnr)
        call rcom#Initialize(1)
    endif
    let word = a:0 >= 1 && !empty(a:1) ? a:1 : expand("<cword>")
    " TLogVAR word
    ruby RCom.interpreter.evaluate(%{help(#{VIM.evaluate('word')})}, 'r')
endf

" command! -nargs=1 RComKeyword call rcom#Keyword(<q-args>)


" :display: rcom#GetSelection(?mbeg="'<", ?mend="'>", ?mode='selection')
" Mode can be one of: selection, lines, block
function! rcom#GetSelection(...) "{{{3
    if a:0 >= 2
        let mbeg = a:1
        let mend = a:2
    else
        let mbeg = "'<"
        let mend = "'>"
    endif
    let mode = a:0 >= 3 ? a:3 : 'selection'
    let l0   = line(mbeg)
    let l1   = line(mend)
    let text = getline(l0, l1)
    let c0   = col(mbeg)
    let c1   = col(mend)
    " TLogVAR mbeg, mend, mode, l0, l1, c0, c1, text
    if mode == 'block'
        let clen = c1 - c0
        call map(text, 'strpart(v:val, c0, clen)')
    elseif mode == 'selection'
        if c1 > 1
            let text[-1] = strpart(text[-1], 0, c1 - (c1 >= len(text[-1]) ? 0 : 1))
        endif
        if c0 > 1
            let text[0] = strpart(text[0], c0 - 1)
        endif
    endif
    return text
endf


function! rcom#Operator(type, ...) range "{{{3
    " TLogVAR a:type, a:000
    let sel_save = &selection
    let &selection = "inclusive"
    let reg_save = @@
    try
        if a:0
            let text = rcom#GetSelection()
        elseif a:type == 'line'
            let text = rcom#GetSelection("'[", "']", 'lines')
        elseif a:type == 'block'
            let text = rcom#GetSelection("'[", "']", 'block')
        else
            let text = rcom#GetSelection("'[", "']")
        endif
        " TLogVAR text
        let mode = exists('b:rcom_mode') ? b:rcom_mode : ''
        call rcom#EvaluateInBuffer(text, mode)
    finally
        let &selection = sel_save
        let @@ = reg_save
    endtry
endf


function! rcom#Log() "{{{3
    split __RCom_Log__
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted
    setlocal foldmethod=manual
    setlocal foldcolumn=0
    setlocal modifiable
    setlocal nospell
    1,$delete
    let items = sort(keys(s:log))
    call map(items, 'v:val .": ". substitute(s:log[v:val], ''\s*\n\s*'', ". ", "g")')
    call append(0, items)
endf


command! RComlog call rcom#Log()
command! RComlogreset let s:log = {}



let &cpo = s:save_cpo
unlet s:save_cpo
