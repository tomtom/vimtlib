" worksheet.vim Worksheets (Log of interaction with an interpreter)
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2008-07-15.
" @Last Change: 2010-02-22.
" @Revision:    68
" GetLatestVimScripts: 0 0 worksheet.vim

if &cp || exists("loaded_worksheet")
    finish
endif
if !exists('g:loaded_hookcursormoved') || g:loaded_hookcursormoved < 9
    echoerr 'hookcursormoved >= 0.9 is required'
    finish
endif
let loaded_worksheet = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:worksheet_default')
    " The default worksheet type
    let g:worksheet_default = 'vim'   "{{{2
endif

if !exists('g:worksheet_suffix')
    " The suffix for saved worksheets.
    " TODO: If non-empty, this will also add a line to the filetypedetect 
    " autogroup.
    let g:worksheet_suffix = '.wks'   "{{{2
endif
if !empty(g:worksheet_suffix) && exists('tml_vimfiles')
    " exec 'au filetypedetect BufNewFile,BufRead *'. g:worksheet_suffix .' call worksheet#Setfiletype(matchstr(expand("<afile>"), "\\V_\\zs\\.\\{-}\\ze". g:worksheet_suffix ."\\$"))'
    exec 'au filetypedetect BufNewFile,BufRead *'. g:worksheet_suffix .' call worksheet#RestoreBuffer()'
endif

if !exists('g:worksheet_rewrite')
    " let g:worksheet_rewrite = {}   "{{{2
    let g:worksheet_rewrite = {
                \ '^r\(_com\)\?$': [
                \ ['^\s\+??\(.*\)', 'help.search("\1")', ''],
                \ ['^\s\+?\([^?].*\)', 'help("\1")', ''],
                \ ]
                \ }
endif


" :display: :Worksheet [TYPE]
" Open a new worksheet.
command! -narg=* -complete=customlist,worksheet#Complete Worksheet call worksheet#Worksheet(<f-args>)

" Restore a worksheet to the last know good state.
command! WorksheetRestore call worksheet#Restore()

" :WorksheetSaveAs[!] [FILENAME]
" Save a worksheet to disk.
" By default worksheets are 'buftype'=nofile and 'noswapfile'.
command! -bang -narg=? -complete=file WorksheetSaveAs call worksheet#SaveAs("<bang>", <q-args>)

" Evaluate all cells in the current worksheet.
command! WorksheetEvaluateAll call worksheet#EvaluateAll()

" Export the input fields to a file.
command! -narg=? -complete=file WorksheetExport call worksheet#Export(<q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo


finish
CHANGES:
0.1
- Initial release

