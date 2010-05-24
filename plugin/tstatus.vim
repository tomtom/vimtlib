" tStatus.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim-tStatus)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-02.
" @Last Change: 2010-04-18.
" @Revision:    0.1.24

if &cp || exists("loaded_tstatus")
    finish
endif
let loaded_tstatus = 1

if exists('*TOptionsSummary')
    " TOptionsSummary is loaded by
    "     runtime macros/toptions.vim
    " in your vimrc file if you want to make use of it.
    let g:tstatusline1='%1*[%{winnr()}:%02n]%* %2t %(%M%R%H%W%k%) %=%{TOptionsSummary()} %3*<%l,%c%V,%p%%>%*'
else
    let g:tstatusline1='%1*[%{winnr()}:%02n]%* %2t %(%M%R%H%W%k%) %=%3*<%l,%c%V,%p%%>%*'
endif
let g:tstatusline0='%1*[%{winnr()}:%02n]%* %2t %(%M%R%H%W%k%) %=%3*<%l,%c%V,%p%%>%*'

" let g:trulerformat1='%-010.25(%Y%M%R %lx%c%V %P%)'
" let g:trulerformat1='%-010.25(%M%R %lx%c%V %P%)'
" let g:trulerformat1='%-010.25(B%n%R%M%W %lx%c%V %P%)'
let g:trulerformat1='%-010.25(%lx%c%V %P%R%M%W%)'
let g:trulerformat0=&rulerformat
" set rulerformat=%60(%=%{TmlStatusline('%H:%M')}\ %3*<%l,%c%V,%p%%>%*%)

command! -bang TStatus let statussel=empty("<bang>")
            \ | let &statusline  = g:tstatusline{statussel}
            \ | let &rulerformat = g:trulerformat{statussel}
            \ | unlet statussel


augroup TStatus
    autocmd!
    autocmd VimEnter * TStatus
augroup END

