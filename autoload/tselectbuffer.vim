" tselectbuffer.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-03-25.
" @Revision:    0.0.6

let s:save_cpo = &cpo
set cpo&vim
" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


function! s:SNR()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
endf

" Possible values:
"   bufnr :: Default behaviour
"   mru   :: Sort buffers according to most recent use
"
" NOTE: MRU order works on second invocation only. If you want to always 
" use MRU order, call tlib#buffer#EnableMRU() in your ~/.vimrc file.
TLet g:tselectbuffer_order = 'bufnr'

if !exists('g:tselectbuffer_autopick') | let g:tselectbuffer_autopick = 1 | endif
if !exists('g:tselectbuffer_handlers')
    let g:tselectbuffer_handlers = [
                \ {'key':  4, 'agent': s:SNR().'AgentDeleteBuffer', 'key_name': '<c-d>', 'help': 'Delete buffer(s)'},
                \ {'key': 21, 'agent': s:SNR().'AgentRenameBuffer', 'key_name': '<c-u>', 'help': 'Rename buffer(s)'},
                \ {'key': 19, 'agent': s:SNR().'AgentSplitBuffer',  'key_name': '<c-s>', 'help': 'Show in split window'},
                \ {'key': 20, 'agent': s:SNR().'AgentTabBuffer',    'key_name': '<c-t>', 'help': 'Show in tab'},
                \ {'key': 22, 'agent': s:SNR().'AgentVSplitBuffer', 'key_name': '<c-v>', 'help': 'Show in vsplit window'},
                \ {'key': 23, 'agent': s:SNR().'AgentOpenBuffer',   'key_name': '<c-w>', 'help': 'View in current window'},
                \ {'key': 60, 'agent': s:SNR().'AgentJumpBuffer',   'key_name': '<',     'help': 'Jump to opened window/tab à la swb=opentab'},
                \ {'return_agent': s:SNR() .'Callback'},
                \ ]
    if !g:tselectbuffer_autopick
        call add(g:tselectbuffer_handlers, {'pick_last_item': 0})
    endif
endif

function! s:PrepareSelectBuffer()
    let [s:selectbuffer_nr, s:selectbuffer_list] = tlib#buffer#GetList(s:selectbuffer_hidden, 1, g:tselectbuffer_order)
    let s:selectbuffer_alternate = ''
    let s:selectbuffer_alternate_n = 0
    for b in s:selectbuffer_list
        let s:selectbuffer_alternate_n -= 1
        if b =~ '^\s*\d\+\s\+#'
            let s:selectbuffer_alternate = b
            let s:selectbuffer_alternate_n = -s:selectbuffer_alternate_n
            break
        endif
    endfor
    if s:selectbuffer_alternate_n < 0
        let s:selectbuffer_alternate_n = 0
    endif
    return s:selectbuffer_list
endf

function! s:GetBufNr(buffer)
    " TLogVAR a:buffer
    let bi = index(s:selectbuffer_list, a:buffer)
    " TLogVAR bi
    let bx = s:selectbuffer_nr[bi]
    " TLogVAR bx
    return 0 + bx
endf

function! s:RenameThisBuffer(buffer)
    let bx = s:GetBufNr(a:buffer)
    let on = bufname(bx)
    let nn = input('Rename buffer: ', on)
    if !empty(nn) && nn != on
        exec 'buffer '. bx
        if filereadable(on) && &buftype !~ '\<nofile\>'
            " if filewritable(nn)
                call rename(on, nn)
                echom 'Rename file: '. on .' -> '. nn
            " else
            "     echoerr 'File cannot be renamed: '. nn
            " endif
        endif
        exec 'file! '. escape(nn, ' %#')
        echom 'Rename buffer: '. on .' -> '. nn
        return 1
    endif
    return 0
endf

function! s:AgentRenameBuffer(world, selected)
    call a:world.CloseScratch()
    for buffer in a:selected
        call s:RenameThisBuffer(buffer)
    endfor
    let a:world.state = 'reset'
    let a:world.base  = s:PrepareSelectBuffer()
    " let a:world.index_table = s:selectbuffer_nr
    return a:world
