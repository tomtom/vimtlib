" spec.vim -- Behaviour-driven design for VIM
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2009-03-06.
" @Revision:    60
" GetLatestVimScripts: 0 0 :AutoInstall: spec.vim

if &cp || exists("loaded_spec")
    finish
endif
let loaded_spec = 1

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

TODO:
- SpecInclude spec.file
- Delete spec commands when done.


POSSIBLE ENHANCEMENTS:
- log to file???
- Pass, Fail (current spec)
- remote testing (maybe we don't need this if the use of feedkeys() is 
sufficient for most interactive tests)


CHANGES:
0.1
- Initial release

