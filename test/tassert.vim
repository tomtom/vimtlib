" tAssert.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=vim-tAssert)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2006-12-13.
" @Last Change: 2009-02-08.
" @Revision:    0.66

fun! <SID>TestFunction(a, b)
    return a:a + a:b
endf

TAssertBegin! "General"

fun! TAssertTemporaryFunction(a, b)
    return a:a + a:b
endf

TAssert! 0 == 0
TAssert! 0 == 1
TAssert! IsEqual(0, 1)
TAssert! "bla" == "bla"
TAssert IsA(1, 'Number')
TAssert IsA('a', 'String')
TAssert IsA('a', ['List', 'String'])
TAssert IsA([1,2], 'List')
TAssert IsA({1:2}, 'Dictionary')
finish

let vard1 = {'data': [1,2,3], 'a': function('TAssertTemporaryFunction'), 'b': function('TAssertTemporaryFunction')}
let vard2 = {'data': [], 'a': 1, 'b': 1}
TAssert IsA(vard1, vard2)
" c is private
TAssert IsA(vard1, {'a': 0, 'b': 1, 'c': 0})
" c is public
TAssert !IsA(vard1, {'a': 0, 'b': 1, 'c': 1})

TAssert! IsNumber(1)
TAssert! IsString("foo")
TAssert! IsFuncref(function('IsFuncref'))
TAssert! IsList([1,2,3])
TAssert! IsDictionary({1:2})
TAssert! !IsNumber("Foo")
TAssert! !IsString(1)
TAssert! !IsFuncref({1:2})
TAssert! !IsList(function('IsFuncref'))
TAssert! !IsDictionary([1,2,3])
TAssert! IsException('0 + [1]') =~ ':E745:'
TAssert! <SID>TestFunction(1, 2) == 3
TAssertEnd var varl vard vard1 vard2 TAssertTemporaryFunction()

TAssert! !exists('TAssertTemporaryFunction()')

TAssertBegin! "Switching context", 'plugin/00tAssert.vim'
TAssert! <SID>Test(1) == 2
TAssertEnd

TAssertBegin! "Unfulfilled assertions"
TAssert! IsEqual(0, 1)
TAssert! IsNumber("Foo")
TAssert! IsString(1)
TAssert! IsFuncref({1:2})
TAssert! IsList(function('IsFuncref'))
TAssert! IsDictionary([1,2,3])
TAssert! IsError('0 + [1]', ':E999:')
TAssert! IsException('0 + 1') =~ ':E745:'
TAssertEnd 

TAssert IsEqual(TAssertVal('tSkeleton.vim', 's:tskelProcessing'), 0)
TAssert !IsEqual(TAssertVal('tSkeleton.vim', 's:tskelProcessing'), 1)

