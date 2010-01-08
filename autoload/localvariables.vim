" localvariables.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-05.
" @Last Change: 2010-01-05.
" @Revision:    0.0.5

let s:save_cpo = &cpo
set cpo&vim


fun! s:ConditionalLet(var,value)
    if !exists(a:var)
        exe "let ".a:var." = ".a:value
    endif
endf

call s:ConditionalLet("g:localVariablesRange",                 "30")
call s:ConditionalLet("g:localVariablesBegText",               "'Local Variables:'")
call s:ConditionalLet("g:localVariablesEndText",               "'End:'")
call s:ConditionalLet("g:localVariablesDownCaseHyphenedNames", "1")
call s:ConditionalLet("g:localVariablesVimlet",                "1")

delf s:ConditionalLet

let s:localVariablesAllowExec=1

fun! s:AskUser(prompt, default)
    if has("gui_running")
        let val = inputdialog(a:prompt, a:default)
    else
        call inputsave()
        let val = input(a:prompt, a:default)
        call inputrestore()
    endif
    return val
endf

if s:localVariablesAllowExec >= 1
    fun! s:AllowSpecial(class, value)
        let force = (a:value =~? 'localVariables\|system')
        if s:localVariablesAllowExec > 0
            if !force && s:localVariablesAllowExec == 3
                return 1
            else
                let default = s:localVariablesAllowExec == 2 ? "y" : "n"
                let options = s:localVariablesAllowExec == 2 ? "(Y/n)" : "(y/N)"
                return s:AskUser("LocalVariables: Allow ". a:class ." '".a:value."'? ".
                            \ options, default) ==? "y"
            endif
        else
            return 0
        endif
    endf
    fun! s:Execute(cmd)
        sandbox exec a:cmd
    endf
    fun! localvariables#AppendEvent(event, value)
        if !exists("b:LocalVariables". a:event)
            let pre = ""
        else
            let pre = b:LocalVariables{a:event} ."|"
        endif
        exe "let b:LocalVariables". a:event .' = "'. escape(pre, '"') . escape(a:value, '"') .'"'
    endf
else
    fun! s:AllowSpecial(class, value)
        return 0
    endf
    fun! s:Execute(cmd)
        echomsg "LocalVariables: Disabled: ".a:cmd
    endf
    fun! localvariables#AppendEvent(event, value)
        echomsg "LocalVariables: Disabled Event Handling: ".a:event."=".a:value
    endf
endif

