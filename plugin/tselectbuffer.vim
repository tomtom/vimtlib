" tselectbuffer.vim -- A simplicistic buffer selector/switcher
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-15.
" @Last Change: 2010-01-03.
" @Revision:    323
" GetLatestVimScripts: 1866 1 tselectbuffer.vim

if &cp || exists("loaded_tselectbuffer")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 24
    echoerr 'tlib >= 0.24 is required'
    finish
endif
let loaded_tselectbuffer = 7


command! -count=0 -bang TSelectBuffer call tselectbuffer#Select(!empty("<bang>") || v:count)


finish
0.1
Initial release

0.2
- Minor improvements

0.3
- <c-u>: Rename buffer (and file on disk)
- <c-v>: Show buffers in vertically split windows
- Require tlib 0.9
- "Delete buffer" will wipe-out unloaded buffers.

0.4
- <c-w> ... View file in original window
- < ... Jump to already opened window, preferably on the current tab 
page (if any)
- Enabled <c-t> to open buffer in tab
- Require tlib 0.13
- Initially select the alternate buffer
- Make a count act as bang.
- Can be "suspended" (i.e. you can switch back to the orignal window)

0.5
- Alternate buffer wasn't initially selected after 0.4
- FIX: <c-s> and similar keys didn't work.

0.6
- MRU order

0.7
- Moved the definition of some variables from plugin/tselectbuffer.vim 
to autoload/tselectbuffer.vim

