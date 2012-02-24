" Name Of File: darkocean.vim
"  Description: Gvim colorscheme, works best with version 6.0.
"   Maintainer: Naveen Chandra R <ncr AT iitbombay DOT org>
"  Last Change: Thursday, August 15, 2002
" Installation: Drop this file in your $VIMRUNTIME/colors/ directory
"               or manually source this file using ':so darkocean.vim'.

set background=dark
hi clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name="tmlDarkOcean"

" hi Cursor         gui=None            guibg=#add8e6    guifg=#000000
" hi CursorIM       gui=None            guibg=#add8e6    guifg=#000000
hi Conceal        gui=None            guibg=#102520    guifg=fg cterm=NONE ctermfg=NONE
hi Cursor         gui=None            guibg=#bf0000    guifg=fg
hi CursorIM       gui=None            guibg=#bf0000    guifg=fg
hi Directory      gui=None            guibg=bg         guifg=#20b2aa
hi DiffAdd        gui=Bold            guibg=#7e354d    guifg=fg
hi DiffChange     gui=Bold            guibg=#103040    guifg=#cc3300
hi DiffDelete     gui=Bold,Reverse    guibg=#7e354d    guifg=fg
hi DiffText       gui=Bold            guibg=#d74141    guifg=fg
hi ErrorMsg       gui=None            guibg=#b22222    guifg=#ffffe0
hi VertSplit      gui=None            guibg=#999999    guifg=#000000
hi Folded         gui=Bold            guibg=#003366    guifg=#999999
" hi FoldColumn     gui=None            guibg=#010101    guifg=#b0d0e0
hi FoldColumn     gui=None            guibg=#101013    guifg=#b0d0e0
" hi SignColumn     gui=None            guibg=#102520    guifg=#b0d0e0
hi SignColumn     gui=None            guibg=#101013    guifg=#b0d0e0
hi IncSearch      gui=Bold            guibg=#8db6cd    guifg=fg
hi LineNr         gui=Bold            guibg=#0f0f0f    guifg=#8db6cd
hi MoreMsg        gui=Bold            guibg=bg         guifg=#bf9261
hi ModeMsg        gui=Bold            guibg=bg         guifg=#4682b4
" hi NonText        gui=None            guibg=#0f0f0f    guifg=#87cefa
" hi NonText        gui=None            guibg=#1b2d40    guifg=#a0a0a0
" hi NonText        gui=None            guibg=#305070    guifg=#a0a0a0 cterm=NONE ctermfg=NONE
hi NonText        gui=None            guibg=#101013    guifg=#a0a0a0 cterm=NONE ctermfg=NONE
hi Normal         gui=None            guibg=#000000    guifg=#e0ffff
" hi Normal         gui=None            guibg=#101013    guifg=#e0ffff
hi Question       gui=Bold            guibg=bg         guifg=#f4bb7e
" hi Search         gui=Bold            guibg=#607b8b    guifg=#000000
hi Search         gui=None            guibg=#dfbe6a    guifg=#000000
hi SpecialKey     gui=None            guibg=bg         guifg=#63b8ff
hi StatusLine     gui=Bold            guibg=#8db6cd    guifg=#000000
hi StatusLineNC   gui=None            guibg=#607b8b    guifg=#1a1a1a
hi Title          gui=Bold            guibg=bg         guifg=#5cacee
" hi Visual         gui=Reverse         guibg=#ffffff    guifg=#36648b
hi Visual         gui=Reverse         guibg=bg    guifg=#e08b36
" hi VisualNOS      gui=Bold,Underline  guibg=#4682b4    guifg=fg
hi VisualNOS      gui=Bold,Underline  guibg=#dfae32    guifg=fg
hi WarningMsg     gui=Bold            guibg=bg         guifg=#b22222
hi WildMenu       gui=Bold            guibg=#607b8b    guifg=#000000
" hi Comment        gui=None            guibg=#102520    guifg=#8db6cd
hi Comment        gui=None            guibg=#102520    guifg=#9f7280
" hi Constant       gui=None            guibg=bg         guifg=#c34a2c
" hi Constant       gui=None            guibg=bg         guifg=#3b9c9c
hi Constant       gui=None            guibg=bg         guifg=#8fbcad
hi Identifier     gui=None            guibg=bg         guifg=#009acd
hi Statement      gui=None            guibg=bg         guifg=#72a5ee
" hi PreProc        gui=None            guibg=bg         guifg=#c12869
hi PreProc        gui=None            guibg=bg         guifg=#c15884
hi Include        gui=None            guibg=bg         guifg=#ccccff
" hi Type           gui=None            guibg=bg         guifg=#3b9c9c
hi Type           gui=None            guibg=bg         guifg=#c34a2c
hi Error          gui=None            guibg=#b22222    guifg=#ffffe0
hi Todo           gui=None            guibg=#507080    guifg=#3bcccc
hi Ignore         gui=None            guibg=bg         guifg=#777777
hi TagName        gui=None            guibg=#660000    guifg=#a7a7a7
" hi CursorLine     gui=None            guibg=#202020
" hi CursorLine     gui=None            guibg=#090909 guifg=None

if v:version >= 700
    hi Pmenu          gui=None            guibg=#9f430b    guifg=#e0e0e0
    hi PmenuSel       gui=None            guibg=#df600f    guifg=#ffffff
    " hi PmenuSbar      gui=None            guibg=#5f2806    guifg=#e0e0e0
    " hi PmenuThumb
endif

