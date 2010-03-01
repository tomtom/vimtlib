" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-02-26.
" @Last Change: 2010-03-01.
" @Revision:    239

let s:save_cpo = &cpo
set cpo&vim



SpecBegin 'title': 'Prototype'

if 0
endif


It should define a simple prototype.

let p1 = prototype#strict#New({'a': 2, 'b': 3, 'x': 'X'})
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

let o1 = prototype#strict#New(p1)
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

let o2 = prototype#strict#New({'x': 'B'}, o1)
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

let o1a = prototype#strict#New({'a': 300, 'x': 'A'}, p1)
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

let x1 = prototype#strict#New({'a': 2, 'b': 3})
function! x1.Foo(a) dict "{{{3
    return "x1-". (self.a * a:a)
endf

Should be equal x1.Foo(10), "x1-20"



It should inherit from a prototype.

let x2 = prototype#strict#New({'a': 33}, x1)

Should be equal x2.Foo(10), "x1-330"
Should be equal x2.a, 33
Should be equal x2.b, 3
    


It should change the prototype.

let x1a = prototype#strict#New({'a': 20, 'b': 30, 'c': 50})
function! x1a.Foo(a) dict "{{{3
    return "x1a-". (self.c * a:a)
endf
call x2.__Prototype(x1a)

Should be equal x2.Foo(10), "x1a-500"



It should throw an exception on type mismatch.

let t1 = prototype#strict#New({"x": 1}, x1)

Should be equal t1.x, 1
Should be equal keys(t1.__abstract), ['x']

let t1.x = [1, 2]
Should throw Exception 'prototype#strict#Validate(g:t1)', '^Prototype: Expected '



It should throw an exception on type mismatch with the prototype.

let t2 = prototype#strict#New({"x": 1}, x1)

Should be equal t2.a, 2
Should be equal keys(t2.__abstract), ['x']

let t2.a = [1]
Should throw Exception 'prototype#strict#Validate(g:t2)', '^Prototype: Expected '



It should throw an exception on type mismatch when cloning.

let t3 = prototype#strict#New({"x": 1}, x1)

Should not throw Exception 'prototype#strict#Clone(g:t3)', '^Prototype: Expected '
let t3.x = [1]
Should throw Exception 'prototype#strict#Clone(g:t3)', '^Prototype: Expected '



It should throw an expected on type mismatch with the prototype.

Should be a x1.a, 'Number'
Should throw Exception 'prototype#strict#New({"a": [1]}, g:x1)', '^Prototype: Expected '



It should throw an expected on type mismatch when setting an attribute.

Should be a x1.a, 'Number'
Should throw Exception 'g:x1.__Set("a", [1])', '^Prototype: Expected '



It should validate fields.

let t4 = prototype#strict#New({"x": 1, "y": 2})
Should be equal keys(t4.__abstract), ['x', 'y']

function! t4.__abstract.x.Validate(value) dict
    if a:value >= 10
        throw "Oops!"
    endif
    return a:value
endfun

Should not throw Exception 'g:t4.__Set("x", 5)', '^Oops!'
Should throw Exception 'g:t4.__Set("x", 20)', '^Oops!'
Should be equal keys(t4.__abstract), ['x', 'y']



It should reinforce the fields' validity.

function! t4.__abstract.y.Validate(value) dict
    if a:value <= 0
        return 0
    elseif a:value >= 10
        return 10
    else
        return a:value
    endif
endfun

Should be equal t4.y, 2

call t4.__Set("y", 5)
Should be equal t4.y, 5

call t4.__Set("y", -10)
Should be equal t4.y, 0

call t4.__Set("y", 20)
Should be equal t4.y, 10



let &cpo = s:save_cpo
unlet s:save_cpo
