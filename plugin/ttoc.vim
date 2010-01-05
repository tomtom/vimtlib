" ttoc.vim -- A regexp-based ToC of the current buffer
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-07-09.
" @Last Change: 2010-01-03.
" @Revision:    467
" GetLatestVimScripts: 2014 0 ttoc.vim
" TODO: The cursor isn't set to the old location after using "preview".

if &cp || exists("loaded_ttoc")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 32
    echoerr 'tlib >= 0.32 is required'
    finish
endif
let loaded_ttoc = 5

let s:save_cpo = &cpo
set cpo&vim


" :display: :[COUNT]TToC[!] [REGEXP]
" EXAMPLES: >
"   TToC                   ... use standard settings
"   TToC foo.\{-}\ze \+bar ... show this rx (don't include 'bar')
"   TToC! foo.\{-}bar      ... show lines matching this rx 
"   3TToC! foo.\{-}bar     ... show lines matching this rx + 3 extra lines
command! -nargs=? -bang -count TToC call ttoc#View(<q-args>, !empty("<bang>"), v:count, <count>)

" Synonym for |:TToC|.
command! -nargs=? -bang -count Ttoc call ttoc#View(<q-args>, !empty("<bang>"), v:count, <count>)

" Like |:TToC| but open the list in "background", i.e. the focus stays 
" in the document window.
command! -nargs=? -bang -count Ttocbg call ttoc#View(<q-args>, !empty("<bang>"), v:count, <count>, 1)


let &cpo = s:save_cpo

finish
CHANGES:
0.1
- Initial release

0.2
- Require tlib 0.14
- <c-e> Run a command on selected lines.
- g:ttoc_world can be a normal dictionary.
- Use tlib#input#ListD() instead of tlib#input#ListW().

0.3
- Highlight the search term on partial searches
- Defined :Ttoc as synonym for :TToC
- Defined :Ttocbg to open a toc in the "background" (leave the 
focus/cursor in the main window)
- Require tlib 0.21
- Experimental: ttoc#Autoword(onoff): automatically show lines 
containing the word under the cursor; must be enabled for each buffer.
- Split plugin into (autoload|plugin)/ttoc.vim
- Follow/trace cursor functionality (toggled with <c-t>): instantly 
preview the line under cursor.
- Restore original position when using preview

0.4
- Handle multi-line regexps (thanks to M Weber for pointing this out)
- Require tlib 0.27
- Changed key for "trace cursor" from <c-t> to <c-insert>.

0.5
- Require tlib 0.32
- Fill location list

0.6
- Moved the definition of some variables from plugin/ttoc.vim to autoload/ttoc.vim

