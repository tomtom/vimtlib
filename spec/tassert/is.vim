" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-07.
" @Last Change: 2009-03-07.

let s:save_cpo = &cpo
set cpo&vim


runtime macros/tassert.vim


SpecBegin 'title': 'tassert Is* Macros'


Should IsA(1, 'number')
Should IsA("1", 'string')
Should IsA([1,2], 'list')
Should IsA({}, 'dictionary')
Should IsA(function('IsA'), 'funcref')

Should not IsA("1", 'number')
Should not IsA(1, 'string')
Should not IsA(function('IsA'), 'list')
Should not IsA([1,2], 'dictionary')
Should not IsA({}, 'funcref')

Should IsNumber(1)
Should IsString("1")
Should IsList([])
Should IsDictionary({})
Should IsFuncref(function('IsA'))
Should IsException('1 + [2]')
Should IsError('1 + [2]', 'E745:')
Should IsEqual(1, 1)
Should IsNotEqual(1, 2)
Should IsEmpty([])
Should IsNotEmpty([1])
Should IsMatch('123', '2')
Should IsNotMatch('123', '4')
Should IsExistent('*IsExistent')

Should not IsNumber("1")
Should not IsString(1)
Should not IsList(function('IsA'))
Should not IsDictionary([])
Should not IsFuncref({})
Should not IsException('1 + 2')
Should not IsError('1 + [2]', 'E744:')
Should not IsEqual(1, 2)
Should not IsNotEqual(1, 1)
Should not IsEmpty([1])
Should not IsNotEmpty([])
Should not IsMatch('123', '4')
Should not IsNotMatch('123', '2')
Should not IsExistent('*IsFoo')


let &cpo = s:save_cpo
unlet s:save_cpo
