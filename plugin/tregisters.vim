" tregisters.vim -- List, edit, and run/execute registers/clipboards
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-08-22.
" @Last Change: 2010-01-03.
" @Revision:    120
" GetLatestVimScripts: 2017 1 tregisters.vim

if &cp || exists("loaded_tregisters")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 26
    echoerr 'tlib >= 0.26 is required'
    finish
endif
let loaded_tregisters = 3

let s:save_cpo = &cpo
set cpo&vim


" List the registers as returned by |:reg|. You will be able to edit 
" certain registers (see |g:tregisters_ro|).
command! TRegisters call tregisters#List()


let &cpo = s:save_cpo

finish
------------------------------------------------------------------------

Command~
:TRegister
    List the registers as returned by |:reg|.

Keys~
    <c-e> ... Edit register/clipboard
    <c-q> ... Execute register (see |@|)
    <cr>  ... Put selected register(s) (see |:put|)
    <esc> ... Cancel


CHANGES
0.1 (0.2)
Initial release

0.2
- Require tlib 0.26

0.3
- Moved the definition of some variables from plugin/tregisters.vim to 
autoload/tregisters.vim

