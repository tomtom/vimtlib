" linglang.vim  Perform actions on basis of the current line's language
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-11.
" @Last Change: 2010-01-05.
" @Revision:    69
" GetLatestVimScripts: 2292 0 linglang.vim

if &cp || exists("loaded_linglang")
    finish
endif
if !exists('g:loaded_hookcursormoved') || g:loaded_hookcursormoved < 8
    echoerr 'hookcursormoved >= 0.8 is required'
    finish
endif
let loaded_linglang = 2

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:linglang_actions')
    " Actions to be executed when switching languages.
    " :nodefault:
    " :read: let g:linglang_actions = {}   "{{{2
    let g:linglang_actions = {
                \ 'de': 'setlocal spelllang=de',
                \ 'en': 'setlocal spelllang=en',
                \ }
endif


" :display: :Linglang[!] [LANGS ...]
" Toggle linglang support for the current buffer.
" With [!], suppress message.
command! -bang -nargs=* Linglang call linglang#Linglang(empty('<bang>'), <f-args>)


let &cpo = s:save_cpo
unlet s:save_cpo


finish
CHANGES:
0.1
- Initial release

0.2
- Language patterns are stored in .../autoload/linglang/LANGUAGE.ENCODING
- Respect encoding
- Removed g:linglang_words, g:linglang_patterns
- Removed g:linglang_filetypes
