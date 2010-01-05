" tbibtools.vim -- bibtex-related utilities (require ruby support)
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim-tbibtools)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-03-30.
" @Last Change: 2010-01-03.
" @Revision:    0.5.200
"
" GetLatestVimScripts: 1915 1 tbibtools.vim

if &cp || exists("loaded_tbibtools")
    finish
endif
if !has('ruby')
    " echohl Error
    " echo 'tbibtools requires compiled-in ruby support'
    " echohl NONE
    finish
end
if !exists('loaded_tlib') || loaded_tlib < 9
    echoerr 'tlib >= 0.9 is required'
    finish
endif
let loaded_tbibtools = 7

let s:save_cpo = &cpo
set cpo&vim


" Please see ~/.vim/ruby/tbibtools/index.html for details.
command! -range=% -nargs=? -bar TBibTools ruby
            \ TVimTools.new.process_range(<line1>, <line2>)
            \ {|text| TBibTools.new.parse_command_line_args(<q-args>.split(/\s+/)).bibtex_sort_by(nil, text)}

" This command uses the --ls command line option
command! -nargs=? -bang -bar TBibList call s:TBibList("<bang>", <q-args>)


let &cpo = s:save_cpo
unlet s:save_cpo
finish

0.1
- Initial version

0.2
- The configuration file is always loaded (also when called from Vim)
- The configuration file is evaluated in the context of the configuration object (use some kind of configuration DSL)
- Use optargs for parsing command line arguments (i.e. command line options have slightly changed)
- Improved simple_bibtex_parser()

0.3
- Syntax of the query command has changed: query FIELD1 => RX1, FIELD2 => RX2 ...
- Merge duplicate entries
- Merge certain conflicting fields
- FIX: Problem with --ls

0.4
- sortCrossref: Put cross-referenced entries to the back.
- New format: (un)selectCrossref: View only entries that are (not) cross-referenced
- VIM: Improved TBibList (include keywords in list; if g:tbibUseCache is set, the listing will be cached between editing sessions)

0.5
- VIM: Require tlib 0.9

0.6
- Format "squeeze": Remove redundant whitespace

0.7
- Die silently if +ruby support is unavailable.
- Moved the definition of some variables from plugin/tbibtools.vim to 
autoload/tbibtools.vim


