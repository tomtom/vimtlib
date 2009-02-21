" tLog.vim
" @Author:      Tom Link (micathom AT gmail com?subject=vim-tLog)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2006-12-15.
" @Last Change: 2009-02-21.
" @Revision:    0.3.153

if &cp || exists('loaded_tlog')
    finish
endif
let loaded_tlog = 100


" One of: echo, echom, file, Decho
" Format: type:args
" E.g. file:/tmp/foo.log
if !exists('g:tlogDefault')   | let g:tlogDefault = 'echom'   | endif
if !exists('g:TLOG')          | let g:TLOG = g:tlogDefault    | endif
if !exists('g:tlogBacktrace') | let g:tlogBacktrace = 2       | endif


command! -nargs=+ TLog call tlog#Log(<args>)
command! -nargs=* -bar TLogTODO call tlog#Debug(expand('<sfile>').': Not yet implemented '. <q-args>)
command! -nargs=1 TLogDBG call tlog#Debug(expand('<sfile>').': '. <args>)
command! -nargs=+ TLogStyle call tlog#Style(<args>)
command! -nargs=+ TLogVAR call tlog#Var(expand('<sfile>'), <q-args>, <args>)
" command! -nargs=+ TLogVAR if !TLogVAR(expand('<sfile>').': ', <q-args>, <f-args>) | call tlog#Debug(expand('<sfile>').': Var doesn''t exist: '. <q-args>) | endif

command! -bar -nargs=? TLogOn let g:TLOG = empty(<q-args>) ? g:tlogDefault : <q-args>
command! -bar -nargs=? TLogOff let g:TLOG = ''
command! -bar -nargs=? TLogBufferOn let b:TLOG = empty(<q-args>) ? g:tlogDefault : <q-args>
command! -bar -nargs=? TLogBufferOff let b:TLOG = ''

command! -range=% -bar TLogComment call tlog#Comment(<line1>, <line2>)
command! -range=% -bar TLogUncomment call tlog#Uncomment(<line1>, <line2>)


finish

CHANGE LOG {{{1
see 07tAssert.vim

