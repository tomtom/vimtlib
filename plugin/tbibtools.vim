" tbibtools.vim -- bibtex-related utilities (require ruby support)
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim-tbibtools)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-03-30.
" @Last Change: 2010-01-02.
" @Revision:    0.5.196
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

fun! s:SNR()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSNR$')
endf

if !exists('g:tbibUseCache') "{{{2
    let g:tbibUseCache = 1
endif
if !exists('g:tbibListFormat') "{{{2
    let g:tbibListFormat = "#{author|editor|institution|organization}: #{title|booktitle} [#{keywords|keyword}] #{_id} #4{_lineno}"
endif
if !exists('g:tbibListFormat_get_id') "{{{2
    let g:tbibListFormat_get_id = '\s\zs\S\{-}\ze \d\+$'
endif
if !exists('g:tbibListFormat_get_lineno') "{{{2
    let g:tbibListFormat_get_lineno = '\d\+$'
endif
if !exists('g:tbibListViewHandlers') "{{{2
    let g:tbibListViewHandlers = [
                \ {'key': 16, 'agent': s:SNR().'AgentPreviewEntry', 'key_name': '<c-p>', 'help': 'Preview entry'},
                \ {'key':  3, 'agent': s:SNR().'AgentCopyKey', 'key_name': '<c-c>', 'help': 'Copy keys'},
                \ {'pick_last_item': 0},
                \ ]
endif

let s:source = expand('<sfile>:p:h:h')

" exec 'rubyfile '. s:source .'/ruby/tbibtools.rb'
" exec 'rubyfile '. s:source .'/ruby/tvimtools.rb'

ruby <<EOR
for f in ['tbibtools.rb', 'tvimtools.rb']
    ff = File.join(VIM::evaluate('s:source'), 'ruby', f)
    if File.exists?(ff)
        require ff
    else
        # begin
            require f
        # rescue Exception => e
        #     puts e
        # end
    end
end
EOR

fun! s:GotoItem(entry)
    let lineno = matchstr(a:entry, g:tbibListFormat_get_lineno)
    " TLogVAR a:entry
    " TLogVAR lineno
    exec lineno
    exec 'norm! '. lineno .'zt'
endf

fun! s:AgentPreviewEntry(world, selected)
    let entry = a:selected[0]
    let bn = winnr()
    exec s:bib_win .'wincmd w'
    call s:GotoItem(entry)
    redraw
    exec bn .'wincmd w'
    let a:world.state = 'redisplay'
    return a:world
endf

function! s:AgentCopyKey(world, selected) "{{{3
    let keys = map(a:selected, 'matchstr(v:val, g:tbibListFormat_get_id)')
    let @* = join(keys, ',')
    call a:world.ResetSelected()
    return a:world
endf

fun! s:TBibList(bang, args)
    if !empty(a:bang) || !exists('b:tbiblisting')
        if g:tbibUseCache
            let cfile = tlib#cache#Filename('tbibtools', '', 1)
            if empty(a:bang)
                let cdata = tlib#cache#Get(cfile)
                if !empty(cdata)
                    let b:tbiblisting = cdata.tbiblisting
                endif
            endif
        endif
        if !empty(a:bang) || !exists('b:tbiblisting')
            let b:tbiblisting = []
            ruby <<EOR
            args = ["-l'#{VIM::evaluate("g:tbibListFormat")}'"] + VIM::evaluate("a:args").split(/\s+/)
            lines = TVimTools.new.with_range(1, VIM::evaluate("line('$')").to_i) do |text|
                TBibTools.new.parse_command_line_args(args).bibtex_sort_by(nil, text)
            end
            lines.each do |l|
                l = l.chomp
                l = l[1..-2]
                l.gsub!(/'/, "''")
                VIM::evaluate("add(b:tbiblisting, '#{l}')")
            end
EOR
            if g:tbibUseCache
                call tlib#cache#Save(cfile, {'tbiblisting': b:tbiblisting})
            endif
        endif
    endif
    let s:bib_win = winnr()
    let entry = tlib#input#List('m', 'Select entry', b:tbiblisting, g:tbibListViewHandlers)
    if !empty(entry)
        call s:GotoItem(entry[0])
    endif
endf

" Please see ~/.vim/ruby/tbibtools/index.html for details.
command! -range=% -nargs=? -bar TBibTools ruby
            \ TVimTools.new.process_range(<line1>, <line2>)
            \ {|text| TBibTools.new.parse_command_line_args(<q-args>.split(/\s+/)).bibtex_sort_by(nil, text)}

" This command uses the --ls command line option
command! -nargs=? -bang -bar TBibList call s:TBibList("<bang>", <q-args>)


finish



Changes~

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

