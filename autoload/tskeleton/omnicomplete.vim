" omnicomplete.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-08-23.
" @Last Change: 2010-02-26.
" @Revision:    0.0.15

let s:save_cpo = &cpo
set cpo&vim


function! tskeleton#omnicomplete#Initialize() "{{{3
endf


function! tskeleton#omnicomplete#FiletypeBits(dict, type) "{{{3
    " TAssert IsDictionary(a:dict)
    " TAssert IsString(a:type)
    call tskeleton#Complete_use_omnifunc('', a:dict)
endf



let &cpo = s:save_cpo
unlet s:save_cpo
