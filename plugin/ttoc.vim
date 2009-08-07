" ttoc.vim -- A regexp-based ToC of the current buffer
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-07-09.
" @Last Change: 2009-08-04.
" @Revision:    463
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


" Markers as used by vim and other editors. Can be also buffer-local. 
" This rx is added to the filetype-specific rx.
" Values:
"   0      ... disable
"   1      ... use &foldmarker
"   2      ... use &foldmarker only if &foldmethod == marker
"   string ... use as rx
TLet g:ttoc_markers = 1

" if has('signs')
"     " If non-empty, mark locations with signs.
"     TLet g:ttoc_sign = '~'
"     exec 'sign define TToC text='. g:ttoc_sign .' texthl=Special'
" else
"     " :nodoc:
"     TLet g:ttoc_sign = ''
" endif


" By default, assume that everything at the first column is important.
TLet g:ttoc_rx = '^\w.*'

" TLet g:ttoc_markers = '.\{-}{{{.*'


" Filetype-specific rx "{{{2

" :doc:
" Some filetype-specific regexps. If you don't like the default values, 
" set these variables in ~/.vimrc.

TLet g:ttoc_rx_bib    = '^@\w\+\s*{\s*\zs\S\{-}\ze\s*,'
TLet g:ttoc_rx_c      = '^[[:alnum:]#].*'
TLet g:ttoc_rx_cpp    = g:ttoc_rx_c
TLet g:ttoc_rx_html   = '\(<h\d.\{-}</h\d>\|<\(html\|head\|body\|div\|script\|a\s\+name=\).\{-}>\|<.\{-}\<id=.\{-}>\)'
TLet g:ttoc_rx_java   = '^\s*\(\(package\|import\|private\|public\|protected\|void\|int\|boolean\)\s\+\|\u\).*'
TLet g:ttoc_rx_javascript = '^\(var\s\+.\{-}\|\s*\w\+\s*:\s*\S.\{-}[,{]\)\s*$'
TLet g:ttoc_rx_perl   = '^\([$%@]\|\s*\(use\|sub\)\>\).*'
TLet g:ttoc_rx_php    = '^\(\w\|\s*\(class\|function\|var\|require\w*\|include\w*\)\>\).*'
TLet g:ttoc_rx_python = '^\s*\(import\|class\|def\)\>.*'
TLet g:ttoc_rx_rd     = '^\(=\+\|:\w\+:\).*'
TLet g:ttoc_rx_ruby   = '\C^\(if\>\|\s*\(class\|module\|def\|require\|private\|public\|protected\|module_functon\|alias\|attr\(_reader\|_writer\|_accessor\)\?\)\>\|\s*[[:upper:]_]\+\s*=\).*'
TLet g:ttoc_rx_scheme = '^\s*(define.*'
TLet g:ttoc_rx_sh     = '^\s*\(\(export\|function\|while\|case\|if\)\>\|\w\+\s*()\s*{\).*'
TLet g:ttoc_rx_tcl    = '^\s*\(source\|proc\)\>.*'
TLet g:ttoc_rx_tex    = '\C\\\(label\|\(sub\)*\(section\|paragraph\|part\)\)\>.*'
TLet g:ttoc_rx_viki   = '^\(\*\+\|\s*#\l\).*'
TLet g:ttoc_rx_vim    = '\C^\(fu\%[nction]\|com\%[mand]\|if\|wh\%[ile]\)\>.*'

" TLet g:ttoc_rx_vim    = '\C^\(\(fu\|if\|wh\).*\|.\{-}\ze\("\s*\)\?{{{.*\)'
" TLet g:ttoc_rx_ocaml  = '^\(let\|module\|\s*let .\{-}function\).*'


" :nodefault:
" ttoc-specific |tlib#input#ListD| configuration.
" Customizations should be done in ~/.vimrc/after/plugin/ttoc.vim
" E.g. in order to split horizontally, use: >
"     let g:ttoc_world.scratch_vertical = 0
TLet g:ttoc_world = {
                \ 'type': 'm',
                \ 'query': 'Select entry',
                \ 'pick_last_item': 0,
                \ 'scratch': '__ttoc__',
                \ 'retrieve_eval': 'ttoc#Collect(world, 0)',
                \ 'return_agent': 'ttoc#GotoLine',
                \ 'key_handlers': [
                    \ {'key': 16, 'agent': 'tlib#agent#PreviewLine',  'key_name': '<c-p>', 'help': 'Preview'},
                    \ {'key':  7, 'agent': 'ttoc#GotoLine',     'key_name': '<c-g>', 'help': 'Jump (don''t close the TOC window)'},
                    \ {'key': 60, 'agent': 'ttoc#GotoLine',     'key_name': '<',     'help': 'Jump (don''t close the TOC window)'},
                    \ {'key':  5, 'agent': 'tlib#agent#DoAtLine',     'key_name': '<c-e>', 'help': 'Run a command on selected lines'},
                    \ {'key': "\<c-insert>", 'agent': 'ttoc#SetFollowCursor', 'key_name': '<c-ins>', 'help': 'Toggle trace cursor'},
                    \ {'key': 28, 'agent': 'tlib#agent#ToggleStickyList',       'key_name': '<c-\>', 'help': 'Toggle sticky'},
                \ ],
            \ }
            " \ 'scratch_vertical': (&lines > &co),


" If true, split vertical.
TLet g:ttoc_vertical = '&lines < &co'
" TLet g:ttoc_vertical = -1

" Vim code that evaluates to the desired window width/heigth.
TLet g:ttoc_win_size = '((&lines > &co) ? &lines : &co) / 2'
" TLet g:ttoc_win_size = '((&lines > &co) ? winheight(0) : winwidth(0)) / 2'


" function! TToC_GetLine_vim(lnum, acc) "{{{3
"     let l = a:lnum
"     while 1
"         let l -= 1
"         let t = getline(l)
"         if !empty(t) && t =~ '^\s*"'
"             let t = matchstr(t, '"\s*\zs.*')
"             TLogVAR t
"             call insert(a:acc, t, 1)
"         else
"             break
"         endif
"     endwh
"     return l
" endf


function! TToC_GetLine_viki(lnum, acc) "{{{3
    let l = a:lnum
    while 1
        let l += 1
        let t = getline(l)
        if !empty(t)
            if t[0] == '#'
                call add(a:acc, t)
            elseif t =~ '\s\+::\s\+'
                call add(a:acc, t)
            else
                break
            end
        else
            break
        endif
    endwh
    return l
endf


function! TToC_GetLine_bib(lnum, acc) "{{{3
    for l in range(a:lnum + tlib#string#Count(a:acc[0], '\n'), a:lnum + 4)
        let t = getline(l)
        if !empty(t)
            call add(a:acc, t)
        endif
    endfor
    return a:lnum + 5
endf


augroup TToC
    autocmd!
augroup END


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

