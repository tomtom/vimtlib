" EvalSelection.vim -- evaluate selected vim/ruby/... code
" @Author:      Tom Link (micathom AT gmail com)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     29-Jän-2004.
" @Last Change: 2010-01-07.
" @Revision:    886
" 
" vimscript #889
" 
" TODO: find & fix compilation errors
" TODO: fix interaction errors
"

""" Basic Functionality {{{1

if &cp || exists("s:loaded_evalselection") "{{{2
    finish
endif
let s:loaded_evalselection = 17

" Parameters {{{2
if !exists("g:evalSelectionLeader")         | let g:evalSelectionLeader         = '<Leader>e' | endif "{{{2
if !exists("g:evalSelectionRegisterLeader") | let g:evalSelectionRegisterLeader = '<Leader>E' | endif "{{{2
if !exists("g:evalSelectionAutoLeader")     | let g:evalSelectionAutoLeader     = '<Leader>x' | endif "{{{2
if !exists("g:evelSelectionEvalExpression") | let g:evelSelectionEvalExpression = '<LocalLeader>r' | endif "{{{2

if !exists('g:evalSelectionFiletypes')
    let g:evalSelectionFiletypes = ['vim']   "{{{2
endif

if !exists("g:evalSelectionPluginMenu") "{{{2
    let g:evalSelectionPluginMenu = "Plugin.EvalSelection."
endif

let s:evalSelModes     = "xeparl"


function! EvalSelectionGenerateBindingsHelper(mapmode, mapleader, lang, modes, eyank, edelete) "{{{3
    let es   = "call EvalSelection_". a:lang
    let eslc = ':let g:evalSelLastCmd = substitute(@e, "\n$", "", "")<CR>'
    if a:modes =~# "x"
        exe a:mapmode .'noremap <silent> '. a:mapleader ."x ".
                    \ a:eyank . eslc.':'.es.'("")<CR>'
    endif
    if a:modes =~# "e"
        exe a:mapmode .'noremap <silent> '. a:mapleader ."e ".
                    \ a:eyank . eslc.':silent '.es.'("")<CR>'
    endif
    if a:modes =~# "p"
        exe a:mapmode .'noremap <silent> '. a:mapleader ."p ".
                    \ a:eyank . eslc.':'.es.'("echomsg")<CR>'
    endif
    if a:modes =~# "a"
        exe a:mapmode .'noremap <silent> '. a:mapleader ."a ".
                    \ a:eyank .' `>'.eslc.':silent '.es. "('exe \"norm! a\".')<CR>"
    endif
    if a:modes =~# "r"
        exe a:mapmode .'noremap <silent> '. a:mapleader ."r ".
                    \ a:edelete .eslc.':silent '.es. "('exe \"norm! i\".')<CR>"
    endif
    if a:modes =~# "l"
        exe a:mapmode .'noremap <silent> '. a:mapleader ."l ".
                    \ a:eyank . eslc.':silent '.es. "('EvalSelectionLog')<CR>"
    endif
endf


function! EvalSelectionGenerateBindings(shortcut, lang, ...) "{{{3
    let modes = a:0 >= 1 ? a:1 : s:evalSelModes
    call EvalSelectionGenerateBindingsHelper("v", g:evalSelectionLeader . a:shortcut, a:lang, modes,
                \ '"ey', '"ed')
    call EvalSelectionGenerateBindingsHelper("", g:evalSelectionRegisterLeader . a:shortcut, a:lang, modes,
                \ "", "")
endf
call EvalSelectionGenerateBindingsHelper("v", g:evalSelectionAutoLeader, "{&ft}", s:evalSelModes,
            \ '"ey', '"ed')


command! -nargs=* EvalSelectionEcho call evalselection#Echo(<q-args>)

command! -nargs=* EvalSelectionLog call evalselection#Log(<q-args>)


if has('ruby')

    command! -nargs=1 EvalSelectionQuit ruby EvalSelection.tear_down(<q-args>)

    command! -nargs=? -complete=custom,evalselection#GetWordCompletions 
                \ EvalSelectionCompleteCurrentWord call evalselection#CompleteCurrentWord(<q-args>)

    command! -nargs=1 EvalSelectionCmdLine call evalselection#CmdLine(<q-args>)

    if has("menu") "{{{2
        amenu PopUp.--SepEvalSelection-- :
        amenu PopUp.Complete\ Word :EvalSelectionCompleteCurrentWord<cr>
    endif

endif


for s:ft in g:evalSelectionFiletypes
    call evalselection#{s:ft}#Init()
endfor
unlet! s:ft


finish

CHANGES:
0.5 :: Initial Release

0.6 :: Interaction with interpreters; separated logs; use of redir; 
EvalSelectionCmdLine (CLI like interaction) 

0.7 :: Improved interaction (e.g., multi-line commands in R); moved code 
depending on +ruby to EvalSelectionRuby.vim (thanks to Grant Bowman for 
pointing out this problem); saved all files in unix format; added 
python, perl, and tcl (I can't tell if they work) 

0.8 :: improved interaction with external interpreters (it's still not 
really usable but it's getting better); reunified EvalSelection.vim and 
EvalSelectionRuby.vim 

0.9 :: support for communication via win32 COM/OLE (R, SPSS); general 
calculator shortcuts 

0.10 :: capture interaction with R via R(D)COM; "RDCOM" uses a 2nd 
instance of gvim as a pager (it doesn't start RCmdr any more); "RDCOM 
Commander" uses RCmdr; "RDCOM Clean" and "RDCOM Commander Clean" modes; 
take care of functions with void results (like data, help.search ...) 

0.11
R: set working directory and load .Rdata if available, word completion, 
catch errors, build objects menu; SPSS: show data window, build menu; 
g:evalSelectionLogCommands defaults to 1; revamped log 

0.14
Fixed some menu-related problems; <LocalLeader>r shortkey for SPSS and R 
(work similarly to ctrl-r in the spss editor); display a more useful 
error message when communication via OLE goes wrong; possibility to save 
the interaction log; post setup & tear down hooks for external 
interpreters; don't use win32ole when not on windows

0.15
- Escape backslashes in EvalSelectionTalk()
- SPSS: Insert a space before variable names (as does SPSS)

0.16
- MzScheme support (thanks to Mark Smithfield)
- Catch errors on EvalSelectionQuit (you'll have to manually kill zombie 
processes)

0.17
- Moved the definition of some variables from plugin/EvalSelection.vim 
to autoload/evalselection.vim
- Supported filetypes have to be enabled in your vimrc file by creating 
an array of strings (g:evalSelectionFiletypes)
- mzscheme: Check for hasmapto("EvalSelection_mz(") (reported by Sergey 
Khorev)