fun! s:Set(line, prefix, suffix)
    let scope     = ""
    let prefixEnd = strlen(a:prefix)
    let scopeEnd  = matchend(a:line, "^.:", prefixEnd)
    if scopeEnd >= 0
        let scope = strpart(a:line, prefixEnd, 2)
    else
        let scopeEnd = prefixEnd
    endif
    
    let varEnd = matchend(a:line, '.\{-}:', scopeEnd)
    if varEnd >= 0
        let var = strpart(a:line, scopeEnd, varEnd-scopeEnd-1)
        if var =~ "-"
            if g:localVariablesDownCaseHyphenedNames
                let var = tolower(var)
            endif
            let var = substitute(var, "-\\(.\\)", "\\U\\1", "g")
        endif
    else
        throw "Local Variables: No variable name found in: ".a:line
    endif
    if scope == ""
        if exists("g:localVariableX".var)
            let var = g:localVariableX{var}
        elseif exists("*LocalVariableX".var)
            let scope = "X"
        else
            let scope = "b:"
        endif
    endif
    
    let value = matchstr(strpart(a:line, varEnd), '\V\^\s\*\zs\.\{-}\ze'. a:suffix .'\s\*\$')
    
    if scope == "::"
        if var =~ "^\\cexec\\(u\\(t\\(e\\)\\?\\)\\?\\)\\?$"
            if s:AllowSpecial("execute", value)
                call s:Execute(value)
            else
                echomsg "Local Variables: Disabled: ".value
            endif
        elseif var =~? '^On.\+'
            let event = matchstr(var, '\c^On\zs.\+')
            if s:AllowSpecial(event, value)
                call localvariables#AppendEvent(event, value)
            else
                echomsg "Local Variables: Disabled: ".value
            endif
        else
            throw "Local Variables: Unknown special name: ".var
        endif
    elseif scope ==# "X"
        if value =~ "^\\s*\\(\".*\"\\|'.*'\\)\\s*$"
            let value = substitute(value, "^\\s*\\(\"\\(.*\\)\"\\|'\\(.*\\)'\\)\\s*$", '\2', '')
        endif
        call LocalVariableX{var}(value)
    elseif var =~# "localVariablesAllowExec"
        throw "Local Variables: Can't set: ".var
    else
        if scope ==# "&:"
            exe 'setlocal '.var.'='.value
        else
            if !(value =~ "^\\s*\\(\".*\"\\|'.*'\\)\\s*$")
                let value = '"'.escape(value, '"\').'"'
            endif
            exe 'let '.scope.var.' = '.value
        endif
    endif
endf

fun! s:Search(repos)
    if a:repos
        let pos = getpos('.')
    endif
    let startline = line("$") - g:localVariablesRange
    call cursor(startline, 1)
    let rv = search("\\V\\C\\^\\(\\.\\*\\)". g:localVariablesBegText ."\\(\\.\\{-}\\)\\s\\*\\n\\(\\_^\\1\\.\\+:\\.\\+\\2\\n\\)\\*\\_^\\1". g:localVariablesEndText ."\\2\\s\\*\\$", "W")
    if a:repos
        call setpos('.', pos)
    endif
    return rv
endf 

fun! s:CheckLet()
    if g:localVariablesVimlet
        let rx = '\V\^\W\*vimlet:\s\*\zs\(\.\{-}\)\s\*\$'
        let rs = @/
        exec 'keepjumps silent g /'. rx .'/call s:CheckLetLet(rx, getline("."))'
        let @/ = rs
    endif
endf

fun! s:CheckLetLet(rx, line)
    let e = matchstr(a:line, a:rx)
    if e =~ '\S'
        let e = 'let b:'. substitute(e, '|\s*', '|let b:', 'g')
        try
            sandbox exec e
        catch
            echoerr 'localvariables: There was an error in your vimlet line: '. e
        endtry
    endif
endf

fun! localvariables#ReCheck()
    let cpos = getpos('.')
    let pos  = s:Search(0)
    if pos
        let line = getline(pos)
        let locVarBegPos = match(line, "\\V\\C".g:localVariablesBegText)
        if locVarBegPos >= 0
            " let prefix = strpart(line, 0, locVarBegPos)
            " let suffix = strpart(line, locVarBegPos + strlen(g:localVariablesBegText))
            let prefix = matchstr(line, '\V\C\^\zs\.\{-}\ze'. g:localVariablesBegText)
            let suffix = matchstr(line, '\V\C'. g:localVariablesBegText. '\zs\.\{-}\ze\s\*\$')
        else
            throw "Local Variables: Parsing error (please report)"
        endif
        let endRx  = '\V\C\^'
                    \ . escape(prefix, '\')
                    \ . g:localVariablesEndText
                    \ . escape(suffix, '\')
                    \ . '\s\*\$'
        let endPos = search(endRx, "W") - 1
        while pos < endPos
            let pos = pos + 1
            call s:Set(getline(pos), prefix, suffix)
        endwh
    endif
    call s:CheckLet()
    let b:localVariablesChecked = 1
    call setpos('.', cpos)
endf

fun! localvariables#Check()
    if !exists("b:localVariablesChecked")
        call localvariables#ReCheck()
    endif
endf

fun! localvariables#RunEventHook(event)
    if exists("b:LocalVariables". a:event)
        exe b:LocalVariables{a:event}
    endif
endf

fun! localvariables#RegisterHook(event, bang)
    if exists("b:LocalVariablesRegisteredHooks")
        if (b:LocalVariablesRegisteredHooks =~? "|". a:event ."|")
            if !(a:bang == "!")
                throw "Local Variables: Already registered for ". a:event
            else
                return
            endif
        else
            let b:LocalVariablesRegisteredHooks = b:LocalVariablesRegisteredHooks . a:event ."|"
        endif
    else
        let b:LocalVariablesRegisteredHooks = "|". a:event ."|"
    endif
    exe "au ". a:event ." * call localvariables#RunEventHook('". a:event ."')"
endf


let &cpo = s:save_cpo
unlet s:save_cpo
