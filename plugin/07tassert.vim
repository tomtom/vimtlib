" tAssert.vim
" @Author:      Tom Link (micathom AT gmail com?subject=vim-tAssert)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2006-12-12.
" @Last Change: 2009-02-21.
" @Revision:    760
"
" GetLatestVimScripts: 1730 1 07tAssert.vim


if &cp || exists("loaded_tassert")
    if !(!exists("s:assert") || g:TASSERT != s:assert)
        finish
    endif
endif
let loaded_tassert = 100


if !exists('g:TASSERT')    | let g:TASSERT = 0    | endif
if !exists('g:TASSERTLOG') | let g:TASSERTLOG = 1 | endif

if !exists('g:tassert_cwindow')
    " The command that should be used for viewing the quickfix list.
    let g:tassert_cwindow = 'cwindow'   "{{{2
endif

if exists('s:assert')
    echo 'TAssertions are '. (g:TASSERT ? 'on' : 'off')
endif
let s:assert = g:TASSERT


if g:TASSERT

    if exists(':TLogOn') && empty(g:TLOG)
        TLogOn
    endif

    " :display: TAssert[!] {expr}
    " Test that an expression doesn't evaluate to something |empty()|. 
    " If used after a |:TAssertBegin| command, any occurrences of 
    " "<SID>" in the expression is replaced with the current script's 
    " |<SNR>|. With [!] failures are logged according to the setting of 
    " |g:tAssertLog|.
    command! -nargs=1 -bang TAssert 
                \ let s:assertReason = '' |
                \ call tassert#__Setup() |
                \ try |
                \   let s:assertFailed = empty(eval(tassert#__ResolveSIDs(<q-args>))) |
                \ catch |
                \   let s:assertReason = v:exception |
                \   let s:assertFailed = 1 |
                \ endtry |
                \ call tassert#__Teardown() |
                \ if s:assertFailed |
                \   call should#__InsertReason(<q-args>) |
                \   if !empty(s:assertReason) | call should#__InsertReason(s:assertReason) | endif |
                \   let s:assertReasons = should#__ClearReasons() |
                \   if exists('s:tassert_run') |
                \     call tassert#AddQFL(<q-args>, s:assertReasons) |
                \   elseif "<bang>" != '' |
                \     call tlog#Log(s:assertReasons) |
                \   else |
                \     throw substitute(s:assertReasons, '^Vim.\{-}:', '', '') |
                \   endif |
                \ endif

    " :display: TAssertRun [PATH]
    " Run all vim files in PATH as unit tests. If no PATH is given, run 
    " the current file only.
    "
    " CAVEAT: Unit test scripts must not run other unit tests by 
    " sourcing them. In order for tassert to map the |:TAssert| commands 
    " onto the correct file & line number scripts containing assertions 
    " have to be run via :TAssertRun.
    "
    " NOTE: Integration with the quickfix list requires tlib 
    " (vimscript#1863) to be installed.
    "
    " Even then it sometimes happens that tassert cannot distinguish 
    " between to identical tests in different contexts, which is why you 
    " should only use one |:TAssertBegin| command per file.
    command! -nargs=? -bang TAssertRun  runtime macros/tassert.vim
                \ | let s:tassert_run = 1 
                \ | call tassert#__Run(<q-args>, expand('%:p'))
                \ | unlet s:tassert_run

else

    " :nodoc:
    command! -nargs=* -bang TAssert :
    " :nodoc:
    command! -nargs=* -bang TAssertRun  :

endif


if !exists(':TAssertOn')

    " Switch assertions on and reload the plugin.
    command! -bar TAssertOn let g:TASSERT = 1 | runtime plugin/07tassert.vim
    " Switch assertions off and reload the plugin.
    command! -bar TAssertOff let g:TASSERT = 0 | runtime plugin/07tassert.vim

    " Comment TAssert* commands and all lines between a TAssertBegin 
    " and a TAssertEnd command.
    command! -range=% -bar -bang TAssertComment call tassert#Comment(<line1>, <line2>, "<bang>")
    " Uncomment TAssert* commands and all lines between a TAssertBegin 
    " and a TAssertEnd command.
    command! -range=% -bar -bang TAssertUncomment call tassert#Uncomment(<line1>, <line2>, "<bang>")

    " Put the line "exec TAssertInit()" into your script in order to 
    " install the function s:TAssertVal(), which can be used to evaluate 
    " expressions in the script context. This initializations is 
    " necessary only if you call the function |tassert#Val()| in your 
    " tests.
    fun! TAssertInit()
        return "function! s:TAssertVal(expr)\nreturn eval(a:expr)\nendf"
    endf

end


finish
CHANGE LOG {{{1

0.1: Initial release

0.2
- More convenience functions
- The convenience functions now display an explanation for a failure
- Convenience commands weren't loaded when g:TASSERT was off.
- Logging to a file & via Decho()
- TAssert! (the one with the bang) doesn't throw an error but simply 
displays the failure in the log
- s:ResolveSIDs() didn't return a string if s:assertFile wasn't set.
- s:ResolveSIDs() caches scriptnames
- Moved logging code to 00tLog.vim

0.3
- IsA(): Can take a list of types as arguments and it provides a way to 
check dictionaries against prototypes or interface definitions.
- IsExistent()
- New log-related commands: TLogOn, TLogOff, TLogBufferOn, TLogBufferOff
- Use TAssertVal(script, expr) to evaluate an expression (as 
argument to a command) in the script context.
- TAssertOn implies TLogOn
- *Comment & *Uncomment commands now take a range as argument (default: 
whole file).
- TAssertComment! & TAssertUncomment! (with [!]) also call 
TLog(Un)Comment.

0.4
- TLogVAR: take a comma-separated variable list as argument; display a 
time-stamp (if +reltime); show only the g:tlogBacktrace'th last items of 
the backtrace.

1.0
- Incompatible changes galore
- Removed :TAssertToggle
- Moved :TAssertBegin & :TAssertEnd to macros/tassert.vim


TODO:
- Line number? Integration with the quickfix list.
- Interactive assertions (buffer input, expected vs observed): 
compare#BufferWithFile() or should#result_in#BufferWithFile()
- Support for Autoloading, AsNeeded ...

