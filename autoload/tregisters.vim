" tregisters.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.5

let s:save_cpo = &cpo
set cpo&vim
" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


function! s:SNR() "{{{3
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
endf


" Editing numbered registers doesn't make much sense as they change when 
" calling |:TRegister|.
TLet g:tregisters_ro = '~:.%#0123456789'

if !exists('g:tregisters_handlers') "{{{2
    let g:tregisters_handlers = [
            \ {'key':  5, 'agent': s:SNR() .'AgentEditRegister', 'key_name': '<c-e>', 'help': 'Edit register'},
            \ {'key': 17, 'agent': s:SNR() .'AgentRunRegister', 'key_name': '<c-q>', 'help': 'Run register'},
            \ {'pick_last_item': 0},
            \ {'return_agent': s:SNR() .'ReturnAgent'},
            \ ]
endif


function! s:GetRegisters() "{{{3
    let registers = tlib#cmd#OutputAsList('registers')
    call filter(registers, 'v:val =~ ''^"''')
    call map(registers, 'substitute(v:val, ''\s\+'', " ", "g")')
    return registers
endf


function! s:AgentEditRegister(world, selected) "{{{3
    let reg = a:selected[0][1]
    if stridx(g:tregisters_ro, reg) == -1
        let world  = tlib#agent#Suspend(a:world, a:selected)
        let regval = getreg(reg)
        keepalt call tlib#input#Edit('Registers', regval, s:SNR() .'EditCallback', [reg])
        return world
    else
        echom 'Read-only register'
        let a:world.state = 'redisplay'
        return a:world
    endif
endf


function! s:AgentRunRegister(world, selected) "{{{3
    let sb = a:world.SwitchWindow('win')
    try
        for r in a:selected
            let rr = r[1]
            if stridx('%#=', rr) == -1
                exec 'norm! @'. rr
            endif
        endfor
    finally
        exec sb
    endtry
    let a:world.state = 'redisplay'
    return a:world
endf


function! s:EditCallback(register, ok, text) "{{{3
    " TLogVAR a:register, a:ok, a:text
    if a:ok
        if stridx(g:tregisters_ro, a:register) == -1
            call setreg(a:register, a:text)
            let b:tlib_world.base = s:GetRegisters()
        else
            echom 'Read-only register'
        endif
    endif
    call tlib#input#Resume("world")
endf


function! s:ReturnAgent(world, selected) "{{{3
    " TLogVAR a:selected
    if !empty(a:selected)
        let reg = a:selected[0][1]
        " TLogVAR reg
        exec 'put '. reg
    endif
endf


function! tregisters#List() "{{{3
    let s:registers = s:GetRegisters()
    call tlib#input#List('s', 'Registers', s:registers, g:tregisters_handlers)
endf



let &cpo = s:save_cpo
unlet s:save_cpo
