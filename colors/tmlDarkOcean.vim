" tmlDarkOcean.vim
" (based on darkocean.vim by Naveen Chandra R <ncr AT iitbombay DOT org>)
" @Author:      Tom Link (micathom AT gmail com)
" @Last Change: 2012-02-24.

set background=dark
hi clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name="tmlDarkOcean"

hi ColorColumn   gui=NONE            guibg=#101013  guifg=#b0d0e0
hi Comment       gui=NONE            guibg=#102520  guifg=#9f7280  cterm=NONE         ctermfg=magenta ctermbg=darkgray
hi Conceal       gui=NONE            guibg=#102520  guifg=fg       cterm=NONE         ctermfg=NONE
hi Constant      gui=NONE            guibg=bg       guifg=#8fbcad  ctermfg=darkgreen
hi Cursor        gui=NONE            guibg=#bf0000  guifg=fg
hi CursorColumn  gui=NONE            guibg=#202020
hi CursorIM      gui=NONE            guibg=#bf0000  guifg=fg
hi CursorLine    gui=NONE            guibg=#202020
hi DiffAdd       gui=Bold            guibg=#7e354d  guifg=fg       ctermbg=darkmagenta
hi DiffChange    gui=Bold            guibg=#103040  guifg=#cc3300  ctermfg=red          ctermbg=darkgray
hi DiffDelete    gui=Bold,Reverse    guibg=#7e354d  guifg=fg       ctermfg=darkmagenta  ctermbg=white
hi DiffText      gui=Bold            guibg=#d74141  guifg=fg
hi Directory     gui=NONE            guibg=bg       guifg=#20b2aa
hi Error         gui=NONE            guibg=#b22222  guifg=#ffffe0
hi ErrorMsg      gui=NONE            guibg=#b22222  guifg=#ffffe0
hi FoldColumn    gui=NONE            guibg=#101013  guifg=#b0d0e0  ctermfg=gray       ctermbg=darkgray
hi Folded        gui=Bold            guibg=#003366  guifg=#999999  cterm=bold         ctermfg=black      ctermbg=darkblue
hi Identifier    gui=NONE            guibg=bg       guifg=#009acd  cterm=NONE         ctermfg=blue
hi Ignore        gui=NONE            guibg=bg       guifg=#777777
hi Include       gui=NONE            guibg=bg       guifg=#ccccff
hi IncSearch     gui=Bold            guibg=#8db6cd  guifg=fg       ctermfg=lightcyan
hi LineNr        gui=Bold            guibg=#0f0f0f  guifg=#8db6cd  cterm=bold         ctermfg=lightcyan
hi ModeMsg       gui=Bold            guibg=bg       guifg=#4682b4  cterm=bold         ctermfg=darkblue
hi MoreMsg       gui=Bold            guibg=bg       guifg=#bf9261  cterm=bold         ctermfg=brown
hi NonText       gui=NONE            guibg=#101013  guifg=#a0a0a0  cterm=NONE         ctermfg=NONE
hi Normal        gui=NONE            guibg=#000000  guifg=#e0ffff
hi Pmenu         gui=NONE            guibg=#9f430b  guifg=#e0e0e0
hi PmenuSel      gui=NONE            guibg=#df600f  guifg=#ffffff
hi PreProc       gui=NONE            guibg=bg       guifg=#c15884
hi Question      gui=Bold            guibg=bg       guifg=#f4bb7e  cterm=bold         ctermfg=brown
hi Search        gui=NONE            guibg=#dfbe6a  guifg=#000000
hi SignColumn    gui=NONE            guibg=#101013  guifg=#b0d0e0
hi Special       gui=NONE            guibg=bg       guifg=orange   ctermfg=yellow
hi SpecialKey    gui=NONE            guibg=bg       guifg=#63b8ff
hi Statement     gui=NONE            guibg=bg       guifg=#72a5ee  cterm=NONE         ctermfg=cyan
hi StatusLine    gui=Bold            guibg=#8db6cd  guifg=#000000  cterm=reverse      ctermfg=gray       ctermbg=black
hi StatusLineNC  gui=NONE            guibg=#607b8b  guifg=#1a1a1a  cterm=reverse      ctermfg=gray       ctermbg=black
hi TabLine       gui=underline       guibg=#101013  guifg=#8db6cd
hi TabLineFill   gui=underline       guibg=bg       guifg=#8db6cd
hi TabLineSel    gui=underline       guibg=#8db6cd  guifg=#101013
hi TagName       gui=NONE            guibg=#660000  guifg=#a7a7a7
hi Title         gui=Bold            guibg=bg       guifg=#5cacee  cterm=NONE ctermfg=blue
hi Todo          gui=NONE            guibg=#507080  guifg=#3bcccc
hi Type          gui=NONE            guibg=bg       guifg=#c34a2c
hi VertSplit     gui=NONE            guibg=#999999  guifg=#000000  ctermbg=gray
hi Visual        gui=Reverse         guibg=bg       guifg=#e08b36  ctermfg=DarkYellow
hi VisualNOS     gui=Bold,Underline  guibg=#dfae32  guifg=fg       ctermfg=Yellow
hi WarningMsg    gui=Bold            guibg=bg       guifg=#b22222
hi WildMenu      gui=Bold            guibg=#607b8b  guifg=#000000  ctermfg=gray         ctermbg=black

