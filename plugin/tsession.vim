" tsession.vim
" @Author:      Thomas Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-09-02.
" @Last Change: 2008-12-20.
" @Revision:    0.1.98
" GetLatestVimScripts: 0 1 tsession.vim
"
" TODO:
" - restore tab pages

if &cp || exists("loaded_tsession")
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 12
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 12
        echoerr 'tlib >= 0.12 is required'
        finish
    endif
endif
let loaded_tsession = 1

let s:save_cpo = &cpo
set cpo&vim


" Where to save sessions. By default, the data will be saved in 
" |g:tlib_cache|.'/sessions'.
" If a session name starts with an underscore ("_"), it will be saved in 
" the b:tsession_dir directory -- if defined. Otherwise the global/cache 
" directory will be used.
" Global or buffer local.
TLet g:tsession_dir = ''

" The suffix for sessions files.
" Currently, it's only function is to prevent name clashes with regular 
" files.
TLet g:tsession_suffix = '.tsess'

" The global options to store with session data.
TLet g:tsession_save_global = ['&co', '&lines', '&go', '&fdc', '&fdl', '&fen', '&guiheadroom']

" A list of expressions that create commands to restore other global settings.
TLet g:tsession_save_global_extra = [
            \ "'winpos '. getwinposx() .' '. getwinposy()",
            \ ]

" The buffer-local options to store with session data.
TLet g:tsession_save_buf = []
" TLet g:tsession_save_buf = ['&fdc', '&fdl']

" A list of expressions that create commands to restore other 
" buffer-local settings.
TLet g:tsession_save_buf_extra = []

" The window-local options to store with session data.
TLet g:tsession_save_win = ['&fdc', '&fdl', '&fen', '&scb']

" A list of expressions that create commands to restore other 
" window-local settings.
TLet g:tsession_save_win_extra = []

TLet g:tsession_current = 'vim'

TLet g:tsession_register_special = {'buftype': '', 'unlisted': 0, 'unloaded': 0}

" When loading a session, hide buffers not in the current session.
TLet g:tsession_swap = 0
" TLet g:tsession_swap = 1

TLet g:tsession_world = {
                \ 'type': 's',
                \ 'key_handlers': [
                \     {'key':  4, 'agent': 'tsession#AgentDeleteSession', 'key_name': '<c-d>', 'help': 'Delete session'},
                \     {'key': 14, 'agent': 'tsession#AgentNewSession',    'key_name': '<c-n>', 'help': 'New session'},
                \     {'key': 19, 'agent': 'tsession#AgentSaveSession',   'key_name': '<c-s>', 'help': 'Save session'},
                \ ],
                \ 'allow_suspend': 0,
                \ 'query': 'Select session',
                \ }


function! s:SessionComplete(ArgLead, CmdLine, CursorPos) "{{{3
    return filter(tsession#Sessions(), 'v:val =~ "^". a:ArgLead')
endf


function! s:Swap(bang) "{{{3
    return g:tsession_swap ? empty(a:bang) : !empty(a:bang)
endf


" :display: TSessionSave [SESSION]
" See also |tsession#Save|.
" EXAMPLES: >
"   TSessionSave example
command! -bang -nargs=? -bar -complete=customlist,s:SessionComplete
            \ TSessionSave call tsession#Save(<q-args>)

" :display: TSessionLoad[!] [SESSION]
" With !, buffers not registered in the session will be deleted if 
" |g:tsession_swap| is false. If g:tsession_swap is true, the meaning of 
" ! is inverted.
" See also |tsession#Load|.
" EXAMPLES: >
"   TSessionLoad example
command! -bang -nargs=? -bar -complete=customlist,s:SessionComplete
            \ TSessionLoad call tsession#Load(<q-args>, {'swap': s:Swap('<bang>')})

" :display: TSession[!]
" With !, buffers not registered in the session will be deleted if 
" |g:tsession_swap| is false. If g:tsession_swap is true, the meaning of 
" ! is inverted.
" See also |tsession#Browse|.
command! -bang -bar TSession
            \ call tsession#Browse({'swap': s:Swap('<bang>')})


let &cpo = s:save_cpo
unlet s:save_cpo
