" worksheet.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-15.
" @Last Change: 2009-02-15.
" @Revision:    0.0.66

if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

syntax match WorksheetId /\\\@!\zs@\w\+@/

try
    " exec 'runtime syntax/'. b:worksheet.mode .'.vim'
    exec 'syntax include @WorksheetInputSyntax syntax/'. b:worksheet.syntax .'.vim'
    " unlet b:current_syntax
    syntax match WorksheetInput /^[^%`_].*/ transparent contains=@WorksheetInputSyntax,WorksheetId
catch
    syntax match WorksheetInput /^[^%`_].*/ transparent contains=WorksheetId
endtry

syntax match WorksheetHead /^___\[@\d\{4,}@\]_________\[.\{-}\]___\+$/ contains=WorksheetId nextgroup=WorksheetInput
syntax match WorksheetBody /^`  .*/
syntax match WorksheetComment /^%.*/


if version < 508
    command! -nargs=+ HiLink hi link <args>
else
    command! -nargs=+ HiLink hi def link <args>
endif
HiLink WorksheetHead Question
HiLink WorksheetId TagName
HiLink WorksheetBody Statement
HiLink WorksheetComment Comment


delcommand HiLink
let b:current_syntax = 'worksheet'
