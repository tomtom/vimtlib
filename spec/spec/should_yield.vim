" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-06.
" @Last Change: 2009-03-06.

let s:save_cpo = &cpo
set cpo&vim


let g:test_file = expand('<sfile>:p:h') .'/'
SpecBegin 'title': 'Should yield', 'sfile': 'autoload/should/yield.vim',
            \ 'scratch': [g:test_file . "test_yield.txt"]

It should test buffer content.
Should yield#Buffer(':silent 1,3delete', g:test_file.'test_yield1.txt')
Should not yield#Buffer(':silent 1,3delete', g:test_file.'should_yield.vim')

It should test squeezed buffer content.
Should yield#SqueezedBuffer(':silent 1,3delete', g:test_file.'test_yield2.txt')
Should not yield#SqueezedBuffer(':silent 1,3delete', g:test_file.'should_yield.vim')


let &cpo = s:save_cpo
unlet s:save_cpo
