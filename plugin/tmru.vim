" tmru.vim -- Most Recently Used Files
" @Author:      Tom Link (micathom AT gmail com?subject=vim-tlib-mru)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-13.
" @Last Change: 2010-01-03.
" @Revision:    277
" GetLatestVimScripts: 1864 1 tmru.vim

if &cp || exists("loaded_tmru")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 28
    echoerr "tlib >= 0.28 is required"
    finish
endif
let loaded_tmru = 8

if !exists("g:tmruSize")
    " The number of recently edited files that are registered.
    let g:tmruSize = 50 "{{{2
endif
if !exists("g:tmruMenu")
    " The menu's prefix. If the value is "", the menu will be disabled.
    let g:tmruMenu = 'File.M&RU.' "{{{2
endif
if !exists("g:tmruMenuSize")
    " The number of recently edited files that are displayed in the 
    " menu.
    let g:tmruMenuSize = 20 "{{{2
endif
if !exists("g:tmruEvents")
    " A comma-separated list of events that trigger buffer registration.
    let g:tmruEvents = 'BufWritePost,BufReadPost' "{{{2
endif
if !exists("g:tmru_file")
    if stridx(&viminfo, '!') == -1
        " Where to save the file list. The default value is only 
        " effective, if 'viminfo' doesn't contain '!' -- in which case 
        " the 'viminfo' will be used.
        let g:tmru_file = tlib#cache#Filename('tmru', 'files', 1) "{{{2
    else
        let g:tmru_file = ''
    endif
endif

