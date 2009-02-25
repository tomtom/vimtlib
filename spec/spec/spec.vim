" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2009-02-25.

let s:save_cpo = &cpo
set cpo&vim

let s:vars = len(g:)

unlet! g:spec_foo
let g:spec_bar = 1


SpecBegin 'title': 'Self-test',
            \ 'sfile': 'autoload/spec.vim',
            \ 'before': 'let g:spec_bar = 2',
            \ 'after': 'let g:spec_bar = 1'


It should initialize the environment.
Should be#Equal(spec#Val('s:spec_vars'), keys(g:))
Should be#Equal(spec#Val('s:spec_msg'), 'Self-test')

Should be#Equal(spec#Val('s:should_counts'), 3)

Should be#Dictionary(spec#Val('s:spec_args'))
Should be#NotEmpty(spec#Val('s:spec_args'))

Should be#List(spec#Val('s:scripts'))
Should be#NotEmpty(spec#Val('s:scripts'))


It should execute before & after ex commands.
Should be#Equal(g:spec_bar, 2)
if g:spec_bar != 1
    throw 'Teardown failed'
endif


It should remember comments.
Should be#Equal(spec#Val('s:spec_comment'), 'It should remember comments.')
Should !be#Equal(spec#Val('s:spec_comment'), 'Foo')
Should be#NotEmpty(spec#Val('s:spec_comment'))


It should rewrite expressions.
Should be#Equal(spec#__Rewrite('not be#Equal'), '!should#be#Equal')
" Should be#Equal(spec#__Rewrite('not be equal'), '!should#be#Equal')
Should not be#Equal(spec#__Rewrite('not be#Equal'), 'foo')
Should not be equal(spec#__Rewrite('not be#Equal'), 'foo')
Should not be Equal spec#__Rewrite('not be#Equal'), 'foo'
Should not be equal spec#__Rewrite('not be#Equal'), 'foo'
Should throw something '1 + [1]'
Should not throw something '1 + 2'


It should remove temporary global variables & functions when done.
let g:spec_foo = 1

function! SpecFoo(a) "{{{3
    return a:a * 2
endf


It should be able to access script-local functions.
Should be#Equal(<SID>CanonicalFilename('a:\foo/bar'), 'A:/foo/bar')


It should integrate with the quickfix list.
let g:spec_qfl_len = len(getqflist())
It should fail.
Should be#Equal("fail", "should")
" incease with 2 because of the "it should" comment.
Should be#Equal(len(getqflist()), g:spec_qfl_len + 2)


SpecEnd SpecFoo()


if exists('*SpecFoo')
    throw "SpecFoo() wasn't removed"
endif

if exists('g:spec_foo')
    throw "Global variable wasn't removed"
endif


let &cpo = s:save_cpo
unlet s:save_cpo
