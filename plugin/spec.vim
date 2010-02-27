" spec.vim -- Behaviour-driven design for VIM script
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2010-02-27.
" @Revision:    68
" GetLatestVimScripts: 2580 0 :AutoInstall: spec.vim

if &cp || exists("loaded_spec")
    finish
endif
let loaded_spec = 2

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:spec_cwindow')
    " The command that should be used for viewing the quickfix list.
    let g:spec_cwindow = 'cwindow'   "{{{2
endif

if !exists('g:spec_option_sets')
    " If |g:spec_killer| is non-null, test your specs against these 
    " options -- a list of dictionaries.
    "
    " See also |:SpecBegin|.
    let g:spec_option_sets = []   "{{{2
endif

" if !exists('g:spec_vim')
"     " The (g)vim executable -- used for remote tests.
"     let g:spec_vim = 'gvim'  "{{{2
" endif


" :display: Spec[!] [PATH]
" Run one or more specification files.
"
" PATH can be either a file or a directory.
" 
" If PATH is a directory, run all vim files (whose name doesn't begin 
" with an underscore "_") under PATH as specification scripts.
"
" If no PATH is given, run the current file only.
" 
" With [!], also print a short list specifications by means of |:TLog|, 
" if available, or |:echom|. You might need to call |:messages| in order 
" to review this list.
"
" NOTES:
" Unit test scripts must not run other unit tests by using 
" |:source|. Use |:SpecInclude| if you have to include a vimscript file 
" that contains |:Should| commands.
"
" Even then it sometimes happens that spec cannot distinguish 
" between to identical tests in different contexts, which is why you 
" should only use one |:SpecBegin| command per file.
command! -nargs=? -complete=file -bang Spec
            \ | runtime macros/spec.vim
            \ | call spec#__Run(<q-args>, expand('%:p'), !empty("<bang>"))


" :display: SpecBegin [ARGUMENTS AS INNER DICTIONNARY]
" Establish the environment for the current specification.
" This command also serves as a saveguard that should prevent users from 
" running specs with the |:source| command.
"
" Known keys for ARGUMENTS:
"
"   title   ... The test's title.
"   file    ... The script context.
"   before  ... Code to be run before each test (only effective when run 
"               via |:SpecRun|.
"   after   ... Code to be run after each test (only effective when run 
"               via |:SpecRun|.
"   scratch ... Run spec in scratch buffer. If the value is "", use an 
"               empty buffer. If it is "%", read the spec file itself 
"               into the scratch buffer. Otherwise read the file of the 
"               given name.
"   cleanup ... A list of function names that will be removed
"   options ... Run the spec against these options (a list of 
"               dictionnaries or 'vim' for the default option set).
"               NOTE: If you test your specs against vim default 
"               settings, it's possible that you have to restart vim in 
"               order to get the usual environment.
" 
" NOTES:
" Any global variables that were not defined at the time of the last 
" invocation of |:SpecBegin| are considered temporary variables and will 
" be removed.
"
" A specification file *should* ;-) include exactly one :SpecBegin 
" command.
command! -nargs=* SpecBegin call spec#__Begin({<args>}, expand("<sfile>:p"))


" Include the line "exec SpecInit()" in your script in order to install 
" the function s:SpecVal(), which can be used to evaluate expressions in 
" script context. This initializations is necessary only if you call the 
" function |spec#Val()| in your tests.
fun! SpecInit()
    return "function! s:SpecVal(expr)\nreturn eval(a:expr)\nendf"
endf


let &cpo = s:save_cpo
unlet s:save_cpo
finish

TODO: SpecInclude spec.file
TODO: Delete spec commands when done.


POSSIBLE ENHANCEMENTS:
- log to file???
- Pass, Fail (current spec)
- remote testing (maybe we don't need this if the use of feedkeys() is 
sufficient for most interactive tests)


CHANGES:
0.1
- Initial release

0.2
- Display a message after having run all specs
- Raise an error when :SpecBegin is not called in a spec context (i.e. 
via the :Spec command)