" Don't change the value of this variable.
if !exists("g:TMRU")
    if empty(g:tmru_file)
        let g:TMRU = ''
    else
        let g:TMRU = get(tlib#cache#Get(g:tmru_file), 'tmru', '')
    endif
endif

if !exists("g:tmruExclude") "{{{2
    " Ignore files matching this regexp.
    " :read: let g:tmruExclude = '/te\?mp/\|vim.\{-}/\(doc\|cache\)/\|__.\{-}__$' "{{{2
    let g:tmruExclude = '/te\?mp/\|vim.\{-}/\(doc\|cache\)/\|__.\{-}__$\|'.
                \ substitute(escape(&suffixes, '~.*$^'), ',', '$\\|', 'g') .'$'
endif

if !exists("g:tmru_ignorecase")
    " If true, ignore case when comparing filenames.
    let g:tmru_ignorecase = !has('fname_case') "{{{2
endif

if !exists('g:tmru_world') "{{{2
    let g:tmru_world = {
                \ 'type': 'm',
                \ 'key_handlers': [
                \ {'key': 3,  'agent': 'tlib#agent#CopyItems',        'key_name': '<c-c>', 'help': 'Copy file name(s)'},
                \ {'key': 9,  'agent': 'tlib#agent#ShowInfo',         'key_name': '<c-i>', 'help': 'Show info'},
                \ {'key': 19, 'agent': 'tlib#agent#EditFileInSplit',  'key_name': '<c-s>', 'help': 'Edit files (split)'},
                \ {'key': 22, 'agent': 'tlib#agent#EditFileInVSplit', 'key_name': '<c-v>', 'help': 'Edit files (vertical split)'},
                \ {'key': 20, 'agent': 'tlib#agent#EditFileInTab',    'key_name': '<c-t>', 'help': 'Edit files (new tab)'},
                \ {'key': 23, 'agent': 'tlib#agent#ViewFile',         'key_name': '<c-w>', 'help': 'View file in window'},
                \ ],
                \ 'allow_suspend': 0,
                \ 'query': 'Select file',
                \ }
                " \ 'filter_format': 'fnamemodify(%s, ":t")',
endif


function! s:BuildMenu(initial) "{{{3
    if !empty(g:tmruMenu)
        if !a:initial
            silent! exec 'aunmenu '. g:tmruMenu
        endif
        let es = s:MruRetrieve()
        if g:tmruMenuSize > 0 && len(es) > g:tmruMenuSize
            let es = es[0 : g:tmruMenuSize - 1]
        endif
        for e in es
            let me = escape(e, '.\ ')
            exec 'amenu '. g:tmruMenu . me .' :call <SID>Edit('. string(e) .')<cr>'
        endfor
    endif
endf

function! s:MruRetrieve()
    return split(g:TMRU, '\n')
endf

function! s:MruStore(mru)
    let g:TMRU = join(a:mru, "\n")
    " TLogVAR g:TMRU
    " call TLogDBG(g:tmru_file)
    call s:BuildMenu(0)
    call tlib#cache#Save(g:tmru_file, {'tmru': g:TMRU})
endf

function! s:MruRegister(fname)
    " TLogVAR a:fname
    if g:tmruExclude != '' && a:fname =~ g:tmruExclude
        return
    endif
    if exists('b:tmruExclude') && b:tmruExclude
        return
    endif
    let tmru = s:MruRetrieve()
    let imru = index(tmru, a:fname, 0, g:tmru_ignorecase)
    if imru == -1 && len(tmru) >= g:tmruSize
        let imru = g:tmruSize - 1
    endif
    if imru != -1
        call remove(tmru, imru)
    endif
    call insert(tmru, a:fname)
    call s:MruStore(tmru)
endf

function! s:SNR()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
endf

" Return 0 if the file isn't readable/doesn't exist.
" Otherwise return 1.
function! s:Edit(filename) "{{{3
    if a:filename == expand('%:p')
        return 1
    else
        let bn = bufnr(a:filename)
        " TLogVAR bn
        if bn != -1 && buflisted(bn)
            exec 'buffer '. bn
            return 1
        elseif filereadable(a:filename)
            try
                let file = tlib#arg#Ex(a:filename)
                " TLogVAR file
                exec 'edit '. file
            catch
                echohl error
                echom v:errmsg
                echohl NONE
            endtry
            return 1
        else
            echom "TMRU: File not readable: ". a:filename
        endif
    endif
    return 0
endf

function! s:SelectMRU()
    " TLogDBG "SelectMRU#1"
    let tmru  = s:MruRetrieve()
    " TLogDBG "SelectMRU#2"
    " TLogVAR tmru
    let world = tlib#World#New(g:tmru_world)
    call world.Set_display_format('filename')
    " TLogDBG "SelectMRU#3"
    let world.base = copy(tmru)
    " TLogDBG "SelectMRU#4"
    " let bs    = tlib#input#List('m', 'Select file', copy(tmru), g:tmru_handlers)
    let bs    = tlib#input#ListW(world)
    " TLogDBG "SelectMRU#5"
    " TLogVAR bs
    if !empty(bs)
        for bf in bs
            " TLogVAR bf
            if !s:Edit(bf)
                let bi = index(tmru, bf)
                " TLogVAR bi
                call remove(tmru, bi)
                call s:MruStore(tmru)
            endif
        endfor
        return 1
    endif
    return 0
endf

function! s:EditMRU()
    let tmru = s:MruRetrieve()
    let tmru1 = tlib#input#EditList('Edit MRU', tmru)
    if tmru != tmru1
        call s:MruStore(tmru)
    endif
endf

function! s:AutoMRU(filename) "{{{3
    " if &buftype !~ 'nofile' && fnamemodify(a:filename, ":t") != '' && filereadable(fnamemodify(a:filename, ":t"))
    if &buflisted && &buftype !~ 'nofile' && fnamemodify(a:filename, ":t") != ''
        call s:MruRegister(a:filename)
    endif
endf


augroup tmru
    au!
    au VimEnter * call s:BuildMenu(1)
    exec 'au '. g:tmruEvents .' * call s:AutoMRU(expand("<afile>:p"))'
augroup END

" Display the MRU list.
command! TRecentlyUsedFiles call s:SelectMRU()

" Edit the MRU list.
command! TRecentlyUsedFilesEdit call s:EditMRU()


finish


CHANGES:
0.1
Initial release

0.2
- :TRecentlyUsedFilesEdit
- Don't register nofile buffers or buffers with no filename.
- <c-c> copy file name(s) (to @*)
- When !has('fname_case'), ignore case when checking if a filename is 
already registered.

0.3
- Autocmds use expand('%') instead of expand('<afile>')
- Build menu (if the prefix g:tmruMenu isn't empty)
- Key shortcuts to open files in (vertically) split windows or tabs
- Require tlib >= 0.9

0.4
- <c-w> ... View file in original window
- <c-i> ... Show file info
- Require tlib >= 0.13

0.5
- Don't escape backslashes for :edit

0.6
- g:tmruEvents can be configured (eg. BufEnter)
- Require tlib 0.28

0.7
- If viminfo doesn't include '!', then use tlib to save the file list.

0.8
- s:EditMRU(): Save tmru list only if it was changed.

