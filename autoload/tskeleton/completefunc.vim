" completefunc.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-08-23.
" @Last Change: 2009-08-23.
" @Revision:    0.0.11

let s:save_cpo = &cpo
set cpo&vim


function! tskeleton#completefunc#Initialize() "{{{3
endf


function! tskeleton#completefunc#FiletypeBits(dict, type) "{{{3
    " TAssert IsDictionary(a:dict)
    " TAssert IsString(a:type)
    if !empty(&completefunc)
        " TLogDBG 'use_completefunc'
        for w in tskeleton#GetCompletions(&completefunc, '')
            let [cname, mname] = tskeleton#PurifyBit(w)
            let a:dict[cname] = {'text': w, 'menu': 'CompleteFunc.'. mname, 'type': 'tskeleton'}
        endfor
    endif
endf



let &cpo = s:save_cpo
unlet s:save_cpo
