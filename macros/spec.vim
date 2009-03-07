" spec.vim
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2009-03-06.
" @Revision:    57

if &cp || exists("loaded_macros_spec")
    finish
endif
let loaded_macros_spec = 1

let s:save_cpo = &cpo
set cpo&vim


" :display: SpecBegin [ARGUMENTS AS INNER DICTIONNARY]
" Establish the environment for the current specification.
"
" Known keys for ARGUMENTS:
"
"   title   ... The test's title.
"   file    ... The script context.
"   before  ... Code to be run before each test (only effective when run 
"               via |:SPecRun|.
"   after   ... Code to be run after each test (only effective when run 
"               via |:SPecRun|.
"   scratch ... Run spec in scratch buffer. If the value is "", use an 
"               empty buffer. If it is "%", read the spec file itself 
"               into the scratch buffer. Otherwise read the file of the 
"               given name.
"   cleanup ... A list of function names that will be removed
"   options ... Run the spec against these options (a list of 
"               dictionnaries).
" 
" NOTES:
" Any global variables that were not defined at the time of the last 
" invocation of |:SpecBegin| are considered temporary variables and will 
" be removed.
"
" A specification file *should* ;-) include exactly one :SpecBegin 
" command.
command! -nargs=* SpecBegin call spec#__Begin({<args>}, expand("<sfile>:p"))


" :display: SpecInclude _FILENAME
" Include a spec file. The filename of the included type should begin 
" with an underscore and it should not contain a |:SpecBegin| command.
command! -nargs=1 SpecInclude call spec#Include(<args>, 0)


" :display: It[!] MESSAGE
" Insert a message.
" The message will be displayed when running the spec in verbose mode. 
" With [!], the message will be included in the quickfix list to mark a 
" pending specification.
command! -nargs=1 -bang It call spec#__Comment('It '. <q-args>, !empty('<bang>'))


" " :display: The MESSAGE
" " Insert a message.
" command! -nargs=1 The call spec#__Comment('The '. <q-args>)


" :display: Should {expr}
" Make sure that the value of an expression is not |empty()|. If used 
" after a |:SpecBegin| command, any occurrences of "<SID>" in the 
" expression is replaced with the current script's |<SNR>|.
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


" :display: Replay[!] MACRO
" Replay a recorded key sequence.
" With [!], the argument is passed unprocessed on to |spec#Replay()|. 
" Otherwise, the macro is evaluated as in |expr-quote|.
command! -nargs=1 -bang Replay if empty("<bang>")
            \ | call spec#Replay(eval('"'. escape(<q-args>, '"') .'"'))
            \ | else
                \ | call spec#Replay(<q-args>)
                \ | endif


let &cpo = s:save_cpo
unlet s:save_cpo
