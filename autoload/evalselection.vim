" evalselection.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.32

let s:save_cpo = &cpo
set cpo&vim
" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


if !exists("g:evalSelectionLogCommands")  | let g:evalSelectionLogCommands = 1  | endif "{{{2
if !exists("g:evalSelectionLogTime")      | let g:evalSelectionLogTime = 0      | endif "{{{2
if !exists("g:evalSelectionSeparatedLog") | let g:evalSelectionSeparatedLog = 1 | endif "{{{2
" if !exists("g:evalSelectionDebugLog")     | let g:evalSelectionDebugLog = 1     | endif
if !exists("g:evalSelectionDebugLog")     | let g:evalSelectionDebugLog = 0     | endif "{{{2
if !exists("g:evalSelectionSaveLog")      | let g:evalSelectionSaveLog = ""     | endif "{{{2
if !exists("g:evalSelectionSaveLog_r") "{{{2
    let g:evalSelectionSaveLog_r = "EvalSelection_r.log"
endif

autocmd BufRead EvalSelection_*.log setf EvalSelectionLog

if !exists("g:evalSelectionMenuSize")     | let g:evalSelectionMenuSize = &lines | endif "{{{2

if !exists("g:evalSelectionPager") "{{{2
    let g:evalSelectionPager = "gvim --servername GVIMPAGER --remote-silent"
endif

if !exists("g:evalSelection_SPSS_DraftOutput") "{{{2
    let g:evalSelection_SPSS_DraftOutput = 0
endif

let s:evalSelLogBufNr  = -1
let g:evalSelLastCmd   = ""
let g:evalSelLastCmdId = ""


