" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-02-26.
" @Last Change: 2010-02-27.
" @Revision:    131

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



It should delegate to a (super) prototype.

let o2 = prototype#New({'x': 'B'}, o1)
function! o2.Bar(b) dict "{{{3
    return (self.b + a:b) * 1000 + self.__prototype.Bar(a:b)
endf

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

Should be equal o2.Bar, Bar_o2a
Should be equal o2.Foo(10), 20
Should be equal o2.Bar(10), 13013
Should be equal o2.a, 300
Should be equal o2.b, 3



It should inherit methods from "grand-parents".

Should be equal o2.La("La"), "Sing La"



It should call inherited methods that call inherited methods.

Should be equal o2.Ref(3), "Ref BBB___"



It should throw an error on unknown methods.

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
Should be equal x2.b, 3
    


It should change the prototype.

let x1a = prototype#New({'a': 20, 'b': 30, 'c': 50})
function! x1a.Foo(a) dict "{{{3
    return "x1a-". (self.c * a:a)
endf
call x2.__Prototype(x1a)
Should be equal x2.Foo(10), "x1a-500"



let &cpo = s:save_cpo
unlet s:save_cpo
