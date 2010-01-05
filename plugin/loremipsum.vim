" loremipsum.vim
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-10.
" @Last Change: 2010-01-03.
" @Revision:    71
" GetLatestVimScripts: 2289 0 loremipsum.vim

if &cp || exists("loaded_loremipsum")
    finish
endif
let loaded_loremipsum = 3

let s:save_cpo = &cpo
set cpo&vim


" :display: :Loremipsum[!] [COUNT] [PARAGRAPH_TEMPLATE] [PREFIX POSTFIX]
" With [!], insert the text "inline", don't apply paragraph templates.
" If the PARAGRAPH_TEMPLATE is *, use the default template from 
" |g:loremipsum_paragraph_template| (in case you want to change 
" PREFIX and POSTFIX). If it is _, use no paragraph template.
" If PREFIX is _, don't use markers.
command! -bang -nargs=* Loremipsum call loremipsum#Insert("<bang>", <f-args>)

" Replace loremipsum text with something else. Or simply remove it.
" :display: :Loreplace [REPLACEMENT] [PREFIX POSTFIX]
command! -nargs=* Loreplace call loremipsum#Replace(<f-args>)


let &cpo = s:save_cpo
unlet s:save_cpo


finish
CHANGES:
0.1
- Initial release

0.2
- Loremipsum!: With !, insert inline (single paragraph)
- If the template argument is *, don't apply the default paragraph 
template.
- Loreplace: Replace loremipsum text with something else (provided a 
marker was defined for the current filetype)
- g:loremipsum_file, b:loremipsum_file

0.3
- Moved the definition of some variables from plugin/loremipsum.vim to 
autoload/loremipsum.vim

