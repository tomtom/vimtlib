" rubymath.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-15.
" @Last Change: 2010-02-20.
" @Revision:    0.0.53

if &cp || !has('ruby')
    throw "No +ruby support."
    finish
endif
let s:save_cpo = &cpo
set cpo&vim


function! worksheet#rubymath#InitializeInterpreter(worksheet) "{{{3
    ruby <<EOR
    require 'mathn'
    include Math
EOR
endf


function! worksheet#rubymath#InitializeBuffer(worksheet) "{{{3
    return worksheet#ruby#InitializeBuffer(a:worksheet)
endf


let &cpo = s:save_cpo
unlet s:save_cpo
