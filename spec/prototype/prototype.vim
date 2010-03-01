" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-02-26.
" @Last Change: 2010-03-01.
" @Revision:    244

let s:save_cpo = &cpo
set cpo&vim



SpecBegin 'title': 'Prototype'



It should define a simple prototype.

let p1 = prototype#New({'a': 2, 'b': 3, 'x': 'X'})
function! p1.Foo(a) dict "{{{3
    return self.a * a:a
endf
function! p1.Bar(b) dict "{{{3
    return self.b + a:b
endf
function! p1.La(c) dict "{{{3
    return "Sing ". a:c
endf
function! p1.SelfRef0(a) dict "{{{3
    return repeat(self.x, a:a)
endf


Should be equal p1.Foo(10), 20
Should be equal p1.Bar(10), 13
Should be equal p1.La("La"), "Sing La"



It should redefine methods.

let o1 = prototype#New(p1)
function! o1.Foo(a) dict "{{{3
    return -a:a
endf

Should be equal o1.Foo(10), -10
Should be equal o1.Bar(10), 13
Should be equal o1.La("La"), "Sing La"



It should not change p1.

Should be equal p1.Foo(10), 20
Should be equal p1.Bar(10), 13



It should call methods in a (super) object.

let o2 = prototype#New({'x': 'B'}, o1)
function! o2.Bar(b) dict "{{{3
    return (self.b + a:b) * 1000 + self.__prototype.Bar(a:b)
endf
" TLogVAR o2

Should be equal o2.Foo(10), -10
Should be equal o2.Bar(10), 13013
Should be equal o2.a, 2
Should be equal o2.b, 3
Should be equal o2.La("La"), "Sing La"



It should change the prototype while maintaining changed items.

let o1a = prototype#New({'a': 300, 'x': 'A'}, p1)
function! o1a.Foo(a) dict "{{{3
    return a:a * 2
endf
function! o1a.SelfRef1(a) dict "{{{3
    return repeat("_", a:a)
endf
function! o1a.Ref(a) dict "{{{3
    return "Ref ". self.SelfRef0(a:a) . self.SelfRef1(a:a)
endf
let o2a = copy(o2)

let Bar_o2a = o2.Bar
call o2.__Prototype(o1a)

Should not be equal o2.__prototype, o2a.__prototype
Should be equal o2.Bar, Bar_o2a
Should be equal o2.Foo(10), 20
Should be equal o2.Bar(10), 13013
Should be equal o2.a, 300
Should be equal o2.b, 3



It should inherit methods from "grand-parents".

Should be equal o2.La("La"), "Sing La"



It should call inherited methods that call inherited methods.

Should be equal o2.Ref(3), "Ref BBB___"



It should throw an error when calling unknown methods.

Should throw Exception 'g:o2.NoLa("La")', '^Vim(return):E716:'



It should call parent methods.

function! o2.La(a) dict "{{{3
    return "No, I don't want to ". self.__prototype.La(a:a)
endf

Should be equal o2.La("La"), "No, I don't want to Sing La"



It should not change p1.

Should be equal p1.Foo(10), 20
Should be equal p1.Bar(10), 13
Should be equal p1.La("La"), "Sing La"



It should not change o1.

Should be equal o1.Foo(10), -10
Should be equal o1.Bar(10), 13
Should be equal o1.a, 2
Should be equal o1.b, 3
Should be equal o1.La("La"), "Sing La"



It should define a prototype.

let x1 = prototype#New({'a': 2, 'b': 3})
function! x1.Foo(a) dict "{{{3
    return "x1-". (self.a * a:a)
endf

Should be equal x1.Foo(10), "x1-20"



It should inherit from a prototype.

let x2 = prototype#New({'a': 33}, x1)

Should be equal x2.Foo(10), "x1-330"
Should be equal x2.a, 33
Should be equal x2.b, 3
    


It should change the prototype.

let x1a = prototype#New({'a': 20, 'b': 30, 'c': 50})
function! x1a.Foo(a) dict "{{{3
    return "x1a-". (self.c * a:a)
endf
call x2.__Prototype(x1a)

Should be equal x2.Foo(10), "x1a-500"



It should fill in default values when using the getter.

let x = prototype#New()
let ncalls = 0
function! x.__Default(n) dict
    let g:ncalls += 1
    if a:n <= 1
        let self[a:n] = a:n
    else
        let self[a:n] = self.__Get(a:n - 2) + self.__Get(a:n - 1)
    endif
endfunction
Should be equal map(range(0, 10), 'x.__Get(v:val)'),
            \ [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55]
Should be equal ncalls, 11
Should be equal map(prototype#Keys(x, 1), 'x.__Get(v:val)'),
            \ [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55]



It should export objects as list.

Should be equal prototype#AsList(x, -1),
            \ [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55]

Should be equal ncalls, 11

Should be equal prototype#AsList({2: "a", 4: "b", -1: "c"}),
            \ ["", "", "a", "", "b"]

Should be equal prototype#AsList({2: "a", 4: "b", -1: "c"}, -1),
            \ [-1, -1, "a", -1, "b"]



It should export objects as dictionaries.

let x3 = prototype#New({'a': 33}, x1)
let d3 = prototype#AsDictionary(x3)

Should be equal sort(keys(d3)),
            \ ['Foo', 'a', 'b']



It should create an object from a list.

let l4 = ["foo", "bar"]
let x4 = prototype#New(l4)

Should be equal prototype#Keys(x4), ["0", "1"]
Should be equal prototype#AsList(x4), l4



let &cpo = s:save_cpo
unlet s:save_cpo
