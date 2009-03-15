" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-14.
" @Last Change: 2009-03-14.

let s:save_cpo = &cpo
set cpo&vim


SpecBegin 'title': 'Option sets',
            \ 'sfile': 'autoload/spec.vim',
            \ 'options': [
            \ 'vim',
            \ ]


if spec#Val('s:spec_perm') >= 0
    Should be equal &cpo, 'aABceFs'
endif


let &cpo = s:save_cpo
unlet s:save_cpo
