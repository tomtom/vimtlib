" rcom.vim -- Execute R code via rcom
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-02-23.
" @Last Change: 2010-04-07.
" @Revision:    496
" GetLatestVimScripts: 2991 1 :AutoInstall: rcom.vim

let s:save_cpo = &cpo
set cpo&vim

if !exists('loaded_rcom')
    let loaded_rcom = 3
endif


function! s:IsRemoteServer() "{{{3
    return has('clientserver') && v:servername == 'RCOM'
endf


if !exists('g:rcom#help')
    " Handling of help commands.
    "
    "   0 ... disallow
    "   1 ... allow
    "   2 ... Use RSiteSearch() instead of help() (this option requires 
    "         Internet access)
    let g:rcom#help = 1   "{{{2
endif


if !exists('g:rcom#reuse')
    " How to interact with R.
    "    0 ... Start a headless instance of R and transcribe the 
    "          interaction in VIM
    "    1 ... Re-use a running instance of R GUI (default)
    let g:rcom#reuse = 1   "{{{2
endif


if !exists('g:rcom#transcript_cmd')
    " Command used to display the transcript buffers.
    let g:rcom#transcript_cmd = s:IsRemoteServer() ? 'edit' : 'vert split'   "{{{2
endif


if !exists('g:rcom#log_cmd')
    " Command used to display the transcript buffers.
    let g:rcom#log_cmd = 'split'   "{{{2
endif


if !exists('g:rcom#server')
    " If non-empty, use this ex command to start an instance of GVIM 
    " that acts as a server for remotely evaluating R code. The string 
    " will be evaluated via |:execute|.
    " The string may contain %s where rcom-specific options should be 
    " included.
    "
    " Example: >
    "   let g:rcom#server = 'silent ! start "" gvim.exe "+set lines=18" "+winpos 1 700" %s'
    "   let g:rcom#server = 'silent ! gvim %s &'
    let g:rcom#server = ""   "{{{2
endif


if !exists('g:rcom#server_wait')
    " Seconds to wait after starting |rcom#server|.
    let g:rcom#server_wait = 10   "{{{2
endif


if !exists('#RCom')
    augroup RCom
        autocmd!
    augroup END
endif


let s:init = 0
let s:rcom = {}
let s:log  = {}


