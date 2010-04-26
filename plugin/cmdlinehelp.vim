" cmdlinehelp.vim -- Display help on the command in the command line
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-01.
" @Last Change: 2010-04-26.
" @Revision:    352
" GetLatestVimScripts: 2279 0 cmdlinehelp.vim

" :doc:
" NOTE:
" - This plugin temporarily sets &l:tags to g:cmdlinehelpTags. I hope 
"   this doesn't interfere with anything else.

if &cp || exists("loaded_cmdlinehelp")
    finish
endif
let loaded_cmdlinehelp = 6

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:cmdlinehelpMapView')
    " Default map.
    let g:cmdlinehelpMapView = '<f1>'  "{{{2
endif

if !exists('g:cmdlinehelpMapDown')
    let g:cmdlinehelpMapDown = '<c-pagedown>'   "{{{2
endif

if !exists('g:cmdlinehelpMapUp')
    let g:cmdlinehelpMapUp = '<c-pageup>'   "{{{2
endif


if !hasmapto('CmdLineHelpView', 'c')
    exec 'cnoremap <silent> '. g:cmdlinehelpMapView .' <c-\>ecmdlinehelp#Buffer()<cr><c-c>:call cmdlinehelp#View()<cr>'
end
if !hasmapto('CmdLineHelpUp', 'c')
    exec 'cnoremap <silent> '. g:cmdlinehelpMapUp .' <c-\>ecmdlinehelp#Buffer()<cr><c-c>:call cmdlinehelp#Up()<cr>'
end
if !hasmapto('CmdLineHelpDown', 'c')
    exec 'cnoremap <silent> '. g:cmdlinehelpMapDown .' <c-\>ecmdlinehelp#Buffer()<cr><c-c>:call cmdlinehelp#Down()<cr>'
end


" if &cpoptions !~# 'x'
"     cnoremap <esc> <c-c><c-w>z
" endif
" cnoremap <c-c> <c-c><c-w>z


let &cpo = s:save_cpo
unlet s:save_cpo


finish
CHANGES:
0.1
- Initial release

0.2
- g:cmdlinehelpTable
- FIX: wrong window after scrolling

0.3
- Preferred prefixes: g:cmdlinehelpPrefixes
- Display the help on the top of the preview window

0.4
- For :set, :setlocal, :let show help on the option/variable, not the command
- Catch e426 error.
- Added debug to g:cmdlinehelpIgnore

0.5
- Support for command with a bang [!]
- For :call, :echo[m] show help on the function not the command
- g:cmdlinehelpTable may contain references to custom helper function
- The keys in g:cmdlinehelpTable are regexps
- Don't scroll down one line

0.6
- Moved the definition of some variables from plugin/cmdlinehelp.vim to 
autoload/cmdlinehelp.vim
- g:cmdlinehelpMapView defaults to f1

