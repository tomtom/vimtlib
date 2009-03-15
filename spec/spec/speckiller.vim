" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-06.
" @Last Change: 2009-03-14.

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:spec_foo')
    let g:spec_foo = "foo"
endif

SpecBegin 'title': 'Option sets',
            \ 'sfile': 'autoload/spec.vim',
            \ 'options': [
            \ {'&l:hidden': 1, '&acd': 0, 'g:spec_foo': 'bar'},
            \ {'&l:hidden': 0, '&acd': 1, 'g:spec_foo': 'bar'},
            \ ]

" echom "Round ". spec#Val('s:spec_perm')

if spec#Val('s:spec_perm') >= 0
    It should test the spec against option sets (:SpecBegin).
    Should &hidden || &acd
    Should not (&hidden && &acd)
    Should be equal &hidden + &acd, 1

    Should be equal g:spec_foo, 'bar'
else
    Should be equal g:spec_foo, 'foo'
endif


let &cpo = s:save_cpo
unlet s:save_cpo
