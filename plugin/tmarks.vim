" tmarks.vim -- Browse & manipulate marks
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-08-23.
" @Last Change: 2009-03-29.
" @Revision:    0.0.46
" GetLatestVimScripts: <+SCRIPTID+> 1 tmarks.vim

if &cp || exists("loaded_tmarks")
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 11
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 11
        echoerr 'tlib >= 0.11 is required'
        finish
    endif
endif
let loaded_tmarks = 1
let s:save_cpo = &cpo
set cpo&vim


if !exists('g:tmarks_handlers') "{{{2
    let g:tmarks_handlers = [
            \ {'key':  4, 'agent': 'tmarks#AgentDeleteMark', 'key_name': '<c-d>', 'help': 'Delete mark'},
            \ ]
            " \ {'pick_last_item': 0},
endif


" Browse all marks.
command! -bar TMarks call tmarks#List()

" Place the next available a-z mark at the specified line.
" :display: :{range}TMarksPlace
command! -range -nargs=? -bar TMarksPlace call tmarks#PlaceNextMarkAtLine(<line1>)

" Delete all a-z marks in range.
" :display: :{range}TMarksDelete
command! -range -nargs=? -bar TMarksDelete call tmarks#DeleteInRange(<line1>, <line2>)

" Delete all a-z marks in the current buffer.
command! -bar TMarksDeleteAll call tmarks#DeleteAllMarks()


let &cpo = s:save_cpo
unlet s:save_cpo


finish

0.1
Initial release

