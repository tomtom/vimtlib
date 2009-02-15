" tselectfile.vim -- A simplicistic files selector/browser (sort of)
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-16.
" @Last Change: 2009-02-15.
" @Revision:    605
" GetLatestVimScripts: 1865 1 tselectfiles.vim

if &cp || exists("loaded_tselectfile")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 29
    echoerr "tlib >= 0.29 is required"
    finish
endif
let loaded_tselectfile = 10

" Whether to cache directory listings (in memory). (per buffer, global)
" If 0, disable the use of cached file listings all together.
TLet g:tselectfiles_use_cache = 1

" Don't use the cache for directories matching this rx. (per buffer, 
" global)
TLet g:tselectfiles_no_cache_rx = ''

" Retain only files matching this regexp. (per window, per buffer, global)
" Regexp |magic| must match the setting of |g:tlib_inputlist_match|.
" Check: :echo tlib#Filter_{g:tlib_inputlist_match}#New().FilterRxPrefix()
TLet g:tselectfiles_filter_rx = ''

" In |tselectfiles#BaseFilter()|, rewrite name parts according to these 
" rules.
TLet g:tselectfiles_part_subst = {}
" Poor man's singularize etc.
TLet g:tselectfiles_part_subst_ruby = {'s$': '', '^\(controller\|test\|spec\)$': ''}

" The max depth when globbing directories recursively. 0 = no limit.
TLet g:tselectfiles_limit = 0

" A dictionary of REGEXP => FUNCREF(filename) -> String describing the 
" file (DEFAULT: the filename).
TLet g:tselectfiles_filedescription_rx = {}

" Apply filters to basename only.
TLet g:tselectfiles_filter_basename = 0

" Remove prefix from filenames in list.
" buffer-local, global
TLet g:tselectfiles_prefix = ''

" Use these dirs (a comma separated list, see |globpath()|). (per window, per buffer, global)
" TLet g:tselectfiles_dir = ''

TLet g:tselectfiles_world = {
            \ 'type': 'm',
            \ 'query': 'Select files',
            \ 'scratch': '__tselectfiles__',
            \ 'return_agent': 'tselectfiles#ViewFile',
            \ 'display_format': 'tselectfiles#FormatEntry(world, %s)',
            \ 'filter_format': 'tselectfiles#FormatFilter(world, %s)',
            \ 'pick_last_item': 0,
            \ 'key_handlers': [
                \ {'key':  4,  'agent': 'tselectfiles#AgentDeleteFile',      'key_name': '<c-d>', 'help': 'Delete file(s)'},
                \ {'key': 18,  'agent': 'tselectfiles#AgentReset'},
                \ {'key': 19,  'agent': 'tlib#agent#EditFileInSplit',        'key_name': '<c-s>', 'help': 'Edit files (split)'},
                \ {'key': 22,  'agent': 'tlib#agent#EditFileInVSplit',       'key_name': '<c-v>', 'help': 'Edit files (vertical split)'},
                \ {'key': 20,  'agent': 'tlib#agent#EditFileInTab',          'key_name': '<c-t>', 'help': 'Edit files (new tab)'},
                \ {'key': 23,  'agent': 'tselectfiles#ViewFile',             'key_name': '<c-w>', 'help': 'View file in window'},
                \ {'key': 21,  'agent': 'tselectfiles#AgentRenameFile',      'key_name': '<c-u>', 'help': 'Rename file(s)'},
                \ {'key': 3,   'agent': 'tlib#agent#CopyItems',              'key_name': '<c-c>', 'help': 'Copy file name(s)'},
                \ {'key': 11,  'agent': 'tselectfiles#AgentCopyFile',        'key_name': '<c-k>', 'help': 'Copy file(s)'},
                \ {'key': 16,  'agent': 'tselectfiles#AgentPreviewFile',     'key_name': '<c-p>', 'help': 'Preview file'},
                \ {'key':  2,  'agent': 'tselectfiles#AgentBatchRenameFile', 'key_name': '<c-b>', 'help': 'Batch rename file(s)'},
                \ {'key': 126, 'agent': 'tselectfiles#AgentSelectBackups',   'key_name': '~',     'help': 'Select backup(s)'},
                \ {'key': 9,   'agent': 'tlib#agent#ShowInfo',               'key_name': '<c-i>', 'help': 'Show info'},
                \ {'key': 24,  'agent': 'tselectfiles#AgentHide',            'key_name': '<c-x>', 'help': 'Hide some files'},
                \ {'key':  7,  'agent': 'tselectfiles#Grep',                 'key_name': '<c-g>', 'help': 'Run vimgrep on selected files'},
                \ {'key': 28,  'agent': 'tlib#agent#ToggleStickyList',       'key_name': '<c-\>', 'help': 'Toggle sticky'},
            \ ],
            \ }
            " \ 'scratch_vertical': (&lines > &co),

TLet g:tselectfiles_suffixes = printf('\(%s\)\$', join(map(split(&suffixes, ','), 'v:val'), '\|'))

" Don't include files matching this regexp.
TLet g:tselectfiles_hidden_rx = '\V\(/.\|/CVS/\|/.attic/\|/.svn/\|/vimfiles\(/\[^/]\+\)\{-}/cache/\|'. tlib#rx#Suffixes('V') .'\)'
let g:tselectfiles_hidden_rx = substitute(g:tselectfiles_hidden_rx, '/', '\\[\\/]', 'g')
" TLet g:tselectfiles_skip_rx = tlib#rx#Suffixes('V')

