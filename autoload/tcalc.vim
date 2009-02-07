" tcalc.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-10-07.
" @Last Change: 2007-11-29.
" @Revision:    0.0.538

if &cp || exists("loaded_tcalc_autoload")
    finish
endif
let loaded_tcalc_autoload = 1


function! tcalc#Calculator(reset, initial_args) "{{{3
    " if a:full_screen
    "     edit __TCalc__
    " else
        split __TCalc__
    " end
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nobuflisted
    setlocal modifiable
    setlocal foldmethod=manual
    setlocal foldcolumn=0
    setlocal filetype=
    setlocal nowrap
    if g:tcalc_lines < 0
        exec 'resize '. (-g:tcalc_lines)
    endif
    if a:reset
        ruby TCalc::VIM.reset
    end
    ruby TCalc::VIM.repl(VIM::evaluate('a:initial_args'))
    call s:CloseDisplay()
    echo
endf


function! tcalc#Eval(initial_args) "{{{3
    ruby TCalc::VIM.evaluate(VIM::evaluate('a:initial_args'))
    echo
endf


function! s:CloseDisplay() "{{{3
    if winnr('$') == 1
        bdelete!
    else
        wincmd c
    endif
endf


function! s:PrintArray(lines, reversed, align) "{{{3
    norm! ggdG
    let arr = split(a:lines, '\n', 1)
    if !a:reversed
        let arr = reverse(arr)
    end
    let ilen = len(arr)
    let imax = len(ilen)
    let lines = map(range(ilen), 'printf("%0'. imax .'s: %s", ilen - v:val - 1, arr[v:val])')
    call append(0, lines)
    norm! Gdd
    if winnr('$') > 1 && g:tcalc_lines >= 0
        if a:align && g:tcalc_lines > 0
            let rs = min([g:tcalc_lines, ilen])
        else
            let rs = min([&lines, ilen])
        endif
        exec 'resize '. rs
    endif
    " let top = ilen - (g:tcalc_lines >= 0 ? g:tcalc_lines : &lines)
    norm! Gzb
    echo
    redraw
endf


function! s:DisplayStack(stack_lines) "{{{3
    return s:PrintArray(a:stack_lines, 1, 1)
endf


function! tcalc#Complete(ArgLead, CmdLine, CursorPos) "{{{3
    ruby <<EOR
    ids = TCalc::VIM.completion(VIM::evaluate('a:ArgLead'))
    VIM::command("return split(#{ids.join("\n").inspect}, '\n')")
EOR
endf


exec 'rubyfile '. expand('<sfile>:p:h:h') .'/ruby/tcalc.rb'

