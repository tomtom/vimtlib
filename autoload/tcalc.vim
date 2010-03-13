" tcalc.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-10-07.
" @Last Change: 2010-03-13.
" @Revision:    0.0.544

" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


if !exists('g:tcalc_initialize')
    " A string that will be read when first invoking |:TCalc|.
    " Define some abbreviations. Use 'ls' to see them.
    " :nodefault:
    " :read: let g:tcalc_initialize = '' "{{{2
    let g:tcalc_initialize = '
                \ :binom ( n:Numeric k:Numeric ) args n fak k fak n k - fak * / ;
                \ :fak ( Numeric ) args dup 1 > ( dup 1 - fak * ) ( . 1 ) ifelse ;
                \ :fib ( Numeric ) args dup 1 > ( dup 1 - fib swap 2 - fib + ) if ;
                \ :ld ( Numeric ) args log 2 log / ;
                \ :ln ( Numeric ) args log ;
                \ :logx ( number:Numeric base:Numeric ) args number log base log / ;
                \ :rev ( Numeric ) args 1 swap / ;
                \ :Z ( Numeric ) args Integer ;
                \ :Q ( Numeric ) args Rational ;
                \ :C ( Numeric ) args Complex ;
                \ '
    " \ :binom ( Numeric Numeric ) args copy1 fak rot2 dup fak rot2 - fak * / ;
    " \ :logx ( Numeric Numeric ) args swap log swap log / ;
endif

if !exists('g:tcalc_lines')
    " The height of the window. If negative, use fixed height.
    let g:tcalc_lines = 10 "{{{2
endif


if !exists('g:tcalc_dir')
    " The default directory where "source" finds files.
    let g:tcalc_dir = fnamemodify('~/.tcalc', ':p') "{{{2
endif


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

