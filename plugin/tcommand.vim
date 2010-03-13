" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/vimtlib/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-03-12.
" @Last Change: 2010-03-13.
" @Revision:    7
" GetLatestVimScripts: 0 0 :AutoInstall: tcommand.vim
" Select and execute a command or menu item from a list

if &cp || exists("loaded_tcommand")
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 36
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 36
        echoerr 'tlib >= 0.36 is required'
        finish
    endif
endif
let loaded_tcommand = 1

let s:save_cpo = &cpo
set cpo&vim


" :display: TCommand[!] [INITIAL_FILTER]
" With a '!', reset the list of known commands and menu items.
command! -bang -nargs=? TCommand call tcommand#Select(!empty("<bang>"), <q-args>)


let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release

