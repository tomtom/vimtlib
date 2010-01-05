" tselectfile.vim -- A simplicistic files selector/browser (sort of)
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-16.
" @Last Change: 2010-01-03.
" @Revision:    606
" GetLatestVimScripts: 1865 1 tselectfiles.vim

if &cp || exists("loaded_tselectfile")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 29
    echoerr "tlib >= 0.29 is required"
    finish
endif
let loaded_tselectfile = 10



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

0.11
- Moved the definition of some variables from plugin/tselectfiles.vim to 
autoload/tselectfiles.vim

