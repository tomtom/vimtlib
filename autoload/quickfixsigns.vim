" quickfixsigns.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.lithom.net
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-03-19.
" @Last Change: 2010-03-19.
" @Revision:    0.0.13

let s:save_cpo = &cpo
set cpo&vim


function! quickfixsigns#CompleteSelect(ArgLead, CmdLine, CursorPos) "{{{3
    " TLogVAR a:ArgLead, a:CmdLine, a:CursorPos
    let start = len('quickfixsigns_class_')
    let vars = filter(keys(g:), 'v:val =~ ''^quickfixsigns_class_''. a:ArgLead')
    call map(vars, 'strpart(v:val, start)')
    let selected = split(a:CmdLine, '\s\+')
    call filter(vars, 'index(selected, v:val) == -1')
    if a:CmdLine =~ '\<QuickfixsignsSelect\s\+$'
        call insert(vars, join(g:quickfixsigns_classes))
    endif
    return vars
endf


redraw

let &cpo = s:save_cpo
unlet s:save_cpo
