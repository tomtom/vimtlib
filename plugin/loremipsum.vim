" loremipsum.vim
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-10.
" @Last Change: 2009-02-15.
" @Revision:    68
" GetLatestVimScripts: 2289 0 loremipsum.vim

if &cp || exists("loaded_loremipsum")
    finish
endif
let loaded_loremipsum = 2

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:loremipsum_paragraph_template')
    " A dictionary of filetypes and paragraph templates (as format 
    " strings for |printf()|).
    " :nodefault:
    " :read: let g:loremipsum_paragraph_template = {} "{{{2
    let g:loremipsum_paragraph_template = {
                \ 'html': '<p>%s</p>',
                \ 'php': '<p>%s</p>',
                \ }
endif

if !exists('g:loremipsum_marker')
    " A dictionary of filetypes and array containing the prefix and the 
    " postfix for the inserted text:
    " [prefix, postfix, no_inline?]
    " :read: let g:loremipsum_marker = {}  "{{{2
    let g:loremipsum_marker = {
                \ 'html': ['<!--lorem-->', '<!--/lorem-->', 0],
                \ 'php': ['<!--lorem-->', '<!--/lorem-->', 0],
                \ 'tex': ['% lorem{{{', '% lorem}}}', 1],
                \ 'viki': ['% lorem{{{', '% lorem}}}', 1],
                \ }
endif

if !exists('g:loremipsum_words')
    " Default length.
    let g:loremipsum_words = 100   "{{{2
endif

if !exists('g:loremipsum_files')
    "                                                 *b:loremipsum_file*
    " If b:loremipsum_file exists, it will be used as source. Otherwise, 
    " g:loremipsum_files[&spelllang] will be checked. As a fallback, 
    " .../autoload/loremipsum.txt will be used.
    let g:loremipsum_files = {}   "{{{2
endif


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