" Main functions {{{2
" evalselection#Eval(id, proc, cmd, ?pre, ?post, ?newsep, ?recsep, ?postprocess)
function! evalselection#Eval(id, proc, cmd, ...) "{{{3
    let pre     = a:0 >= 1 ? a:1 : ""
    let post    = a:0 >= 2 ? a:2 : ""
    let newsep  = a:0 >= 3 ? a:3 : "\n"
    let recsep  = a:0 >= 4 ? (a:4 == ""? "\n" : a:4) : "\n"
    let process = a:0 >= 5 ? a:4 : ""
    let e = substitute(@e, '\('. recsep .'\)\+$', "", "g")
    if newsep != "" && newsep != recsep
        let e = substitute(e, recsep, newsep, "g")
    endif
    if exists("g:evalSelectionPRE".a:id)
        exe "let pre = g:evalSelectionPRE".a:id.".'".newsep.pre."'"
    endif
    if exists("g:evalSelectionPOST".a:id)
        exe "let post = g:evalSelectionPOST".a:id.".'".newsep.post."'"
    endif
    let e = pre .e. post
    let c = a:cmd ." ". e
    " TLogVAR c
    " echomsg "DBG: ". a:cmd ." ". e
    redir @e
    " exe a:cmd ." ". e
    " echom "DBG ". a:cmd ." ". e
    silent exec c
    redir END
    let @e = substitute(@e, "\<c-j>$", "", "")
    if @e != ""
        if process != ""
            exec "let @e = ". escape(process, '"\')
        endif
        if a:proc != ""
            let g:evalSelLastCmdId = a:id
            exe a:proc . ' "' . escape(strpart(@e, 1), '"\') . '"'
        endif
    endif
endf

function! evalselection#System(txt) "{{{3
    let rv=system(a:txt)
    return substitute(rv, "\n\\+$", "", "")
endf

function! evalselection#Echo(txt, ...)
    " echo "\r"
    redraw
    " TLogVAR a:txt
    exec "echo ". a:txt
endf

function! s:LogAppend(txt, ...) "{{{3
    " If we search for ^@ right away, we will get a *corrupted* viminfo-file 
    " -- at least with the version of vim, I use.
    call append(0, substitute(a:txt, "\<c-j>", "\<c-m>", "g"))
    exe "1,.s/\<c-m>/\<cr>/ge"
endf

function! evalselection#Log(txt, ...) "{{{3
    let currWin = winnr()
    let dbg     = a:0 >= 1 ? a:1 : 0
    exe "let txt = ".a:txt
    if g:evalSelectionSeparatedLog
        let logID = g:evalSelLastCmdId
    else
        let logID = ""
    endif
    
    let logfile = exists("g:evalSelectionSaveLog_". logID) ? 
                \ g:evalSelectionSaveLog_{logID} : g:evalSelectionSaveLog

    "Adapted from Yegappan Lakshmanan's scratch.vim
    if !exists("s:evalSelLog{logID}_BufNr") || 
                \ s:evalSelLog{logID}_BufNr == -1 || 
                \ bufnr(s:evalSelLog{logID}_BufNr) == -1
        if logfile != ""
            exec "edit ". logfile
            exec "saveas ". escape(logfile, '\')
        else
            if logID == ""
                split _EvalSelectionLog_
            else
                exec "split _EvalSelection_".logID."_"
            endif
            setlocal buftype=nofile
            setlocal bufhidden=hide
            setlocal noswapfile
        endif
        let s:evalSelLog{logID}_BufNr = bufnr("%")
    else
        let bwn = bufwinnr(s:evalSelLog{logID}_BufNr)
        if bwn > -1
            exe bwn . "wincmd w"
        else
            exe "sbuffer ".s:evalSelLog{logID}_BufNr
        endif
    endif

    " if logfile != ""
    "     setlocal buftype=nofile
    "     " setlocal bufhidden=delete
    "     setlocal bufhidden=hide
    "     setlocal noswapfile
    "     " setlocal buflisted
    " endif
    setlocal ft=EvalSelectionLog

    if dbg
        let @d = txt
        exe 'norm! $"dp'
    else
        call s:LogAppend("")
        go 1
        if g:evalSelectionLogCommands && g:evalSelLastCmd != ""
            let evalSelLastCmd = "|| ". substitute(g:evalSelLastCmd, '\n\ze.', '|| ', 'g')
            if evalSelLastCmd =~ "\n$"
                " let sep = "=> "
                let sep = ""
            else
                " let sep = "\n=> "
                let sep = "\n"
            endif
            call s:LogAppend(evalSelLastCmd . sep . txt, 1)
        else
            call s:LogAppend(txt, 1)
        endif
        if g:evalSelectionLogTime
            let t = "|| -----".strftime("%c")."-----"
            if !g:evalSelectionSeparatedLog
                let t = t. g:evalSelLastCmdId
            endif
            call s:LogAppend(t)
        endif
        go 1
        let g:evalSelLastCmd   = ""
        let g:evalSelLastCmdId = ""
        redraw!
    endif
    exe currWin . "wincmd w"
endf


function! evalselection#CmdLine(lang) "{{{3
    let lang = tolower(a:lang)
    while 1
        let @e = input(a:lang." (exit with ^D+Enter):\n")
        if @e == ""
            break
        elseif @e == ""
            let g:evalSelLastCmdId = lang
            call evalselection#Log("''")
        else
            let g:evalSelLastCmd = substitute(@e, "\n$", "", "")
            call EvalSelection_{lang}("EvalSelectionLog")
        endif
    endwh
    echo
endf



" evalselection#ParagraphMappings(log, ?select=vip)
function! evalselection#ParagraphMappings(log, ...) "{{{3
    let select = a:0 >= 1 ? a:1 : "vip"
    let op = a:log ? "l" : "x"
    exec "nmap <buffer> ". g:evelSelectionEvalExpression ." ". select . g:evalSelectionAutoLeader . op
    exec "vmap <buffer> ". g:evelSelectionEvalExpression ." ". g:evalSelectionAutoLeader . op
endf



""" Interaction with an interpreter {{{1

if !has("ruby") "{{{2
    finish
endif


let s:windows = has("win32") || has("win64") || has("win16")

""" Parameters {{{1
if !exists("g:evalSelectionRubyDir") "{{{2
    let g:evalSelectionRubyDir = ""
    " if s:windows
    "     if exists('$HOME')
    "         let g:evalSelectionRubyDir = $HOME."/vimfiles/ruby/"
    "     else
    "         let g:evalSelectionRubyDir = $VIM."/vimfiles/ruby/"
    "     endif
    " else
    "     let g:evalSelectionRubyDir = "~/.vim/ruby/"
    " endif
endif


""" Code {{{1

function! evalselection#CompleteCurrentWord(...) "{{{3
    if a:0 >= 1 && a:1 != ""
        " call evalselection#CompleteCurrentWordInsert(a:1, 0)
        exec "norm! a". a:1
    elseif has("menu")
        let e = @e
        try
            norm! viw"ey
            if exists("*EvalSelectionCompleteCurrentWord_". &filetype)
                try
                    aunmenu PopUp.EvalSelection
                catch
                endtry
                call EvalSelectionCompleteCurrentWord_{&filetype}(@e)
                popup PopUp.EvalSelection
            else
                echom "Unknown filetype"
            end
        finally
            let @e = e
        endtry
    else
        echom "No +menu support. Please use :EvalSelectionCompleteCurrentWord from the command line."
    endif
endf

function! evalselection#CompleteCurrentWordInsert(word, remove_menu) "{{{3
    exec "norm! viwda". a:word
    if has("menu") && a:remove_menu
        aunmenu PopUp.EvalSelection
    endif
endf

function! evalselection#GetWordCompletions(ArgLead, CmdLine, CursorPos) "{{{3
    if exists("*EvalSelectionGetWordCompletions_". &filetype)
        return EvalSelectionGetWordCompletions_{&filetype}(a:ArgLead, a:CmdLine, a:CursorPos)
    else
        return a:ArgLead
    endif
endf

function! evalselection#Talk(id, body) "{{{3
    " let id   = escape(a:id, '"\')
    " let body = escape(a:body, '"\')
    let id   = escape(a:id, '\')
    let body = escape(a:body, '\')
    ruby EvalSelection.talk(VIM::evaluate("id"), VIM::evaluate("body"))
endf

try
    if empty(g:evalSelectionRubyDir)
        exec "rubyfile ". findfile('ruby/EvalSelection.rb', &rtp)
    else
        exec "rubyfile ".g:evalSelectionRubyDir."EvalSelection.rb"
    endif
catch /EvalSelection.rb/
    echom 'Please redefine g:evalSelectionRubyDir: '. g:evalSelectionRubyDir
endtry

autocmd VimLeave * ruby EvalSelection.tear_down_all


let &cpo = s:save_cpo
unlet s:save_cpo
