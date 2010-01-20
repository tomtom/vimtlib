" plugin.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-04.
" @Last Change: 2010-01-20.
" @Revision:    521

if &cp || exists("loaded_tplugin")
    finish
endif
let loaded_tplugin = 4

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:tplugin_autoload')
    " Enable autoloading. See |:TPluginScan|, |:TPluginCommand|, and 
    " |:TPluginFunction|.
    let g:tplugin_autoload = 1   "{{{2
endif


if !exists('g:tplugin_helptags')
    " If non-nil, optionally generate helptags for the repository's doc 
    " subdirectory.
    let g:tplugin_helptags = 1   "{{{2
endif


if !exists('g:tplugin_menu_prefix')
    " If autoload is enabled and this variable is non-empty, build a 
    " menu with available plugins.
    " Menus are disabled by default because they are less useful 
    " than one might think with autoload enabled.
    " A good choice for this variable would be, e.g., 
    " 'Plugin.T&Plugin.'.
    " NOTE: You have to re-run |:TPluginScan| after setting this 
    " value.
    let g:tplugin_menu_prefix = ''   "{{{2
    " let g:tplugin_menu_prefix = 'Plugin.T&Plugin.'   "{{{2
endif


if !exists('g:tplugin_scan')
    " The default value for |:TPluginScan|.
    let g:tplugin_scan = 'cfapt'   "{{{2
endif


function! s:Join(filename_parts) "{{{3
    let parts = map(copy(a:filename_parts), 'substitute(v:val, ''[\/]\+$'', "", "")')
    return join(parts, '/')
endf


let s:roots = []
let s:rtp = split(&rtp, ',')
let s:reg = {}
let s:done = {}
let s:immediate = 0
let s:before = {}
let s:after = {}
let s:helptags = []
let s:ftypes = {}
let s:functions = {}


augroup TPlugin
    autocmd!
    autocmd VimEnter * call s:Process()
augroup END


function! s:RegisterFunction(def) "{{{3
    let s:functions[a:def[1]] = a:def
endf


" args: A string it type == 1, a list if type == 2
function! s:Autoload(type, def, bang, range, args) "{{{3
    " TLogVAR a:type, a:def, a:bang, a:range, a:args
    let [root, cmd; file] = a:def
    " TLogVAR root, cmd, file
    if a:type == 1 " Command
        exec 'delcommand '. cmd
    endif
    if len(file) >= 1 && len(file) <= 2
        call call('TPlugin', [1, root] + file)
    else
        echoerr 'Malformed autocommand definition: '. join(a:def)
    endif
    if a:type == 1 " Command
        let range = join(filter(copy(a:range), '!empty(v:val)'), ',')
        " TLogDBG range . cmd . a:bang .' '. a:args
        try
            exec range . cmd . a:bang .' '. a:args
        catch /^Vim\%((\a\+)\)\=:E481/
            exec cmd . a:bang .' '. a:args
        endtry
    elseif a:type == 2 " Function
    elseif a:type == 3 " Map
    else
        echoerr 'Unsupported type: '. a:type
    endif
endf


" function! TPluginHelp(tags) "{{{3
"     call add(s:helptags, a:tags)
" endf


function! TPluginFiletype(filetype, repos) "{{{3
    if !has_key(s:ftypes, a:filetype)
        let s:ftypes[a:filetype] = []
    endif
    call extend(s:ftypes[a:filetype], a:repos)
endf


function! s:Filetype(filetype) "{{{3
    " TLogVAR a:repos
    for repo in s:ftypes[a:filetype]
        call TPlugin(1, repo, '.', '.')
    endfor
    call remove(s:ftypes, a:filetype)
    exec 'setfiletype '. a:filetype
endf


function! s:AutoloadFunction(fn) "{{{3
    " TLogVAR a:fn
    " call tlog#Debug(string(keys(s:functions)))
    if has_key(s:functions, a:fn)
        " TLogVAR a:fn
        let def = s:functions[a:fn]
        " TLogVAR def
        call s:Autoload(2, def, '', [], [])
        " Ignored
        return 1
    endif
endf


function! s:Map(root, def) "{{{3
    " echom "DBG ". string(a:root) .' '. string(a:def)
    let [m, repo, plugin] = a:def
    let def = [a:root, repo, plugin]
    let plug = matchstr(m, '\c<plug>\w\+$')
    if !empty(plug)
        exec m .' <C-\><C-G>:call <SID>Remap('. string(plug) .', '. string(m) .', '. string(def) .')<cr>'
    endif
endf


function! s:Remap(keys, m, def) "{{{3
    " TLogVAR a:keys, a:m, a:def
    let mode = matchstr(a:m, '\<\([incvoslx]\?\)\ze\(nore\)\?map')
    exec mode .'unmap '. a:keys
    call call('TPlugin', [1] + a:def)
    let keys = substitute(a:keys, '<\ze\w\+\(-\w\+\)*>', '\\<', 'g')
    let keys = eval('"'. escape(keys, '"') .'"')
    " TLogVAR keys, a:keys
    call feedkeys(keys)
endf


let s:rx = {
            \ 'c': '^\s*:\?com\%[mand]!\?\s\+\(-\S\+\s\+\)*\zs\w\+',
            \ 'f': '^\s*:\?fu\%[nction]!\?\s\+\zs\(s:\|<SID>\)\@![[:alnum:]#]\+',
            \ 'p': '\c^\s*:\?\zs[incvoslx]\?\(nore\)\?map\s\+\(<\(silent\|unique\|buffer\|script\)>\s*\)*<plug>\w\+',
            \ }

let s:fmt = {
            \ 'c': {'cargs3': 'TPluginCommand %s %s %s'},
            \ 'f': {'cargs3': 'TPluginFunction %s %s %s'},
            \ 'p': {'arr1': 'TPluginMap %s'},
            \ }


function! s:ScanSource(repo, plugin, what, lines) "{{{3
    let text = join(a:lines, "\n")
    let text = substitute(text, '\n\s*\\', '', 'g')
    let lines = split(text, '\n')
    call map(lines, 's:ScanLine(a:repo, a:plugin, a:what, v:val)')
    call filter(lines, '!empty(v:val)')
    return lines
endf


function! s:ScanLine(repo, plugin, what, line) "{{{3
    for what in a:what
        let rx = get(s:rx, what, '')
        if !empty(rx)
            " TLogVAR rx
            " let rx = rx[0:2] . substitute(rx[3:-1], '\C\\s', '\\(\\n\\s*\\\\\\s*\\|\\s\\+\\)', 'g')
            let m = matchstr(a:line, rx)
            if !empty(m)
                let fmt = s:fmt[what]
                if has_key(fmt, 'arr1')
                    return printf(fmt.arr1, string([m, a:repo, a:plugin]))
                else
                    return printf(fmt.cargs3, m, a:repo, a:plugin)
                endif
            endif
        endif
    endfor
endf


" Write autoload information for all known root directories to 
" "ROOT/tplugin.vim".
function! s:Scan(immediate, roots, args) "{{{3
    let awhat = get(a:args, 0, '')
    if empty(awhat)
        let what = split(g:tplugin_scan, '\zs')
    elseif awhat == 'all'
        let what = ['c', 'f', 'a', 'p', 'h', 't']
    else
        let what = split(awhat, '\zs')
    endif

    let aroot = get(a:args, 1, '')
    if empty(aroot)
        let roots = a:roots
    else
        let roots = [fnamemodify(aroot, ':p')]
    endif

    " TLogVAR what, a:roots

    for root in roots

        let out = []

        if g:tplugin_helptags
            let helpdirs = split(glob(join([root, '*', 'doc'], '/')), '\n')
            for doc in helpdirs
                let tags = join([doc, 'tags'], '/')
                if index(what, 'h') != -1 || !filereadable(tags)
                    if isdirectory(doc)
                        exec 'helptags '. fnameescape(doc)
                    endif
                endif
                " call add(out, 'call TPluginHelp('. string(tags) .')')
            endfor
        endif

        let files = glob(join([root, '*', 'plugin', '*.vim'], '/'))
        if index(what, 'a') != -1
            let files .= "\n". glob(join([root, '*', 'autoload', '*.vim'], '/'))
            let files .= "\n". glob(join([root, '*', 'autoload', '**', '*.vim'], '/'))
        endif
        let pos0 = len(root) + 1

        let filelist = split(files, '\n')
        let progressbar = exists('g:loaded_tlib')
        if progressbar
            call tlib#progressbar#Init(len(filelist), 'TPluginscan: Scanning '. escape(root, '%') .' %s', 20)
        else
            echo 'TPluginscan: Scanning '. root .' ...'
        endif

        if index(what, 't') != -1
            let filetypes  = glob(join([root, '*', 'syntax', '*.vim'], '/')) ."\n"
            let filetypes .= glob(join([root, '*', 'indent', '*.vim'], '/')) ."\n"
            let filetypes .= glob(join([root, '*', 'ftplugin', '*.vim'], '/'))
            " TLogVAR filetypes
            let ftd = {}
            for ftfile in filter(split(filetypes, '\n'), '!empty(v:val)')
                let ft = fnamemodify(ftfile, ':t:r')
                " TLogVAR ft
                if !has_key(ftd, ft)
                    let ftd[ft] = {}
                endif
                let repo = matchstr(ftfile, '^.\{-}\%'. (len(root) + 2) .'c[^\/]\+')
                " TLogVAR ftfile, repo
                let ftd[ft][repo] = 1
            endfor
            for [ft, repos] in items(ftd)
                " TLogVAR ft, repos
                call add(out, 'call TPluginFiletype('. string(ft) .','. string(keys(repos)) .')')
            endfor
        endif

        try
            let fidx = 0
            let menu_done = {}
            for file in filelist
                if progressbar
                    let fidx += 1
                    call tlib#progressbar#Display(fidx)
                endif
                let repo   = matchstr(strpart(file, pos0), '^[^\/]\+\ze[\/]')
                let plugin = matchstr(file, '[\/]\zs[^\/]\{-}\ze\.vim$')
                " TLogVAR file, repo, plugin

                if !empty(g:tplugin_menu_prefix)
                    let mrepo = escape(repo, '\.')
                    let mplugin = escape(plugin, '\.')
                    if !has_key(menu_done, repo)
                        call add(out, 'call TPluginMenu('. string(mrepo .'.Repository') .', '.
                                    \ string(':TPlugin! '. repo .'<cr>') .')')
                        call add(out, 'call TPluginMenu('. string(mrepo .'.-'. mrepo .'-') .', ":")')
                        let menu_done[repo] = 1
                    endif
                    call add(out, 'call TPluginMenu('. string(mrepo .'.'. mplugin) .', '.
                                \ string(':TPlugin! '. repo .' '. plugin .'<cr>') .')')
                endif

                let out += s:ScanSource(repo, plugin, what, readfile(file))
            endfor
        finally
            if progressbar
                call tlib#progressbar#Restore()
            else
                redraw
                echo
            endif
        endtry

        " TLogVAR out
        let outfile = join([root, 'tplugin.vim'], '/')
        call writefile(out, outfile)
        if a:immediate
            exec 'source '. fnameescape(outfile)
        endif

    endfor
endf


function! TPluginMenu(item, cmd) "{{{3
    if !empty(g:tplugin_menu_prefix)
        exec 'amenu '. g:tplugin_menu_prefix . a:item .' '. a:cmd
    endif
endf


function! s:SetRoot(dir) "{{{3
    let root = substitute(fnamemodify(a:dir, ':p'), '[\/]\+$', '', '') |
    let root = substitute(root, '\\', '/', 'g')
    let idx = index(s:roots, root)
    if idx > 0
        call remove(s:roots, idx)
    endif
    if idx != 0
        call insert(s:roots, root)
    endif
    " Don't reload the file. Old autoload definitions won't be 
    " overwritten anyway.
    if idx == -1 && g:tplugin_autoload
        let autoload = join([root, 'tplugin.vim'], '/')
        if filereadable(autoload)
            exec 'source '. fnameescape(autoload)
        endif
    endif
endf


function! s:AddRepo(repos) "{{{3
    " TLogVAR a:repos
    let rtp = split(&rtp, ',')
    let idx = index(rtp, s:rtp[0])
    if idx == -1
        let idx = 1
    else
        let idx += 1
    endif
    let repos = filter(copy(a:repos), '!has_key(s:done, v:val)')
    if !empty(repos)
        for repo in repos
            let tplugin_repo = fnamemodify(repo, ':h') .'/tplugin_'. fnamemodify(repo, ':t') .'.vim'
            " TLogVAR repo, tplugin_repo
            exec 'silent! source '. fnameescape(tplugin_repo)
            " TLogVAR repo
            call insert(rtp, repo, idx)
            call insert(rtp, join([repo, 'after'], '/'), -1)
            " TLogVAR rtp
            let s:done[repo] = {}
        endfor
        let &rtp = join(rtp, ',')
    endif
endf


function! s:LoadPlugins(repo, plugins) "{{{3
    if empty(a:plugins)
        return
    endif
    " TLogVAR a:repo, a:plugins
    let done = s:done[a:repo]
    let pos0 = len(a:repo) + 1
    for plugin in a:plugins
        " TLogVAR plugin
        if !has_key(done, plugin)
            let done[plugin] = 1
            " TLogVAR plugin
            if filereadable(plugin)
                let before = filter(keys(s:before), 'plugin =~ v:val')
                if !empty(before)
                    call s:Depend(a:repo, before, s:before)
                endif
                " TLogDBG 'source '. plugin
                exec 'source '. fnameescape(plugin)
                " TLogDBG 'runtime! after/'. strpart(plugin, pos0)
                exec 'runtime! after/'. fnameescape(strpart(plugin, pos0))
                let after = filter(keys(s:after), 'plugin =~ v:val')
                if !empty(after)
                    call s:Depend(a:repo, after, s:after)
                endif
            endif
        endif
    endfor
endf


function! s:Depend(repo, filename_rxs, dict) "{{{3
    " TLogVAR a:filename_rxs
    for filename_rx in a:filename_rxs
        let others = a:dict[filename_rx]
        " TLogVAR others
        for other in others
            if stridx(other, '*') != -1
                let files = split(glob(a:repo .'/'. other), '\n')
            else
                let files = [a:repo .'/'. other]
            endif
            call s:LoadPlugins(a:repo, files)
        endfor
    endfor
endf


function! s:Process() "{{{3
    " TLogDBG "Plugin:Process"
    call s:AddRepo(keys(s:reg))
    if !empty(s:reg)
        " TLogVAR &rtp
        for [repo, plugins] in items(s:reg)
            call s:LoadPlugins(repo, plugins)
        endfor
    endif
    let s:immediate = 1
endf


" :nodoc:
function! TPlugin(immediate, root, repo, ...) "{{{3
    " TLogVAR a:immediate, a:root, a:repo, a:000
    if a:repo == '.'
        let repo = a:root
    else
        let root = empty(a:root) ? s:roots[0] : a:root
        let repo = join([root, a:repo], '/')
    endif
    " TLogVAR repo
    if a:repo =~ '[\/]'
        let pdir = repo
    else
        let pdir = join([repo, 'plugin'], '/')
    endif
    " TLogVAR a:repo, repo, pdir, a:000
    if empty(a:000)
        " TLogDBG join([pdir, '*.vim'], '/')
        let plugins = split(glob(join([pdir, '*.vim'], '/')), '\n')
    elseif a:1 == '.'
        let plugins = []
    else
        let plugins = map(copy(a:000), 'join([pdir, v:val .".vim"], "/")')
    endif
    " TLogVAR plugins
    if s:immediate || a:immediate
        " TLogVAR repo, plugins
        call s:AddRepo([repo])
        call s:LoadPlugins(repo, plugins)
    else
        if !has_key(s:reg, repo)
            let s:reg[repo] = []
        endif
        let s:reg[repo] += plugins
    end
endf


function! s:TPluginComplete(ArgLead, CmdLine, CursorPos) "{{{3
    " TLogVAR a:ArgLead, a:CmdLine, a:CursorPos
    let repo = matchstr(a:CmdLine, '\<TPlugin\s\+\zs\(\S\+\)\ze\s')
    " TLogVAR repo
    let rv = []
    " for root in s:roots
    let root = s:roots[0]
    " TLogVAR root
    if empty(repo)
        let pos0 = len(root) + 1
        let files = split(glob(join([root, '*'], '/')), '\n')
        call map(files, 'strpart(v:val, pos0)')
        call filter(files, 'stridx(v:val, a:ArgLead) != -1')
        " TLogVAR files
    else
        let pdir = join([repo, 'plugin'], '/')
        let dir = join([root, pdir], '/')
        let pos0 = len(dir) + 1
        let files = split(glob(join([dir, '*.vim'], '/')), '\n')
        call map(files, 'strpart(v:val, pos0, len(v:val) - pos0 - 4)')
        call filter(files, 'stridx(v:val, a:ArgLead) != -1')
        " TLogVAR files
    endif
    let rv += files
    " endfor
    " TLogVAR rv
    return rv
endf


" :display: :TPlugin[!] REPOSITORY [PLUGINS ...]
" Register certain plugins for being sourced at |VimEnter| time.
" See |tplugin.txt| for details.
"
" With the optional '!', the plugin will be loaded immediately.
" In interactive use, i.e. once vim was loaded, plugins will be loaded 
" immediately anyway.
"
" IF REPOSITORY contains a slash or a backslash, it is considered the 
" path relative from the current root directory to the plugin directory. 
" This allows you to deal with repositories with a non-standard 
" directory layout. Otherwise it is assumed that the source files are 
" located in the "plugin" subdirectory.
command! -bang -nargs=+ -complete=customlist,s:TPluginComplete TPlugin
            \ call TPlugin(!empty("<bang>"), '', <f-args>)


" :display: :TPluginRoot DIRECTORY
" Define the root directory for the following |:TPlugin| commands.
" Read autoload information if available (see |g:tplugin_autoload| and 
" |:TPluginScan|).
command! -nargs=1 -complete=dir TPluginRoot call s:SetRoot(<q-args>)



" :display: :TPluginBefore FILE_RX [FILE_PATTERNS ...]
" Load DEPENDENCIES before loading a file matching the regexp pattern 
" FILE_RX.
"
" The files matching FILE_PATTERNS are loaded after the repo's path is 
" added to the 'runtimepath'. You can thus use partial filenames as you 
" would use for the |:runtime| command.
"
" This command should be best put into ROOT/tplugin_REPO.vim files, 
" which are loaded when enabling a source repository.
"
" Example: >
"   " Load master.vim before loading any plugin in a repo
"   TPluginBefore plugin/*.vim plugin/master.vim
command! -nargs=+ TPluginBefore
            \ let s:before[[<f-args>][0]] = [<f-args>][1:-1]


" :display: :TPluginAfter FILE_RX [OTHER_PLUGINS ...]
" Load OTHER_PLUGINS after loading a file matching the regexp pattern 
" FILE_RX.
" See also |:TPluginBefore|.
"
" Example: >
"   " Load auxiliary plugins after loading master.vim
"   TPluginAfter plugin/master.vim plugin/sub_*.vim
command! -nargs=+ TPluginAfter
            \ let s:after[[<f-args>][0]] = [<f-args>][1:-1]


" :display: :TPluginFunction FUNCTION REPOSITORY [PLUGIN]
" Load a certain plugin on demand (aka autoload) when FUNCTION is called 
" for the first time.
command! -nargs=+ TPluginFunction
            \ if g:tplugin_autoload && !exists('*'. [<f-args>][0]) |
            \ call s:RegisterFunction([s:roots[0], <f-args>])
            \ | endif


" :display: :TPluginCommand COMMAND REPOSITORY [PLUGIN]
" Load a certain plugin on demand (aka autoload) when COMMAND is called 
" for the first time. Then call the original command.
"
" For most plugins, |:TPluginScan| will generate the appropriate 
" TPluginCommand commands for you. For some plugins, you'll have to 
" define autocommands yourself in the |vimrc| file.
" 
" Example: >
"   TPluginCommand TSelectBuffer vimtlib tselectbuffer
command! -nargs=+ TPluginCommand
            \ if g:tplugin_autoload && exists(':'. [<f-args>][0]) != 2 |
            \ exec 'command! -bang -range -nargs=* '. [<f-args>][0]
            \ .' call s:Autoload(1, ['. string(s:roots[0]) .', <f-args>], "<lt>bang>", ["<lt>line1>", "<lt>line2>"], <lt>q-args>)'
            \ | endif

" " :display: TPluginMap [MAP_COMMAND, REPOSITORY, [PLUGIN]]
command! -nargs=1 TPluginMap
            \ if g:tplugin_autoload |
            \ call s:Map(s:roots[0], <args>)
            \ | endif


" :display: :TPluginScan[!] [WHAT] [ROOT]
" Scan the current root directory for commands and functions. Save 
" autoload information in "ROOT/tplugin.vim".
"
" Where WHAT is a combination of the following identifiers:
"
"    c ... commands
"    f ... functions
"    p ... <plug> maps
"    a ... autoload
"    t ... filetypes
"    h ... helptags (see also |g:tplugin_helptags|)
"    all ... all of the above
"
" WHAT defaults to |g:tplugin_scan|.
"
" With the optional '!', the autocommands are immediatly usable.
"
" Other than the AsNeeded plugin, tplugin doesn't support the creation 
" of autoload information for maps.
"
" If you collect repositories in one than more directory, I'd suggest to 
" create a special script.
"
" Example: >
"   TPluginRoot dir1
"   TPluginScan
"   TPluginRoot dir2
"   TPluginScan
command! -bang -nargs=* TPluginScan
            \ call s:Scan(!empty("<bang>"), s:roots, [<f-args>])


if exists('loaded_tplugin')

    if g:tplugin_autoload
        augroup TPlugin
            autocmd FuncUndefined * call s:AutoloadFunction(expand("<afile>"))
            autocmd FileType * if has_key(s:ftypes, &ft) | call s:Filetype(&ft) | endif
        augroup END
    endif

else

    echoerr 'Load macros/tplugin.vim before using this file'

endif


call s:SetRoot(s:Join([s:rtp[0], 'repos']))


let &cpo = s:save_cpo
unlet s:save_cpo
finish

0.1
- Initial release

0.2
- Improved command-line completion for :TPlugin
- Experimental autoload for commands and functions (à la AsNeeded)
- The after path is inserted at the second to last position
- When autoload is enabled and g:tplugin_menu_prefix is not empty, build 
a menu with available plugins (NOTE: this is disabled by default)

0.3
- Build helptags during :TPluginScan (i.e. support for helptags requires 
autoload to be enabled)
- Call delcommand before autoloading a plugin because of an unknown 
command
- TPluginScan: Take a root directory as the second optional argument
- The autoload file was renamed to ROOT/tplugin.vim
- When adding a repository to &rtp, ROOT/tplugin_REPO.vim is loaded
- TPluginBefore, TPluginAfter commands to define inter-repo dependencies
- Support for autoloading <plug> maps
- Support for autoloading filetypes

0.4
- Moved autoload functions to macros/tplugin.vim -- users have to rescan 
their repos.
- Fixed concatenation of filetype-related files

