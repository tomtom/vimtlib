" glark.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=vim-glark)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     25-Jän-2006.
" @Last Change: 2007-08-27.
" @Revision:    0.36

if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

syntax match GlarkComment /^\* .*$/
syntax match GlarkFilename /^\S.*$/
" syntax match GlarkMatchingLine /^\s\+\d\+ \(: \)\?/ nextgroup=GlarkMatchingHead
" syntax match GlarkMatchingHead /.*$/
" syntax match GlarkLine /^\s\+\d\+ [+-] / nextgroup=GlarkHead
" syntax match GlarkHead /.*$/
syntax region GlarkLine matchgroup=GlarkHead start=/^\s\+\d\+ \([+-] \)\?/ end=/$/ contains=GlarkMatch
syntax region GlarkMatchingLine matchgroup=GlarkMatchingHead start=/^\s\+\d\+ : / end=/$/ contains=GlarkMatch

call GlarkParseExplain()

if version >= 508 || !exists("did_glark_syntax_inits")
  if version < 508
    let did_glark_syntax_inits = 1
    command! -nargs=+ HiLink hi link <args>
  else
    command! -nargs=+ HiLink hi def link <args>
  endif
 
  HiLink GlarkComment Comment
  HiLink GlarkFilename Title
  HiLink GlarkMatchingLine Special
  HiLink GlarkMatchingHead DiffChange
  " HiLink GlarkLine Comment
  HiLink GlarkHead LineNr
  HiLink GlarkMatch Search

  delcommand HiLink
endif

let b:current_syntax = 'glark'

