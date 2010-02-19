" worksheet.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-16.
" @Last Change: 2010-02-19.
" @Revision:    0.1.54
" GetLatestVimScripts: 0 0 :AutoInstall: worksheet.vim

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

call hookcursormoved#Register("linechange", "worksheet#SetModifiable")

setlocal commentstring=%%\ %s
setlocal comments=fb:-,fb:+,fb:*,fb:#,fb:?,fb:@,:%

" :doc:
" Maps:~

" :tagprefix worksheet-map-:
" Undo
noremap <buffer> <silent> u :setlocal modifiable<cr>u

" Insert new entry below
noremap <buffer> <silent> <c-n> :call b:worksheet.NewEntry(1)<cr>
" Insert new entry above
noremap <buffer> <silent> <c-p> :call b:worksheet.NewEntry(-1)<cr>

" Goto next input field
noremap <buffer> <silent> <c-pagedown> :call b:worksheet.NextInputField(1, 0, 1)<cr>
inoremap <buffer> <silent> <c-pagedown> <c-o>:call b:worksheet.NextInputField(1, 0, 1)<cr>
" Goto previous input field
noremap <buffer> <silent> <c-pageup> :call b:worksheet.NextInputField(-1, 0, 1)<cr>
inoremap <buffer> <silent> <c-pageup> <c-o>:call b:worksheet.NextInputField(-1, 0, 1)<cr>

" Swap with next entry
noremap <buffer> <silent> <m-pagedown> :call b:worksheet.SwapEntries(1)<cr>
inoremap <buffer> <silent> <m-pagedown> <c-o>:call b:worksheet.SwapEntries(1)<cr>
" Swap with previous entry
noremap <buffer> <silent> <m-pageup> :call b:worksheet.SwapEntries(-1)<cr>
inoremap <buffer> <silent> <m-pageup> <c-o>:call b:worksheet.SwapEntries(-1)<cr>

" Submit the input to the interpreter
noremap <buffer> <c-cr> :call b:worksheet.Submit()\|call b:worksheet.NextInputField(1, 1, 0)<cr>
" Submit the input to the interpreter
inoremap <buffer> <c-cr> <c-o>:call b:worksheet.Submit()\|call b:worksheet.NextInputField(1, 1, 0)<cr>

" Go to entry |v:count|
noremap <buffer> <silent> gi :call b:worksheet.GotoEntry(v:count1, 1, 0)\|:exec b:worksheet.EndOfInput()<cr>

noremap <buffer> <silent> K :call b:worksheet.Keyword()<cr>

" Yank the input of the current or |v:count|'s entry to |quotequote|.
noremap <buffer> <silent> yc :call b:worksheet.Yank(v:count, 'string')<cr>
" Yank the output of the current or |v:count|'s entry to |quotequote|.
noremap <buffer> <silent> yo :call b:worksheet.Yank(v:count, 'output')<cr>
" Yank all input fields.
noremap <buffer> <silent> yin :call b:worksheet.YankAll()<cr>
" :tagprefix:

