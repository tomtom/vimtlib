" setsyntax.vim -- Syntax-specific options
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-11-18.
" @Last Change: 2009-02-15.
" @Revision:    0.5.70
" GetLatestVimScripts: 2076 0 setsyntax.vim

if &cp || exists("loaded_setsyntax")
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 21
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 21
        echoerr 'tlib >= 0.21 is required'
        finish
    endif
endif
if !exists('g:loaded_hookcursormoved') || g:loaded_hookcursormoved < 7
    echoerr 'hookcursormoved >= 0.7 is required'
    finish
endif
let loaded_setsyntax = 5

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:setsyntax_options')
    " This variable is a dictionary of dictionaries of dictionaries.
    " {FILETYPE => {SYNREGEXP => {OPTION/VARIABLE: VALUE}}}
    " Be aware that VALUE is an expression that will be passed through 
    " |eval()|.
    "
    " Example: >
    "   let g:setsyntax_options['tex'] = {'^texMathZone': {'&l:tw': 0}}
    " :nodefault:
    let g:setsyntax_options = {}   "{{{2
    let g:setsyntax_options['tex'] = {'^texMath': {'&l:tw': 0, '&l:spelllang': '""'}}
    let g:setsyntax_options['viki'] = {'^texmath': {'&l:tw': 0, '&l:spelllang': '""'}}
endif

augroup SetSyntax
    autocmd!
    au Filetype * call setsyntax#Initialize()
augroup END


" :display: :SetSyntax SYNTAX,... VAR VALUE ...
" Alternative forms: >
"   :SetSyntax /REGEXP/ VAR VALUE ...
"   :SetSyntax SYNTAX1,SYNTAX2,... VAR=VALUE ...
"   :SetSyntax /REGEXP/ VAR=VALUE ...
" < Set syntax-specific options for the current buffer. When using a 
" REGEXP, the syntax names have to be already defined, i.e. you can use 
" the REGEXP only after the syntax file was loaded.
"
" VAR must be a variable name (see |:let| and |:let-&| for details). 
" I.e., if you want to set a option, e.g. spelllang, don't use >
"   SetSyntax /^texMath/ spelllang ""
" < but instead use: >
"   SetSyntax /^texMath/ &l:spelllang ""
" < 
" If VAR is "+", evaluate the expression when entering a syntax 
" regions, when VAR is "-", evaluate the expression when leaving a 
" syntax.
" Example: >
"   SetSyntax /^texMath/ + echo\ "Enter\ Math" - echo\ "Leave\ Math"
" < 
" VALUE actually is an expression that will be evaluated when setting 
" the variable.
"
" NOTE: Blanks and backslashes in VALUE must be escaped with a 
" backslash. See the help page on <f-args> for details.
command! -nargs=+ SetSyntax call setsyntax#SetSyntax(<f-args>)


let &cpo = s:save_cpo
unlet s:save_cpo


finish
CHANGES:
0.1
- Initial release

0.2
- Defined viki regions

0.3
- SetSyntax command
- Require tlib >= 0.21, hookcursormoved >= 0.7
- Look-up should be slightly faster now

0.4
- SetSyntax command: enable a more traditional syntax VAR=VALUE
- +, - pseudo variables (enter, leave a syntax group)

0.5
- Make sure tlib is loaded even if it is installed in a different 
rtp-directory.

