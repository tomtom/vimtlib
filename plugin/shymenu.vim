" shymenu.vim -- Show the menu bar only when pressing an accel key
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-11-12.
" @Last Change: 2010-05-23.
" @Revision:    161
" GetLatestVimScripts: 2437 0 shymenu.vim

if &cp || exists("loaded_shymenu")
    finish
endif
let loaded_shymenu = 4

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:shymenu_emenu')
    " If true, use |:emenu| instead of the GUI menu.
    let g:shymenu_emenu = !has('gui_running')   "{{{2
endif

if !exists('g:shymenu_termalt')
    " If true, make alt-keys work on the terminal. Requires 
    " |g:shymenu_emenu| to be true.
    let g:shymenu_termalt = !has('gui_running') "{{{2
endif

if !exists('g:shymenu_wildcharm')
    if &wildcharm == 0
        let g:shymenu_wildcharm = '<c-t>'
        exec 'set wildcharm='. g:shymenu_wildcharm
    elseif g:shymenu_emenu
        " The value of 'wildcharm' as string. If 'wildcharm' is unset 
        " (i.e. equals 0), it will be set to <c-t>.
        let g:shymenu_wildcharm = nr2char(&wildcharm) "{{{2
        " echoerr 'Please set g:shymenu_wildcharm. ShyMenu was not loaded'
        " finish
    endif
endif

if !exists('g:shymenu_modes')
    " A string that defines the modes for which the maps should be 
    " defined. On international keyboards, the alt-maps could conflict 
    " with special characters, which is why insert mode maps are 
    " disabled by default:
    "   n ... normal mode
    "   i ... insert mode
    let g:shymenu_modes = 'n'   "{{{2
endif

if !exists('g:shymenu_winpos_fullscreen')
    " If the output of |:winpos| matches this pattern, we assume the 
    " window is in fullscreen mode.
    let g:shymenu_winpos_fullscreen = '-\d$'   "{{{2
endif

if !exists('g:shymenu_items')
    " Custom menus (eg. buffer-local menus) that are not detected by 
    " shymenu.
    " Format: {KEY: NAME}
    let g:shymenu_items = {}  "{{{2
endif

if !exists('g:shymenu_blacklist')
    " An array of single-letter strings. Don't create maps for these 
    " keys.
    let g:shymenu_blacklist = []   "{{{2
endif

if !exists('g:shymenu_lines')
    " Increase/decrease 'lines' when hiding/showing the menu bar in 
    " order to maintain the overall window size.
    let g:shymenu_lines = 1   "{{{2
endif

if !exists('g:shymenu_options')
    " A list of options that shall be maintained.
    let g:shymenu_options = ['&cmdheight']   "{{{2
endif


function! s:ShyMenuCollect() "{{{3
    redir => itemss
    silent menu
    redir END
    let items = split(itemss, '\n')
    call filter(items, 'v:val =~ ''^\d''')
    let s:shymenu_items = copy(g:shymenu_items)
    for item in items
        let ml = matchlist(item, '^\(\d\+\)\s\+\(.*\)$')
        if get(ml, 1) > 1
            let key = matchstr(ml[2], '&\zs.')
            if empty(key)
                let key = ml[2][0]
            endif
            let key = tolower(key)
            if index(g:shymenu_blacklist, key) == -1
                let name0 = substitute(ml[2], '&', '', 'g')
                " TLogVAR key, name0
                let s:shymenu_items[key] = name0
            else
                " TLogVAR key
            endif
        endif
    endfor
endf
call s:ShyMenuCollect()

augroup ShyMenu
    autocmd!
augroup END

function! s:ShowMenu() "{{{3
    return &guioptions =~# 'm'
endf

let s:show_menu = s:ShowMenu()

function! s:IsFullScreen() "{{{3
    redir => winp
    silent winpos
    redir END
    return winp =~ g:shymenu_winpos_fullscreen
endf

function! s:InstallAutocmd() "{{{3
    let s:line = line('.')
    autocmd ShyMenu CursorMoved,CursorMovedI * if s:show_menu | call s:ShyMenuCursorMoved(0, '', s:line) | endif
    " autocmd ShyMenu BufEnter,BufWinEnter,CursorHold,CursorHoldI,FocusGained * if s:show_menu | call ShyMenu(0, '') | endif
    autocmd ShyMenu BufEnter,BufWinEnter,FocusGained * if s:show_menu | call ShyMenu(0, '') | endif
