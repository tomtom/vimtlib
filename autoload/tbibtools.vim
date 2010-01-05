" tbibtools.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-03.
" @Last Change: 2010-01-03.
" @Revision:    0.0.4

let s:save_cpo = &cpo
set cpo&vim
" call tlog#Log('Load: '. expand('<sfile>')) " vimtlib-sfile


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



let &cpo = s:save_cpo
unlet s:save_cpo
