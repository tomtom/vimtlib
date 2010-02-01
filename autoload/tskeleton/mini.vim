" mini.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-09-15.
" @Last Change: 2010-01-31.
" @Revision:    0.0.15

if &cp || exists("loaded_tskeleton_mini_autoload") "{{{2
    finish
endif
let loaded_tskeleton_mini_autoload = 1


function! tskeleton#mini#Initialize() "{{{3
endf


function! tskeleton#mini#FiletypeBits(dict, type) "{{{3
    " TLogVAR a:dict, a:type
    " call tskeleton#FetchMiniBits(a:dict, expand('%:p:h') .'/.tskelmini', 1)
    let files = findfile('.tskelmini', expand('%:p:h') .';', -1)
    " TLogVAR files
    for file in reverse(files)
        " TLogVAR file
        call tskeleton#FetchMiniBits(a:dict, file, 1)
    endfor
endf


