" spec.vim -- Behaviour-driven design for VIM
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2009-02-22.
" @Revision:    31
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


" :display: Spec [PATH]
" PATH can be either a file or a directory.
" 
" If PATH is a directory, run all vim files under PATH as specification 
" scripts.
"
" If no PATH is given, run the current file only.
"
" CAVEAT: Unit test scripts must not run other unit tests by 
" sourcing them. In order for spec to map the |:Spec| commands 
" onto the correct file & line number, any spec scripts have to be run 
" via :Spec.
"
" Even then it sometimes happens that spec cannot distinguish 
" between to identical tests in different contexts, which is why you 
" should only use one |:SpecBegin| command per file.
command! -nargs=? -complete=file -bang Spec
            \ | runtime macros/spec.vim
            \ | call spec#__Run(<q-args>, expand('%:p'), "<bang>")


" Put the line "exec SpecInit()" into your script in order to 
" install the function s:SpecVal(), which can be used to evaluate 
" expressions in script context. This initializations is necessary only 
" if you call the function |spec#Val()| in your 
" tests.
fun! SpecInit()
    return "function! s:SpecVal(expr)\nreturn eval(a:expr)\nendf"
endf


let &cpo = s:save_cpo
unlet s:save_cpo
finish

CHANGES:
0.1
- Initial release