endf

function! s:DeleteThisBuffer(buffer)
    let bx = s:GetBufNr(a:buffer)
    call inputsave()
    let doit = input('Delete buffer "'. bufname(bx) .'"? (y/N) ', s:delete_this_buffer_default)
    call inputrestore()
    if doit ==? 'y'
        if doit ==# 'Y'
            let s:delete_this_buffer_default = 'y'
        endif
        if bufloaded(bx)
            exec 'bdelete '. bx
            echom 'Delete buffer '. bx .': '. a:buffer
        else
            exec 'bwipeout '. bx
            echom 'Wipe out buffer '. bx .': '. a:buffer
        end
        return 1
    endif
    return 0
endf

function! s:AgentDeleteBuffer(world, selected)
    call a:world.CloseScratch(0)
    let s:delete_this_buffer_default = ''
    for buffer in a:selected
        " TLogVAR buffer
        call s:DeleteThisBuffer(buffer)
    endfor
    let a:world.state = 'reset'
    let a:world.base  = s:PrepareSelectBuffer()
    " let a:world.index_table = s:selectbuffer_nr
    return a:world
endf

function! s:GetBufferNames(selected) "{{{3
    return map(copy(a:selected), 'bufname(s:GetBufNr(v:val))')
endf

function! s:AgentSplitBuffer(world, selected)
    return tlib#agent#EditFileInSplit(a:world, s:GetBufferNames(a:selected))
endf

function! s:AgentVSplitBuffer(world, selected)
    return tlib#agent#EditFileInVSplit(a:world, s:GetBufferNames(a:selected))
endf

function! s:AgentOpenBuffer(world, selected)
    return tlib#agent#ViewFile(a:world, s:GetBufferNames(a:selected))
endf

function! s:AgentTabBuffer(world, selected)
    return tlib#agent#EditFileInTab(a:world, s:GetBufferNames(a:selected))
endf

function! s:AgentJumpBuffer(world, selected) "{{{3
    let bn = s:GetBufNr(a:selected[0])
    " TLogVAR bn
    let tw = tlib#tab#TabWinNr(bn)
    " TLogVAR tw
    if !empty(tw)
        call a:world.CloseScratch()
        " let w = tlib#agent#Suspend(a:world, a:selected)
        " if w.state =~ '\<suspend\>'
            " call w.SwitchWindow('win')
            let [tn, wn] = tw
            call tlib#tab#Set(tn)
            call tlib#win#Set(wn)
            " return w
        " endif
    else
        let a:world.status = 'redisplay'
    endif
    return a:world
endf

function! s:SwitchToBuffer(world, buffer, ...)
    TVarArg ['cmd', 'buffer']
    let bi = s:GetBufNr(a:buffer)
    " TLogVAR a:buffer
    " TLogVAR bi
    if bi > 0
        let back = a:world.SwitchWindow('win')
        " TLogDBG cmd .' '. bi
        exec cmd .' '. bi
        " exec back
    endif
endf


function! s:Callback(world, selected) "{{{3
    let cmd = len(a:selected) > 1 ? 'sbuffer' : 'buffer'
    for b in a:selected
        " TLogVAR b
        call s:SwitchToBuffer(a:world, b, cmd)
    endfor
endf


function! tselectbuffer#Select(show_hidden)
    let s:selectbuffer_hidden = a:show_hidden
    let bs  = s:PrepareSelectBuffer()
    let bhs = copy(g:tselectbuffer_handlers)
    " call add(bhs, {'index_table': s:selectbuffer_nr})
    if !empty(s:selectbuffer_alternate_n)
        call add(bhs, {'initial_index': s:selectbuffer_alternate_n})
    endif
    let msg = printf('Select buffer (%s)', g:tselectbuffer_order)
    let b = tlib#input#List('m', msg, bs, bhs)
endf


let &cpo = s:save_cpo
unlet s:save_cpo
