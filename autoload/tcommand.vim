" tcommand.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-03-12.
" @Last Change: 2010-03-14.
" @Revision:    189

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:tcommand#world')
    let g:tcommand#world = {
                \ 'type': 's',
                \ 'query': 'Select command',
                \ 'pick_last_item': 0,
                \ 'resize': '&lines / 3',
                \ 'key_handlers': [
                \ {'key':  "\<f1>", 'agent': 'tcommand#Info', 'key_name': '<c-o>', 'help': 'Show info'},
                \ {'key':  23, 'agent': 'tcommand#WhereFrom', 'key_name': '<c-w>', 'help': 'Where is the command defined'}
                \ ]
                \ }
    " \ 'scratch_pos': 'leftabove',
    " \ 'scratch_vertical': -1,
    " \ 'resize_vertical': 34,

    function! g:tcommand#world.SetStatusline(query) dict "{{{3
        echo
        echo self.DisplayFilter() .': '. matchstr(self.CurrentItem(), '^\S\+')
    endf
endif


" Hide entries matching this rx.
TLet g:tcommand#hide_rx = '\C\(^\(ToolBar\|Popup\|Hilfe\|Help\)\>\)'


" The items that should be displayed.
TLet g:tcommand#what = {'command': 's:CollectCommands', 'menu': 's:CollectMenuItems'}


let s:commands = []


function! tcommand#Select(reset, filter) "{{{3
    let w = copy(g:tcommand#world)
    if !empty(a:filter)
        let w.initial_filter = [[a:filter]]
    endif
    if empty(s:commands) || a:reset
        let s:commands = []
        for [what, fn] in items(g:tcommand#what)
            call call(fn, [s:commands])
        endfor
        if !empty(g:tcommand#hide_rx)
            call filter(s:commands, 'v:val !~ g:tcommand#hide_rx')
        endif
    endif
    let w.base = s:commands
    let v = winsaveview()
    let help = 0
    windo if &ft == 'help' | let help = 1 | endif
    try
        let item = tlib#input#ListD(w)
    finally
        if !help
            silent! windo if &ft == 'help' | exec 'wincmd c' | endif
        endif
        call winrestview(v)
        redraw
    endtry
    if !empty(item)
        let [item, type, modifier, nargs] = split(item, '\t')
        let item = substitute(item, '\s\+$', '', '')
        if type ==# 'C'
            let feed = ':'. item
            if nargs == '0'
                let feed .= "\<cr>"
            else
                if modifier != '!'
                    let feed .= ' '
                endif
            endif
            call feedkeys(feed)
        elseif type ==# 'M'
            exec 'emenu '. item
        else
            echoerr 'TCommand: Internal error: '. item
        endif
    endif
endf


" :nodoc:
function! tcommand#Info(world, selected) "{{{3
    " TLogVAR a:selected
    let bufnr = bufnr('%')
    try
        let [item, type, modifier, nargs] = split(a:selected[0], '\t')
        if type ==# 'C' && !empty(item)
            let vert = get(g:tcommand#world, 'scratch_vertical', 0) || winwidth(0) < 140 ? 'above' : 'vert'
            exec vert .' help '. item
        endif
    catch
        echohl Error
        echom "TCommand: ". v:exception
        echohl NONE
    finally
        exec bufwinnr(bufnr) .'wincmd w'
    endtry
    let a:world.state = 'redisplay'
    return a:world
endf


function! s:CollectCommands(acc) "{{{3
    let commands = tlib#cmd#OutputAsList('command')
    call remove(commands, 0)
    call map(commands, 's:FormatCommand(v:val)')
    call extend(a:acc, commands)
endf


function! s:MatchCommand(string) "{{{3
    let match = matchlist(a:string, '\([!"b ]\)\s\+\(\S\+\)\s\+\(.\)')
    return match
endf


function! s:FormatCommand(cmd0) "{{{3
    let match = s:MatchCommand(a:cmd0)
    return s:FormatItem(match[2], 'C', match[1], match[3])
endf


function! s:FormatItem(item, type, modifier, nargs) "{{{3
    let width = get(g:tcommand#world, 'scratch_vertical', 0) ? 30 : (winwidth(0) - 4)
    return printf("%-". width ."s\t%s\t%s\t%s", a:item, a:type, a:modifier, a:nargs)
endf


function! s:CollectMenuItems(acc) "{{{3
    let items = tlib#cmd#OutputAsList('menu')
    let menu = {0: ['']}
    let formattedmenuitem = ''
    for item in items
        let match = matchlist(item, '^\(\s*\)\(\d\+\)\s\+\([^-].\{-}\)\(\^I\(.*\)\)\?$')
        " TLogVAR item, match
        if !empty(match)
            " TLogVAR item, match
            let level = len(match[1])
            let parentlevel = -1
            for prevlevel in keys(menu)
                if prevlevel > level
                    call remove(menu, prevlevel)
                elseif prevlevel > parentlevel && prevlevel < level
                    let parentlevel = prevlevel
                endif
            endfor
            let cleanitem = substitute(match[3], '&', '', 'g')
            " let cleanitem = substitute(cleanitem, '\\\+\.', '.', 'g')
            if parentlevel >= 0
                let parent = menu[parentlevel]
                let menuitem = parent + [cleanitem]
            else
                let menuitem = [cleanitem]
            endif
            let menu[level] = menuitem
            let formattedmenuitem = s:FormatItem(join(map(copy(menuitem), 'escape(v:val, ''\.'')'), '.'), 'M', ' ', 0)
        elseif !empty(formattedmenuitem)
            if match(item, '^\s\+\l[*& -]\?\s') != -1
                " TLogVAR formattedmenuitem
                call add(a:acc, formattedmenuitem)
            endif
            let formattedmenuitem = ''
        endif
    endfor
endf


" :nodoc:
function! tcommand#WhereFrom(world, selected) "{{{3
    let [item, type, modifier, nargs] = split(a:selected[0], '\t')
    if type ==# 'C'
        " if exists(':WhereFrom')
        "     exec 'WhereFrom! '. item
        " else
            exec 'verbose command '. item
        " endif
        echohl MoreMsg
        echo "-- PRESS KEY TO CONTINUE --"
        echohl NONE
        call getchar()
        redraw
    endif
    let a:world.state = 'redisplay'
    return a:world
endf


let &cpo = s:save_cpo
unlet s:save_cpo
