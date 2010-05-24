" trag.vim -- Jump to a file registered in your tags
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-09-29.
" @Last Change: 2010-05-24.
" @Revision:    609
" GetLatestVimScripts: 2033 1 trag.vim

if &cp || exists("loaded_trag")
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 37
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 37
        echoerr 'tlib >= 0.37 is required'
        finish
    endif
endif
let loaded_trag = 9

let s:save_cpo = &cpo
set cpo&vim


" :nodoc:
TLet g:trag_kinds = {}
" :nodoc:
TLet g:trag_filenames = {}
" :nodoc:
TLet g:trag_keyword_chars = {}


" :display: :TRagDefKind KIND FILETYPE /REGEXP_FORMAT/
" The regexp argument is no real regexp but a format string. % thus have 
" to be escaped with % (see |printf()| for details). The REGEXP_FORMAT 
" should contain at least one %s.
" Examples: >
"   TRagDefKind v * /\C\<%s\>\s*=[^=~<>]/
"   TRagDefKind v ruby /\C\<%s\>\(\s*,\s*[[:alnum:]_@$]\+\s*\)*\s*=[^=~<>]/
command! -nargs=1 TRagDefKind call trag#TRagDefKind(<q-args>)


" :display: TRagKeyword FILETYPE KEYWORD_CHARS
" Override 'iskeyword' for a certain filetype. See also |trag#CWord()|.
command! -nargs=+ TRagKeyword if len([<f-args>]) == 2
            \ | let g:trag_keyword_chars[[<f-args>][0]] = [<f-args>][1]
            \ | else
                \ | echoerr 'Expected "FILETYPE KEYWORDRX", but got: <q-args>'
                \ | endif


" :display: TRagDefFiletype FILETYPE EXTENSION ... FILENAME ...
" In order to recognize files based on their extension, you have to 
" declare filetypes first.
" If a file has no extension, the whole filename is used.
" On systems where the case of the filename doesn't matter (check :echo 
" has('fname_case')), EXTENSION should be defined in lower case letters.
" Examples: >
"   TRagDefFiletype html html htm xhtml
command! -nargs=+ TRagDefFiletype for e in [<f-args>][1:-1] | let g:trag_filenames[e] = [<f-args>][0] | endfor


" :display: :TRag[!] KIND [REGEXP]
" Run |:TRagsearch| and instantly display the result with |:TRagcw|.
" See |trag#Grep()| for help on the arguments.
" If the kind rx doesn't contain %s (e.g. todo), you can skip the 
" regexp.
"
" Examples: >
"     " Find any matches
"     TRag . foo
" 
"     " Find variable definitions (word on the left-hand): foo = 1
"     TRag l foo
" 
"     " Find variable __or__ function/method definitions
"     TRag d,l foo
" 
"     " Find function calls like: foo(a, b)
"     TRag f foo
"
"     " Find TODO markers
"     TRag todo
command! -nargs=1 -bang -bar TRag TRagsearch<bang> <args> | TRagcw
command! -nargs=1 -bang -bar Trag TRag<bang> <args>


" :display: :TRagfile
" Edit a file registered in your tag files.
command! TRagfile call trag#Edit()
command! Tragfile call trag#Edit()


" :display: :TRagcw
" Display a quick fix list using |tlib#input#ListD()|.
command! -bang -nargs=? TRagcw call trag#QuickListMaybe(!empty("<bang>"))
command! -bang -nargs=? Tragcw call trag#QuickListMaybe(!empty("<bang>"))

" :display: :Traglw
" Display a |location-list| using |tlib#input#ListD()|.
command! -nargs=? Traglw call trag#LocList()


" :display: :TRagsearch[!] KIND REGEXP
" Scan the files registered in your tag files for REGEXP. Generate a 
" quickfix list. With [!], append to the given list. The quickfix list 
" can be viewed with commands like |:cw| or |:TRagcw|.
"
" The REGEXP has to match a single line. This uses |readfile()| and the 
" scans the lines. This is an alternative to |:vimgrep|.
" If you choose your identifiers wisely, this should guide you well 
" through your sources.
" See |trag#Grep()| for help on the arguments.
command! -nargs=1 -bang -bar TRagsearch call trag#Grep(<q-args>, empty("<bang>"))
command! -nargs=1 -bang -bar Tragsearch TRagsearch<bang> <args>


