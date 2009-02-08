" livetimestamp.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=vim-livetimestamp)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     03-Dez-2005.
" @Last Change: 2007-08-27.
" @Revision:    0.11

if &cp || exists("loaded_livetimestamp")
    finish
endif
let loaded_livetimestamp = 1

let s:livetimestamp = 0
let s:livetimeinit  = 0

fun! LiveTimeStamp(...)
    if a:0 >= 1
        if a:1
            let s:livetimestamp = 1
            if !exists('b:livetimestamp') || !b:livetimestamp
                let b:livetimestamp = 1
                if !s:livetimeinit
                    " exec 'autocmd CursorHold '. escape(expand('%:p'), ' \') .' call LiveTimeStamp()'
                    autocmd CursorHold * call LiveTimeStamp()
                endif
            endif
        else
            let s:livetimestamp = 0
            let b:livetimestamp = 0
        end
    end
    if s:livetimestamp
        exec "norm! Go% ". strftime("%Y-%m-%d %H:%M:%S")
        exec "norm! Go"
    end
endf

command! -narg=? LiveTimeStamp call LiveTimeStamp(<f-args>)


