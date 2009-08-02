" hookcursormoved.vim
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-10-04.
" @Last Change: 2009-08-01.
" @Revision:    0.8.126
" GetLatestVimScripts: 2037 1 hookcursormoved.vim

if &cp || exists("loaded_hookcursormoved")
    finish
endif
let loaded_hookcursormoved = 9

let s:save_cpo = &cpo
set cpo&vim


" :doc:
" Modes:
"

if !exists('g:hookcursormoved_linechange')
    " The cursor moved between lines.
    let g:hookcursormoved_linechange = 'hookcursormoved#Test_linechange'   "{{{2
endif

if !exists('g:hookcursormoved_parenthesis')
    " The cursor is over any kind of parenthesis/bracket/brace.
    let g:hookcursormoved_parenthesis = 'hookcursormoved#Test_parenthesis'   "{{{2
endif

if !exists('g:hookcursormoved_parenthesis_round')
    " The cursor is over (, ).
    let g:hookcursormoved_parenthesis_round = 'hookcursormoved#Test_parenthesis_round'   "{{{2
endif

if !exists('g:hookcursormoved_parenthesis_round_open')
    " The cursor is over (.
    let g:hookcursormoved_parenthesis_round_open = 'hookcursormoved#Test_parenthesis_round_open'   "{{{2
endif

if !exists('g:hookcursormoved_parenthesis_round_close')
    " The cursor is over ).
    let g:hookcursormoved_parenthesis_round_close = 'hookcursormoved#Test_parenthesis_round_close'   "{{{2
endif

if !exists('g:hookcursormoved_syntaxchange')
    " The cursor moved in/out of a syntax region. 
    let g:hookcursormoved_syntaxchange = 'hookcursormoved#Test_syntaxchange' "{{{2
endif

if !exists('g:hookcursormoved_syntaxleave')
    " The cursor moved out of a syntax region. The syntax names that are 
    " taken into consideration are restricted by the 
    " b:hookcursormoved_syntaxleave (LIST) variable.
    let g:hookcursormoved_syntaxleave = 'hookcursormoved#Test_syntaxleave'   "{{{2
endif

if !exists('g:hookcursormoved_syntaxleave_oneline')
    " Like g:hookcursormoved_syntaxleave but also consider line 
    " changes.
    let g:hookcursormoved_syntaxleave_oneline = 'hookcursormoved#Test_syntaxleave_oneline'   "{{{2
endif


augroup HookCursorMoved
    autocmd!
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo


finish

CHANGES
0.1
- Initial release

0.2
- Renamed s:Enable() to hookcursormoved#Enable()
- Renamed s:enabled to b:hookcursormoved_enabled

0.3
- Defined parenthesis, syntaxleave_oneline conditions
- Removed namespace parameter (everything is buffer-local)
- Perform less checks (this should be no problem, if you use #Register).

0.4
- Defined parenthesis_round

0.5
- hookcursormoved#Register() takes mode as optional 3rd argument which 
allows to check a condition only in insert or only in normal mode.
- Defined parenthesis_round_open and parenthesis_round_close.
- Modes are now defined via the g:hookcursormoved_{mode} variable (the 
function name as string).

0.6
- Check correct column in syntax* tests.

0.7
- Minor tweaks
- FIX: Check correct column in s:CheckChars()

0.8
- hookcursormoved#Register: Allow deregister

0.9
- hookcursormoved#Register: Print a message on unknown hooks (don't 
throw an error)
- hookcursormoved#Register: If g:hookcursormoved_linechange is 
undefined, assume the plugin wasn't loaded.
