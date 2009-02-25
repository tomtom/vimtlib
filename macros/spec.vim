" spec.vim
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2009-02-25.
" @Revision:    24

if &cp || exists("loaded_macros_spec")
    finish
endif
let loaded_macros_spec = 1

let s:save_cpo = &cpo
set cpo&vim


" :display: SPecBegin [ARGUMENTS AS INNER DICTIONNARY]
" Known keys for ARGUMENTS:
"
"   title  ... The test's title.
"   file   ... The script context.
"   before ... Code to be run before each test (only effective when 
"              run via |:SPecRun|.
"   after  ... Code to be run after each test (only effective when run 
"              via |:SPecRun|.
"
" When using spec as a poor man's unit testing framework, put 
" your tests between :SPecBegin ... :SPecEnd command.
"
" This command marks the beginning of a sequence some assertions and 
" takes an optional message string as argument. The second command (a 
" regexp) can be used to evaluate functions prefixed with |<SID>| in a 
" different context.
command! -nargs=* SpecBegin call spec#__Begin({<args>}, expand("<sfile>:p"))


" :display: SPecEnd [VAR1 VAR2 ... FUNCTION1 FUNCTION2 ...]
" Mark the end of a sequence of assertions. Call |:unlet| for 
" temporary variables or |:delfunction| for temporary functions 
" named on the command line.
"
" CAVEAT: Any global variables that were not defined at the time of the 
" last invocation of |:SpecBegin| are considered temporary variables and 
" will be removed.
command! -nargs=* SpecEnd call spec#__End(split(<q-args>, '\s\+'))


" :display: It MESSAGE
" Insert a message.
command! -nargs=1 It call spec#__Comment('It '. <q-args>)


" " :display: The MESSAGE
" " Insert a message.
" command! -nargs=1 The call spec#__Comment('The '. <q-args>)


" :display: Should {expr}
" Test that an expression doesn't evaluate to something |empty()|. 
" If used after a |:SpecBegin| command, any occurrences of 
" "<SID>" in the expression is replaced with the current script's 
" |<SNR>|.
command! -nargs=1 Should
            \ let s:spec_reason = '' |
            \ call spec#__Setup() |
            \ try |
            \   let s:spec_failed = empty(eval(spec#__Rewrite(<q-args>))) |
            \ catch |
            \   let s:spec_reason = v:exception |
            \   let s:spec_failed = 1 |
            \ endtry |
            \ call spec#__Teardown() |
            \ if s:spec_failed |
            \   call should#__InsertReason(<q-args>) |
            \   if !empty(s:spec_reason) | call should#__InsertReason(s:spec_reason) | endif |
            \   call spec#__AddQFL(<q-args>, should#__ClearReasons()) |
            \ endif


let &cpo = s:save_cpo
unlet s:save_cpo
