" spec.vim
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2010-02-27.
" @Revision:    63

if &cp || exists("loaded_macros_spec")
    finish
endif
let loaded_macros_spec = 1

let s:save_cpo = &cpo
set cpo&vim


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
