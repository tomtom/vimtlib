" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-03-01.
" @Last Change: 2010-03-15.
" @Revision:    29

runtime autoload/prototype/binding.vim


SpecBegin 'title': 'Bindings'



It should define a simple binding.

let x = 2
let y = "foo"
let z = {"bar": 10}
Binding foo = x y z
function! foo._(a) dict
    return a:a * self.x
endf
let x = 5
let y = "x"
let z = {}

Should be equal foo._(10), 20



It should unpack bindings.

function! Bar(binding)
    exec prototype#AsVim(a:binding)
    return [x, y, z]
endf

Should be equal Bar(foo), [2, "foo", {"bar": 10}]


