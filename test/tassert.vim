" tAssert.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=vim-tAssert)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2006-12-13.
" @Last Change: 2009-02-21.
" @Revision:    0.87

fun! <SID>TestFunction(a, b)
    return a:a + a:b
endf

TAssertBegin! "General"

fun! TAssertTemporaryFunction(a, b)
    return a:a + a:b
endf

TAssert should#be#A(1, 'Number')
TAssert! 0 == 0
TAssert! 0 == 1
TAssert! should#be#Equal(0, 1)
TAssert! "bla" == "bla"
TAssert should#be#A(1, 'Number')
TAssert should#be#A('a', 'String')
TAssert should#be#A('a', ['List', 'String'])
TAssert should#be#A([1,2], 'List')
TAssert should#be#A({1:2}, 'Dictionary')
" finish

let vard1 = {'data': [1,2,3], 'a': function('TAssertTemporaryFunction'), 'b': function('TAssertTemporaryFunction')}
let vard2 = {'data': [], 'a': 1, 'b': 1}
TAssert should#be#A(vard1, vard2)
" c is private
TAssert should#be#A(vard1, {'a': 0, 'b': 1, 'c': 0})
" c is public
TAssert !should#be#A(vard1, {'a': 0, 'b': 1, 'c': 1})

TAssert! should#be#Number(1)
TAssert! should#be#String("foo")
TAssert! should#be#Funcref(function('should#be#Funcref'))
TAssert! should#be#List([1,2,3])
TAssert! should#be#Dictionary({1:2})
TAssert! !should#be#Number("Foo")
TAssert! ! should#be#Number(1)
TAssert! !should#be#String(1)
TAssert! !should#be#Funcref({1:2})
TAssert! !should#be#List(function('should#be#Funcref'))
TAssert! !should#be#Dictionary([1,2,3])
TAssert! should#be#Exception('0 + [1]') =~ ':E745:'
TAssert! <SID>TestFunction(1, 2) == 3
TAssertEnd var varl vard vard1 vard2 TAssertTemporaryFunction()

TAssert! !exists('TAssertTemporaryFunction()')

TAssertBegin! "Switch context", 'plugin/00tAssert.vim'
TAssert <SID>TassertTest(1) == 2
TAssertEnd

TAssertBegin! "Unfulfilled assertions"
TAssert! should#be#Equal(0, 1)
TAssert! should#be#Number("Foo")
TAssert! should#be#String(1)
TAssert! should#be#Funcref({1:2})
TAssert! should#be#List(function('should#be#Funcref'))
TAssert! should#be#Dictionary([1,2,3])
TAssert! should#be#Error('0 + [1]', ':E999:')
TAssert! should#be#Exception('0 + 1') =~ ':E745:'
TAssertEnd 

call should#test#Init()
TAssert should#be#Equal(tassert#Val('autoload/should/test.vim', 's:foo'), 123)
TAssert should#be#Unequal(tassert#Val('autoload/should/test.vim', 's:foo'), 1)
TAssert! should#be#Equal(tassert#Val('autoload/should/test.vim', 's:foo'), 1)


