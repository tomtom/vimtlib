" concordance.vim -- Concordance table
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-13.
" @Last Change: 2008-07-13.
" @Revision:    0.1.9
" GetLatestVimScripts: 0 0 concordance.vim

if &cp || exists("loaded_concordance")
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 23
    echoerr 'tlib >= 0.23 is required'
    finish
endif
let loaded_concordance = 1

let s:save_cpo = &cpo
set cpo&vim

TLet g:concordance_world = {
                \ 'type': 'm',
                \ 'query': 'Concordance table',
                \ 'pick_last_item': 0,
                \ 'scratch': '__concordance__',
                \ 'retrieve_eval': 'concordance#Collect(world, 0)',
                \ 'key_handlers': [
                    \ {'key': 60, 'agent': 'concordance#Explore',     'key_name': '<',     'help': 'Explore word occurences'},
                \ ],
            \ }
            " \ 'return_agent': 'concordance#GotoLine',
            " \ 'scratch_vertical': (&lines > &co),

command! Concordance call concordance#Concordance()


let &cpo = s:save_cpo
unlet s:save_cpo


finish
CHANGES:
0.1
- Initial release

