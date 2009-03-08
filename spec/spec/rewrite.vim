" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-07.
" @Last Change: 2009-03-07.

let s:save_cpo = &cpo
set cpo&vim

call spec#RewriteRule('^!\?\zsfoo \(\d\+\) bar \(\d\+\).*', '(\1 == \2)')

SpecBegin 'title': 'Spec: Rewrite rules'


Should be equal spec#__Rewrite('foo 1 bar 1'), '(1 == 1)'
Should be equal spec#__Rewrite('not foo 1 bar 1'), '!(1 == 1)'

Should foo 1 bar 1.
Should not foo 1 bar 2.


let &cpo = s:save_cpo
unlet s:save_cpo