" :display: :TRaggrep REGEXP [GLOBPATTERN]
" A 99%-replacement for grep. The glob pattern is optional.
"
" Example: >
"   :TRaggrep foo *.vim
"   :TRaggrep bar
command! -nargs=+ -bang -bar -complete=file TRaggrep
            \ let g:trag_grepargs = ['.', <f-args>]
            \ | call trag#Grep(g:trag_grepargs[0] .' '. g:trag_grepargs[1], empty("<bang>"), g:trag_grepargs[2:-1])
            \ | unlet g:trag_grepargs
            \ | TRagcw
command! -nargs=+ -bang -bar -complete=file Traggrep TRaggrep<bang> <args>


" :display: :TRagsetfiles [FILELIST]
" The file list is set only once per buffer. If the list of the project 
" files has changed, you have to run this command on order to reset the 
" per-buffer list.
"
" If no filelist is given, collect the files in your tags files.
"
" Examples: >
"   :TRagsetfiles
"   :TRagsetfiles split(glob('foo*.txt'), '\n')
command! -nargs=? -bar -complete=file TRagsetfiles call trag#SetFiles(<args>)

" :display: :TRagaddfiles FILELIST
" Add more files to the project list.
command! -nargs=1 -bar -complete=file TRagaddfiles call trag#AddFiles(<args>)

" :display: :TRagclearfiles
" Remove any files from the project list.
command! TRagclearfiles call trag#ClearFiles()

" :display: :TRagGitFiles GIT_REPOS
command! -nargs=1 -bar -complete=dir TRagGitFiles call trag#SetGitFiles(<q-args>)


let &cpo = s:save_cpo
unlet s:save_cpo


finish
CHANGES:
0.1
- Initial release

0.2
- Quite a few things have changed and I haven't had the time yet to test 
these changes thorougly. There is a chance that nested patterns thus 
don't work as described (please report).
- Enable search for more than one kinds at once (as comma-separated 
list)
- Enabled <c-e>: Run ex-command on selected lines (e.g. for refactoring 
purposes)
- Enabled <c-s>, <c-v>, <c-t>: Open selected lines in (vertically) split 
windows or tabs.
- Renamed vV kinds to lL (~ let)
- New kind: r/R (right hand side arguemnt of an assignment/let, i.e. 
value)
- New kind: fuzzy (typo-tolerant search)
- INCOMPATIBLE CHANGE: Renamed "mode" to "kind"
- TRag now has some idea of negation. E.g., "TRag !i,w call" will search 
for the word "call" but ignore matches in comments (if defined for the 
    current filetype)
- Alternative methods to define project files: g:trag_files, 
g:trag_glob, g:trag_project.
- Improved support for ruby, vim
- TRagKeyword, trag#CWord(): Customize keyword rx.
- g:trag_get_files
- [bg]:trag_project_{&filetype}: Name of the filetype-specific project 
files catalog (overrides [bg]:trag_project if defined)
- trag#Edit() will now initally select files with the same "basename 
root" (^\w\+) as the current buffer (the command is thus slightly more 
useful and can be used as an ad-hoc alternative file switcher)
- FIX: Match a line only once
- FIX: Caching of regexps

0.3
- Use vimgrep with set ei=all as default search mode (can be configured 
via g:trag_search_mode); by default trag now is a wrapper around vimgrep 
that does the handling of project-related file-sets and regexp builing 
for you.
- FIX: ruby/f regexp

0.4
- trag_proj* variables were renamed to trag_project*.
- Traggrep: Arguments have changed for conformity with grep commands (an 
implicit .-argument is prepended)
- Make sure tlib is loaded even if it is installed in a different 
rtp-directory.
- Post-process lines (strip whitespace) collected by vimgrep
- tlib#Edit(): for list input, set pick_last_item=0, show_empty=1
- Aliases for some commands: Trag, Traggrep ...

0.5
- Update the qfl when running a command on selected lines
- Enable certain operations for multiple choices
- Java, Ruby: x ... find subclasses (extends/implements)
- Experimental rename command for refactoring (general, java)
- NEW: [bg]:trag_get_files_{&filetype}
- Traggrep: If the second argument (glob pattern) is missing, the 
default file list will be used.

0.6
- trag#viki#Rename()
- Generalized trag#rename#Rename()
- Enabled "trace cursor" functionality (mapped to the <c-insert> key).
- :Traglw
- TRagGitFiles, trag#SetGitFiles(), g:trag_git

0.7
- trag#QuickList(): Accept a dict as optional argument.
- trag#Grep(): rx defaults to '\.{-}'
- trag#Grep(): use :g (instead of search()) for non-vimgrep mode

0.8
- Moved the definition of some variables from plugin/trag.vim to autoload/trag.vim
- :TRagcw! (show :cw even if there are no recognized errors)
- Require tlib 0.37

0.9
- g:trag#use_buffer

