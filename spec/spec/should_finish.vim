" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-06.
" @Last Change: 2009-03-07.

let s:save_cpo = &cpo
set cpo&vim


SpecBegin 'title': 'Should finish',
            \ 'sfile': 'autoload/should/finish.vim',
            \ 'cleanup': ['TakeTime()']

function! TakeTime(n) "{{{3
    for i in range(a:n)
    endfor
endf

echo "Spec 'finish': The following test could take up to 5 seconds."
It should measure execution time in seconds.
Should finish#InSecs(':2sleep', 3)
Should not finish#InSecs(':2sleep', 1)


if exists('g:loaded_tlib')

    It should measure in microseconds but this depends on your OS so it probably doesn't.
    Should finish#InMicroSecs('TakeTime(10)', 40)
    Should not finish#InMicroSecs('TakeTime(100000)', 20)

endif


let &cpo = s:save_cpo
unlet s:save_cpo
