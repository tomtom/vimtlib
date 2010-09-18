" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-06.
" @Last Change: 2009-03-06.

let s:save_cpo = &cpo
set cpo&vim


SpecBegin 'title': 'Should throw', 'sfile': 'autoload/should/throw.vim'

It should test for exceptions.
Should throw#Something('1 + [2]')
Should not throw#Something('1 + 2')

It should test for specific exceptions.
Should throw#Exception('1 + [2]', ':E745:')
Should not throw#Exception('1 + [2]', ':E746:')


let &cpo = s:save_cpo
unlet s:save_cpo