endf

function! s:UninstallAutocmd() "{{{3
    autocmd! ShyMenu
endf

function! s:SetTopLine(lineno) "{{{3
    if line('w0') != a:lineno
        " let pos = getpos('.')
        let view = winsaveview()
        exec 'keepjumps norm! '. a:lineno .'zt'
        " call setpos('.', pos)
        call winrestview(view)
    endif
endf

function! s:SetMenu(set_mode, mode) "{{{3
    if a:set_mode
        let topline = line('w0') + g:shymenu_lines
        if !s:IsFullScreen()
            let &lines -= g:shymenu_lines
        endif
        set guioptions+=m
        let s:show_menu = 1
        call s:InstallAutocmd()
    else
        let topline = line('w0') - g:shymenu_lines
        set guioptions-=m
        if !s:IsFullScreen()
            let &lines += g:shymenu_lines
        endif
        let s:show_menu = 0
        call s:UninstallAutocmd()
    endif
    if abs(a:mode) <= 1
        call s:SetTopLine(topline)
    endif
    if !a:set_mode
        redraw
    endif
endf


function! s:ShyMenuCursorMoved(mode, key, line) "{{{3
    if a:line != line('.')
        call ShyMenu(a:mode, a:key)
    endif
endf


" Set menu bar visibility.
" mode:
"   -1 ... toggle
"    0 ... hide
"    1 ... show
function! ShyMenu(mode, key) "{{{3
    let options = {}
    for o in g:shymenu_options
        exec 'let options[o] = '. o
    endfor
    if a:mode < 0
        if s:ShowMenu()
            call s:SetMenu(0, a:mode)
        else
            call s:SetMenu(1, a:mode)
        endif
    elseif a:mode > 0
        if !s:ShowMenu()
            call s:SetMenu(1, a:mode)
        endif
    else
        if s:ShowMenu()
            call s:SetMenu(0, a:mode)
        endif
    endif
    for o in g:shymenu_options
        " TLogVAR o, options[o]
        exec 'if '. o .' != options[o] | let '. o .' = '. options[o] .' | endif'
    endfor
    if has('win32') && !empty(a:key)
        exec 'simalt '. a:key
    endif
endf


function! ShyMenuShow(key) "{{{3
    call ShyMenu(2, '')
    return a:key
endf


let s:ttogglemenu = 0

function! s:ShyMenuInstall() "{{{3
    for [key, item] in items(s:shymenu_items)
        if g:shymenu_emenu
            if g:shymenu_modes =~ 'n'
                exec 'noremap <m-'. key .'> :emenu '. item .'.'. g:shymenu_wildcharm
            endif
            if g:shymenu_modes =~ 'i'
                exec 'inoremap <m-'. key .'> <c-o>:emenu '. item .'.'. g:shymenu_wildcharm
            endif
            let s:ttogglemenu = 0
            if g:shymenu_termalt
                exec 'set <m-'.key.'>='.key
            endif
        else
            if g:shymenu_modes =~ 'n'
                exec 'noremap <silent> <m-'. key .'> :call ShyMenu(1, '. string(key) .')<cr>'
            endif
            if g:shymenu_modes =~ 'i'
                exec 'inoremap <silent> <m-'. key .'> <c-o>:call ShyMenu(1, '. string(key) .')<cr>'
            endif
            let s:ttogglemenu = 1
        endif
    endfor
endf


autocmd ShyMenu VimEnter * call s:ShyMenuInstall()


map <expr> <f10> ShyMenuShow("\<f10>")
imap <expr> <f10> ShyMenuShow("\<f10>")


let &cpo = s:save_cpo
unlet s:save_cpo


finish
CHANGES:
0.1
- Initial release

0.2
- g:shymenu_modes: Disable insert mode maps by default (conflict with 
international characters)

0.3
- Typos (thanks AS Budden)
- Correct line offset if necessary
- Set g:shymenu_wildcharm from &wildcharm

0.4
- g:shymenu_options: A list of options that shall be maintained.

