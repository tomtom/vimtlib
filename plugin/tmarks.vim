" tmarks.vim -- Browse & manipulate marks
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-08-23.
" @Last Change: 2010-01-03.
" @Revision:    0.0.50
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
let loaded_tmarks = 2
let s:save_cpo = &cpo
set cpo&vim


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

0.2
- Moved the definition of some variables from plugin/tmarks.vim to 
autoload/tmarks.vim

