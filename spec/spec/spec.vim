" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2009-03-06.

let s:save_cpo = &cpo
set cpo&vim

let s:vars = len(g:)

let g:spec_bar = 1


SpecBegin 'title': 'Self-test',
            \ 'scratch': '%',
            \ 'sfile': 'autoload/spec.vim',
            \ 'before': 'let g:spec_bar = 2',
            \ 'after': 'let g:spec_bar = 1'


It should initialize the environment.
Should be#Equal(spec#Val('s:spec_vars'), keys(g:))
Should be#Equal(spec#Val('s:spec_msg'), 'Self-test')

Should be#Equal(spec#Val('s:should_counts['. string(<SID>CurrentFile()) .']'), 3)

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
Should be#Equal(spec#__Rewrite('finish in 1 second "Fun2()"'), 'should#finish#InSecs("Fun2()", 1)')
Should be#Equal(spec#__Rewrite('not finish in 2 seconds "Fun2()"'), '!should#finish#InSecs("Fun2()", 2)')
Should be#Equal(spec#__Rewrite("throw something '1 + [1]'"), "should#throw#Something('1 + [1]')")
Should be#Equal(spec#__Rewrite("not exists('*SpecFoo')"), "!exists('*SpecFoo')")

" Should be#Equal(spec#__Rewrite('not be equal'), '!should#be#Equal')
Should not be#Equal(spec#__Rewrite('not be#Equal'), 'foo')
Should not be equal(spec#__Rewrite('not be#Equal'), 'foo')
Should not be Equal spec#__Rewrite('not be#Equal'), 'foo'
Should not be equal spec#__Rewrite('not be#Equal'), 'foo'


It should be able to access script-local functions.
Should be#Equal(<SID>CanonicalFilename('a:\foo/bar'), 'A:/foo/bar')


let g:spec_qfl_len = len(getqflist())
It should fail. Please ignore the entry below unless there is no descriptive explanation.
Should be#Equal("fail", "should")
It should integrate with the quickfix list.
Should be#Equal(len(getqflist()), g:spec_qfl_len + 2)


It! should always add this message to the quickfix list.
Should be#Equal(len(getqflist()), g:spec_qfl_len + 3)


It should replay key sequences.
Replay :let g:spec_char1 = getchar()\n\<f11>
Should be#Equal g:spec_char1, "€F1"


It should replay macros.
call spec#Replay(':let g:spec_char2 = getchar()€F1')
Should be#Equal g:spec_char2, "€F1"
unlet g:spec_char2
Replay! :let g:spec_char2 = getchar()€F1
Should be#Equal g:spec_char2, "€F1"


let &cpo = s:save_cpo
unlet s:save_cpo