" :display: rcom#Initialize(?reuse=g:rcom#reuse)
" Connect to the R interpreter for the current buffer.
" Usually not called by the user.
function! rcom#Initialize(...) "{{{3
    " TLogVAR a:000

    if !s:init
        let reuse = a:0 >= 1 ? a:1 : g:rcom#reuse
        " TLogVAR reuse

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
                    # r_send(%{options(show.error.messages=TRUE)})
                end
                # r_send(%{options(error=function(e) {cat(e$message)})})
                r_send(%{if (options("warn")$warn == 0) options(warn = 1)})
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
                out = ""
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
                    if e.to_s =~ /unknown property or method `EvaluateNoReturn'/
                        return 'It seems R GUI was closed.'
                    else
                        log(e.to_s)
                    end
                end
                out << @ole_printer.Text if @ole_printer
                if out.empty?
                    out << rv.to_s if rv
                else
                    out.gsub!(/\r\n/, "\n")
                    out.sub!(/^\s+/, "")
                    out.sub!(/\s+$/, "")
                    out.gsub!(/^(\[\d+\])\n /m, "\\1 ")
                    @ole_printer.Text = "" if @ole_printer
                end
                out
            end

            def log(text)
                VIM.command(%{call s:Log(#{text.inspect})})
            end

            def quit(just_the_ole_server = false)
                unless just_the_ole_server
                    begin
                        if @rhist
                            r_send(%{try(savehistory("#{@rhist}"))})
                        end
                        if !@reuse
                            r_send(%{q()})
                        end
                    rescue
                    end
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


function! s:ShouldRemoteSend() "{{{3
    if has('clientserver') && v:servername != 'RCOM'
        if serverlist() =~ '\<RCOM\>'
            return 1
        elseif !empty(g:rcom#server)
            let cmd = g:rcom#server
            if cmd =~ '\(%\)\@<!%s\>'
                let cmd = printf(g:rcom#server, '--servername RCOM')
            endif
            exec cmd
            redraw
            echo "RCom: Waiting for GVIM to start"
            let i = 0
            while i < g:rcom#server_wait
                sleep 1
                if serverlist() =~ '\<RCOM\>'
                    redraw
                    echo
                    return 1
                endif
                let i += 1
            endwh
            echoerr "RCom: Got tired of waiting for GVim RCOM server"
            return 0
        else
            return 0
        endif
    else
        return 0
    endif
endf


" :display: rcom#EvaluateInBuffer(rcode, ?mode='')
" Initialize the current buffer if necessary and evaluate some R code in 
" a running instance of R GUI.
"
" If there is a remote gvim server named RCOM running (see 
" |--servername|), evaluate R code remotely. This won't block the 
" current instance of gvim.
"
" See also |rcom#Evaluate()|.
function! rcom#EvaluateInBuffer(...) range "{{{3
    let len = type(a:1) == 3 ? len(a:1) : 1
    redraw
    " echo
    if s:ShouldRemoteSend()
        call remote_send('RCOM', ':call call("rcom#EvaluateInBuffer", '. string(a:000) .')<cr>')
        echo printf("Sent %d lines to GVim/RCOM", len)
        let rv = ''
    else
        " TLogVAR a:000
        " echo printf("Evaluating %d lines of R code ...", len(a:1))
        call s:Warning("Evaluating R code ...")
        let bn = bufnr('%')
        if !has_key(s:rcom, bn)
            call rcom#Initialize(g:rcom#reuse)
        endif
        let logn = s:LogN()
        let rv = call('rcom#Evaluate', a:000)
        if !g:rcom#reuse || s:IsRemoteServer()
            call rcom#Transcribe(a:1, rv)
        endif
        if logn == s:LogN()
            redraw
            " echo " "
            echo printf("Evaluated %d lines", len)
        endif
    endif
    return rv
endf


" :display: rcom#Evaluate(rcode, ?mode='')
" rcode can be a string or an array of strings.
" mode can be one of
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
        call s:Log(log)
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


function! s:Log(text) "{{{3
    if a:text !~ 'RCom: \d\+ messages in the log$'
        let s:log[s:LogID()] = a:text
    endif
    redraw
    call s:Warning('RCom: '. s:LogN() .' messages in the log')
endf


function! s:Warning(text) "{{{3
    echohl WarningMsg
    echom a:text
    echohl NONE
endf


" :display: rcom#Quit(?bufnr=bufnr('%'))
" Disconnect from the R GUI.
" Usually not called by the user.
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
    TLogVAR bufnr
    if has_key(s:rcom, bufnr)
        try
            ruby RCom.disconnect
            call remove(s:rcom, bufnr)
        catch
            call s:Log(v:exception)
        endtry
    else
        " echom "DBG ". string(keys(s:rcom))
        call s:Log("RCOm: Not an R buffer. Call rcom#Initialize() first.")
    endif
endf


function! s:Escape2(text, chars) "{{{3
    return escape(escape(a:text, a:chars), '\')
endf


" Omnicompletion for R.
" See also 'omnifunc'.
function! rcom#Complete(findstart, base) "{{{3
    let bufnr = bufnr('%')
    if !has_key(s:rcom, bufnr)
        call rcom#Initialize(g:rcom#reuse)
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
        if exists('w:tskeleton_hypercomplete')
            let completions = rcom#Evaluate(['paste(sapply(apropos("^'. s:Escape2(a:base, '^$.*\[]~"') .'"), function(t) {if (try(is.function(eval.parent(parse(text = t))), silent = TRUE) == TRUE) sprintf("%s(<+CURSOR+>)", t) else t}), collapse="\n")'], 'r')
        else
            let completions = rcom#Evaluate(['paste(apropos("^'. s:Escape2(a:base, '^$.*\[]~"') .'"), collapse="\n")'], 'r')
        endif
        let clist = split(completions, '\n')
        " TLogVAR clist
        return clist
    endif
endf


" Display help on the word under the cursor.
function! rcom#Keyword(...) "{{{3
    let bufnr = bufnr('%')
    if !has_key(s:rcom, bufnr)
        call rcom#Initialize(g:rcom#reuse)
    endif
    let word = a:0 >= 1 && !empty(a:1) ? a:1 : expand("<cword>")
    " TLogVAR word
    " call rcom#EvaluateInBuffer(printf('help(%s)', word))
    call rcom#EvaluateInBuffer(printf('if (mode(%s) == "function") {print(help(%s))} else {str(%s)}', word, word, word))
endf


" Display help on the word under the cursor.
function! rcom#Info(...) "{{{3
    let bufnr = bufnr('%')
    if !has_key(s:rcom, bufnr)
        call rcom#Initialize(g:rcom#reuse)
    endif
    let word = a:0 >= 1 && !empty(a:1) ? a:1 : expand("<cword>")
    " TLogVAR word
    call rcom#EvaluateInBuffer(printf('str(%s)', word))
    call rcom#EvaluateInBuffer(printf('if (class(%s) == "data.frame") print(head(%s))', word, word))
endf


" :display: rcom#GetSelection(mode, ?mbeg="'<", ?mend="'>", ?opmode='selection')
" mode can be one of: selection, lines, block
function! rcom#GetSelection(mode, ...) range "{{{3
    if a:0 >= 2
        let mbeg = a:1
        let mend = a:2
    else
        let mbeg = "'<"
        let mend = "'>"
    endif
    let opmode = a:0 >= 3 ? a:3 : 'selection'
    let l0   = line(mbeg)
    let l1   = line(mend)
    let text = getline(l0, l1)
    let c0   = col(mbeg)
    let c1   = col(mend)
    " TLogVAR mbeg, mend, opmode, l0, l1, c0, c1
    " TLogVAR text[-1]
    " TLogVAR len(text[-1])
    if opmode == 'block'
        let clen = c1 - c0
        call map(text, 'strpart(v:val, c0, clen)')
    elseif opmode == 'selection'
        if c1 > 1
            let text[-1] = strpart(text[-1], 0, c1 - (a:mode == 'o' || c1 > len(text[-1]) ? 0 : 1))
        endif
        if c0 > 1
            let text[0] = strpart(text[0], c0 - 1)
        endif
    endif
    return text
endf


" For use as an operator. See 'opfunc'.
function! rcom#Operator(type, ...) range "{{{3
    " TLogVAR a:type, a:000
    let sel_save = &selection
    let &selection = "inclusive"
    let reg_save = @@
    try
        if a:0
            let text = rcom#GetSelection("o")
        elseif a:type == 'line'
            let text = rcom#GetSelection("o", "'[", "']", 'lines')
        elseif a:type == 'block'
            let text = rcom#GetSelection("o", "'[", "']", 'block')
        else
            let text = rcom#GetSelection("o", "'[", "']")
        endif
        " TLogVAR text
        let mode = exists('b:rcom_mode') ? b:rcom_mode : ''
        call rcom#EvaluateInBuffer(text, mode)
    finally
        let &selection = sel_save
        let @@ = reg_save
    endtry
endf


function! s:Scratch() "{{{3
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted
    setlocal foldmethod=manual
    setlocal foldcolumn=0
    setlocal modifiable
    setlocal nospell
endf


function! s:ScratchBuffer(type, name) "{{{3
    " TLogVAR a:type, a:name
    let bufnr = bufnr(a:name)
    if bufnr != -1 && bufwinnr(bufnr)
        exec 'drop '. a:name
        return 0
    else
        exec g:rcom#{a:type}_cmd .' '. a:name
        if bufnr == -1
            call s:Scratch()
            return 1
        else
            return 0
        endif
    endif
endf


function! rcom#LogBuffer() "{{{3
    if s:ShouldRemoteSend()
        call remote_foreground('RCOM')
        call remote_send('RCOM', ':call rcom#LogBuffer()<cr>')
    else
        let bufname = bufname('%')
        " TLogVAR bufname
        try
            call s:ScratchBuffer('log', '__RCom_Log__')
            1,$delete
            let items = sort(keys(s:log))
            " TLogVAR items
            call map(items, 'v:val .": ". substitute(s:log[v:val], ''\s*\n\s*'', ". ", "g")')
            call append(0, items)
            norm! Gzb
        finally
            exec 'drop '. bufname
        endtry
    endif
endf


" Display the log.
command! RComlog call rcom#LogBuffer()

" Reset the log.
command! RComlogreset let s:log = {}


function! rcom#TranscriptBuffer() "{{{3
    if s:ShouldRemoteSend()
        call remote_foreground('RCOM')
        call remote_send('RCOM', ':call rcom#TranscriptBuffer()<cr>')
    else
        if s:ScratchBuffer('transcript', '__RCom_Transcript__')
            set ft=r
        endif
    endif
endf

command! RComtranscript call rcom#TranscriptBuffer()


function! rcom#Transcribe(input, output) "{{{3
    let bufname = bufname('%')
    try
        call rcom#TranscriptBuffer()
        call append(line('$'), strftime('# %c'))
        if !empty(a:input)
            if type(a:input) == 1
                let input = split(a:input, '\n')
            else
                let input = a:input
            endif
            " for i in range(len(input))
            "     let input[i] = (i == 0 ? '> ' : '+ ') . input[i]
            " endfor
            call append(line('$'), input)
        endif
        if !empty(a:output)
            " TLogVAR a:output
            let output = split(a:output, '\n\+')
            for i in range(len(output))
                let output[i] = (i == 0 ? '=> ' : '   ') . output[i]
            endfor
            call append(line('$'), output)
        endif
        call append(line('$'), '')
        norm! Gzb
    finally
        if !empty(bufname)
            exec 'drop '. bufname
        endif
    endtry
endf


let &cpo = s:save_cpo
unlet s:save_cpo

finish

-------------------------------------------------------------------
CHANGES:

0.1
- Initial release

0.2
- Add cursor markers only if w:tskeleton_hypercomplete exists
- g:rcom#reuse: If 0, don't use a running instance of R GUI (transcribe 
the results in VIM; be aware that some problems could cause problems)
- If there is a vim server named RCOM running, evaluate R code remotely 
(this won't block the current instance of gvim)
- Use g:rcom#server to start an instance of gvim that acts as server/proxy
- Transcript, log

0.3
- K on non-functions uses str()

