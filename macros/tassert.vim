" tassert.vim
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-21.
" @Last Change: 2009-02-21.
" @Revision:    12

if &cp || exists("loaded_macros_tassert")
    finish
endif
let loaded_macros_assert = 1

let s:save_cpo = &cpo
set cpo&vim


" :display: TAssertBegin [ARGUMENTS AS INNER DICTIONNARY]
" Known keys for ARGUMENTS:
"
"   title    ... The test's title.
"   file     ... The script context.
"   setup    ... Code to be run before each test (only effective when 
"                run via |:TAssertRun|.
"   teardown ... Code to be run after each test (only effective when run 
"                via |:TAssertRun|.
"
" When using tassert as a poor man's unit testing framework, put 
" your tests between :TAssertBegin ... :TAssertEnd command.
"
" This command marks the beginning of a sequence some assertions and 
" takes an optional message string as argument. The second command (a 
" regexp) can be used to evaluate functions prefixed with |<SID>| in a 
" different context.
"
" With [!] the title is logged.
command! -nargs=* -bang TAssertBegin call tassert#Begin({<args>}, expand("<sfile>:p"), "<bang>")

" :display: TAssertEnd [VAR1 VAR2 ... FUNCTION1 FUNCTION2 ...]
" Mark the end of a sequence of assertions. Call |:unlet| for 
" temporary variables or |:delfunction| for temporary functions 
" named on the command line.
command! -nargs=* -bang TAssertEnd  call tassert#End(split(<q-args>, '\s\+'))


let &cpo = s:save_cpo
unlet s:save_cpo