" " TODO: cwindow doesn't currently work as expected
" TLet g:tselectfiles_show_quickfix_list = exists(':TRagcw') ? 'TRagcw' : 'cwindow'
if exists(':TRagcw')
    " The command that is run to show the quickfix list after running grep.
    TLet g:tselectfiles_show_quickfix_list = 'TRagcw'
endif

" TLet g:tselectfiles_dir_edit = 'TSelectFiles'
" 
" if !empty(g:tselectfiles_dir_edit)
"     if exists('g:loaded_netrwPlugin')
"         au! FileExplorer BufEnter
"     endif
"     augroup TSelectFiles
"         autocmd!
"         autocmd BufEnter * silent! if isdirectory(expand("<amatch>")) | exec g:tselectfiles_dir_edit .' '. expand("<amatch>") | endif
"     augroup END
" endif


if !exists('g:tselectfiles_favourites')
    if has('win16') || has('win32') || has('win64')
        let g:tselectfiles_favourites = ['c:/', 'd:/']
    else
        let g:tselectfiles_favourites = []
    endif
    if !empty($HOME)
        call add(g:tselectfiles_favourites, $HOME)
    endif
    if !empty($USERPROFILE)
        call add(g:tselectfiles_favourites, $USERPROFILE)
        " call add(g:tselectfiles_favourites, $USERPROFILE .'/desktop/')
    endif
endif


" :display: :TSelectFiles[!] [DIR]
" Open/delete/rename files in the current directory.
" A [!] forces the commands to rescan the directory. Otherwise a cached 
" value will be used if available.
" You can also type <c-r> to force rescanning a directory, which could 
" be necessary if the file system were changed (e.g. by creating a new 
" file or by some external command)
command! -bang -nargs=* -complete=dir TSelectFiles call tselectfiles#SelectFiles("normal<bang>".v:count, <f-args>)

" Recursively show all files in the current directory and subdirectories 
" (don't show favourites and ".."); don't use this command when you're 
" at /.
" A [!] forces the commands to rescan the directory. Otherwise a cached 
" value will be used if available.
command! -bang -nargs=* -complete=dir TSelectFilesInSubdirs call tselectfiles#SelectFiles("recursive<bang>".v:count, <f-args>)


finish

CHANGES:
0.1
Initial release

0.2
- Copy files
- Renamed TSelectFiles! to TSelectFilesInSubdirs
- Cache file listings (reset by adding a ! to the command or by typing 
<c-r> in the list view)
- g:tselectfiles_use_cache, g:tselectfiles_no_cache: Control the use of 
cached file listings
- If no start argument is provided, the starting directory can also be 
defined via b:tselectfiles_dir and g:tselectfiles_dir (use "." to use 
the current directory); this could be used to quickly select 
project-related files
- Key shortcuts to open files in (vertically) split windows or tabs
- <c-c> now is "Copy file names", <c-k> is "Copy files"

0.3
- Require tlib 0.9
- "Delete file" will ask whether to delete a corresponding buffer too.

0.4
- <c-w> ... View file in original window
- Disabled <c-o> Open dir
- Require tlib >= 0.12
- When renaming a file that's loaded, rename also the buffer.
- You can filter the list of selected files via setting the 
[wbg]:tselectfiles_filter_rx variable.
- Renamed g:tselectfiles_no_cache to g:tselectfiles_no_cache_rx
- [bg]:tselectfiles_use_cache and [bg]:tselectfiles_no_cache_rx can now 
also be set per buffer.
- Renamed some variables from tselectfile_* to tselectfiles_*.
- Can be "suspended" (i.e. you can switch back to the orignal window)

0.5
- [wbg]:tselectfiles_filter_rx is used only when no directory is given 
on the command line.
- Require tlib >= 0.18
- If the filename matches an entry in g:tselectfiles_filedescription_rx, 
use the expression there to construct a file description (eg the file's 
first line)
- Option to run vimgrep on selected files.
- tselectfiles#BaseFilter(): Set b:tselectfiles_filter_rx to something 
useful.
- tselectfiles#BaseFilter(): takes 2 optional arguments to substitute a 
rx in the current buffer's filename.

0.6
- tselectfiles_filter_rx: Set as array
- [gbw]tselectfiles_prefix: Remove prefix from filenames in list
- [gbw]tselectfiles_limit variable
- Problem when browsing single directories

0.7
- NEW: g:tselectfiles_part_subst* variables.
- NEW: [bg]:tselectfiles_filter_basename variable

0.8
- Require tlib 0.29
- g:tselectfiles_skip_rx

0.9
- Don't assume s:select_files_pattern.limit is set
- Include .* in tselectfiles_hidden_rx
- FIX: Include .* files (but hide them by default; thanks to 
naquad/Daniil F.).
- FIX: If 'splitbelow' is false, opening buffers in split view didn't 
properly work (thanks to naquad/Daniil F.)

0.10
- :TSelectFiles, :TSelectFilesInSubdirs, tselectfiles#SelectFiles: take 
an initial pattern as the second optional argument (i.e. if you pass a 
directory as first optional argument, you'll have to escape blanks with 
a backslash).
- tselectfiles#SelectFiles: if dir is &, search &path
- tselectfiles_filter_rx is always evaluated unless a pattern is 
provided as extra argument
- tselectfiles_prefix is always evaluated

