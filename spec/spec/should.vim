" should.vim
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2009-02-25.
" @Revision:    62

let s:save_cpo = &cpo
set cpo&vim



SpecBegin 'title': 'Should be', 'sfile': 'autoload/should/be.vim'

Should be#A(1, 'number')

Should be#Number(1)
Should not be#Number("foo")

Should be#String("foo")
Should not be#String(1)

Should be#Funcref(function('should#be#Funcref'))
Should not be#Funcref(1)

Should be#List([1,2,3])
Should not be#List(1)

Should be#Dictionary({1:2})
Should not be#Dictionary([1,2,3])

Should be#Equal(1, 1)
Should be#Equal({1:2}, {1:2})
Should not be#Equal(1, 2)
Should not be#Equal(1, "1")
Should not be#Equal({1:2}, {1:3})

Should be#Unequal(1, 2)
Should be#Unequal(1, "2")
Should be#Unequal(1, "1")
Should not be#Unequal(1, 1)

Should be#Greater(2, 1)
Should not be#Greater(2, 2)

Should be#GreaterEqual(1, 1)
Should be#GreaterEqual(2, 1)
Should not be#GreaterEqual(2, 3)

Should be#Less(1, 2)
Should not be#Less(3, 2)

Should be#LessEqual(1, 1)
Should be#LessEqual(1, 2)
Should not be#LessEqual(3, 2)

SpecEnd



SpecBegin 'title': 'Should throw', 'sfile': 'autoload/should/throw.vim'

Should throw#Something('1 + [2]')
Should not throw#Something('1 + 2')

Should throw#Exception('1 + [2]', ':E745:')
Should not throw#Exception('1 + [2]', ':E746:')

SpecEnd



let g:test_file = expand('<sfile>:p:h') .'/'
SpecBegin 'title': 'Should yield', 'sfile': 'autoload/should/yield.vim',
            \ 'scratch': [g:test_file . "test_yield.txt"]

Should yield#Buffer('silent 1,3delete', g:test_file.'test_yield1.txt')
Should not yield#Buffer('silent 1,3delete', g:test_file.'should.vim')

Should yield#SqueezedBuffer('silent 1,3delete', g:test_file.'test_yield2.txt')
Should not yield#SqueezedBuffer('silent 1,3delete', g:test_file.'should.vim')

SpecEnd



if exists('g:loaded_tlib')

    SpecBegin 'title': 'Should finish', 'sfile': 'autoload/should/finish.vim'

    function! TakeTime(n) "{{{3
        for i in range(a:n)
        endfor
    endf

    echo "Spec 'finish': The following test could take up to 5 seconds."
    It should measure execution time in seconds.
    Should finish#InSecs(':2sleep', 3)
    Should not finish#InSecs(':2sleep', 1)

    It should measure in microseconds but this depends on your OS so it probably doesn't.
    Should finish#InMicroSecs('TakeTime(10)', 20)
    Should not finish#InMicroSecs('TakeTime(100000)', 20)

    SpecEnd TakeTime()

endif



let &cpo = s:save_cpo
unlet s:save_cpo
