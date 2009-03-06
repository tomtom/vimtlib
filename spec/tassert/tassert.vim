" tassert.vim
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-02-22.
" @Last Change: 2009-03-06.
" @Revision:    34

let s:save_cpo = &cpo
set cpo&vim



SpecBegin 'title': 'TAssert',
            \ 'cleanup': ['Fun1()', 'Fun1type()', 'Fun2()']



function! Fun1(a) "{{{3
    TAssert should#be#Type(a:a, 'string')
endf

function! Fun1type(a) "{{{3
    TAssertType a:a, 'string'
endf

function! Fun2() "{{{3
    TAssert FunTakeTime()
endf

function! FunTakeTime() "{{{3
    echom "Take 2 secs time"
    sleep 2
    return 1
endf

let g:spec_tassert_status = g:TASSERT



TAssertOn

It should evaluate assertions when turned on.
Should throw something 'Fun1(1)'
Should not throw something 'Fun1("foo")'

Should throw#Something('Fun1type(1)')
Should not throw something 'Fun1type("foo")'

Should not finish in 1 second 'Fun2()'



TAssertOff

It should not evaluate assertions when turned off.
Should not throw something 'Fun1(1)'
Should not throw something 'Fun1type(1)'
Should finish in 1 second 'Fun2()'



if g:spec_tassert_status
    TAssertOn
endif



let &cpo = s:save_cpo
unlet s:save_cpo
