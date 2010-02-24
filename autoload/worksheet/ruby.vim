" ruby.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-15.
" @Last Change: 2010-02-22.
" @Revision:    0.0.59

if &cp || !has('ruby')
    throw "No +ruby support."
    finish
endif
let s:save_cpo = &cpo
set cpo&vim


let s:prototype = {'syntax': 'ruby'}


function! s:prototype.Evaluate(lines) dict "{{{3
    let ruby = join(a:lines, "\n")
    let value = ''
    let out = ''
    redir => out
    silent ruby <<EOR
    value = eval(VIM.evaluate('ruby'))
    VIM.command(%{let value=#{value.inspect.inspect}})
EOR
    redir END
    if !empty(out)
        let value = join([out, '=> '. value], "\n")
    endif
    return value
endf


function! worksheet#ruby#InitializeInterpreter(worksheet) "{{{3
endf


function! worksheet#ruby#InitializeBuffer(worksheet) "{{{3
    call extend(a:worksheet, s:prototype)
    ruby require 'stringio'
    runtime indent/ruby.vim
    runtime ftplugin/ruby.vim
endf


let &cpo = s:save_cpo
unlet s:save_cpo
