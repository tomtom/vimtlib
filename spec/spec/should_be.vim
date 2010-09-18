" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-06.
" @Last Change: 2009-03-06.

let s:save_cpo = &cpo
set cpo&vim


SpecBegin 'title': 'Should be', 'sfile': 'autoload/should/be.vim'

It should test if the argument is a number.
Should be#Number(1)
Should not be#Number("foo")

It should test if the argument is a string.
Should be#String("foo")
Should not be#String(1)

It should test if the argument is a funcref.
Should be#Funcref(function('should#be#Funcref'))
Should not be#Funcref(1)

It should test if the argument is a list.
Should be#List([1,2,3])
Should not be#List(1)

It should test if the argument is a dictionary.
Should be#Dictionary({1:2})
Should not be#Dictionary([1,2,3])

It should test if the argument is of a specified type.
Should be#A(1, 'number')
Should be a {"foo": "bar"}, 'dictionary'
Should not be a {"foo": "bar"}, 'list'

It should test for multiple types.
Should be a {"foo": "bar"}, ['list', 'dictionary']
Should not be a {"foo": "bar"}, ['number', 'string']

It should test for class equivalence.
Should be a {"foo": "bar"}, {"foo": 0}
Should be a {"foo": "bar"}, {"foo": 1}
Should be a {"foo": "bar"}, {"x": 0}
Should not be a {"foo": "bar"}, {"x": 1}

It should test for equality.
Should be#Equal(1, 1)
Should be#Equal({1:2}, {1:2})
Should not be#Equal(1, 2)
Should not be#Equal(1, "1")
Should not be#Equal({1:2}, {1:3})

It should test for inequality.
Should be#Unequal(1, 2)
Should be#Unequal(1, "2")
Should be#Unequal(1, "1")
Should not be#Unequal(1, 1)

It should test for <, <=, >, >=.
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

It should match strings.
Should be like "foo", '^f'
Should not be like "foo", '^x'
Should be unlike "foo", '^x'
Should be like "foo", '^f', '#'
Should be unlike "foo", '^F', '#'
Should be unlike "Foo", '^f', '#'
Should be like "Foo", '^F', '#'
Should be like "foo", '^F', '?'
Should be like "Foo", '^f', '?'


let &cpo = s:save_cpo
unlet s:save_cpo
