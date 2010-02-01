" plugin.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-04.
" @Last Change: 2010-02-01.
" @Revision:    819
" GetLatestVimScripts: 2917 1 :AutoInstall: tplugin.vim

if &cp || exists("loaded_tplugin")
    finish
endif
let loaded_tplugin = 5

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:tplugin_autoload')
    " Enable autoloading. See |:TPluginScan|, |:TPluginCommand|, and 
    " |:TPluginFunction|.
    " Values:
    "   1 ... Enable autoload (default)
    "   2 ... Enable autoload and automatically run |:TPluginScan| 
    "         after updating tplugin.
    let g:tplugin_autoload = 1   "{{{2
endif


if !exists('g:tplugin_autoload_exclude')
    " A list of repositories for which autoload is disabled when running 
    " |:TPluginScan|.
    let g:tplugin_autoload_exclude = []   "{{{2
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


function! s:RegisterFunction(def) "{{{3
    " TLogVAR a:def
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


" :nodoc:
function! TPluginFiletype(filetype, repos) "{{{3
    if !has_key(s:ftypes, a:filetype)
        let s:ftypes[a:filetype] = []
    endif
    let repos = map(copy(a:repos), 's:roots[0] ."/". v:val')
    call extend(s:ftypes[a:filetype], repos)
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
    " call tlog#Debug(has_key(s:functions, a:fn))
    " call tlog#Debug(string(keys(s:functions)))
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


" :display: TPluginMap(map, repo, plugin, ?remap="")
" MAP is a map command and the map. REPO and PLUGIN are the same as for 
" the |:TPlugin| command.
"
" Examples: >
"   " Map for <plug>Foo:
"   call TPluginMap('map <plug>Foo', 'mylib', 'myplugin')
"
"   " Load the plugin when pressing <f3> and remap the key to an appropriate 
"   " command from the autoloaded plugin:
"   call TPluginMap('map <f3>', 'mylib', 'myplugin', ':Foo<cr>')
function! TPluginMap(map, repo, plugin, ...) "{{{3
    if g:tplugin_autoload
        let remap = a:0 >= 1 ? substitute(a:1, '<', '<lt>', 'g') : ''
        let def   = [s:roots[0], a:repo, a:plugin]
        let keys  = matchstr(a:map, '\c<plug>\w\+$')
        if empty(keys)
            let keys = matchstr(a:map, '\S\+$')
        endif
        if !empty(keys)
            let mode = s:MapMode(a:map)
            try
                let maparg = maparg(keys, mode)
                " TLogVAR maparg
            catch
                let maparg = ""
            endtry
            if empty(maparg)
                exec a:map .' <C-\><C-G>:call <SID>Remap('. join([string(keys), string(a:map), string(remap), string(def)], ',') .')<cr>'
            endif
        endif
    endif
endf


function! s:Remap(keys, map, remap, def) "{{{3
    " TLogVAR a:keys, a:map, a:def, a:remap
    let mode = s:MapMode(a:map)
    exec mode .'unmap '. a:keys
    call call('TPlugin', [1] + a:def)
    if !empty(a:remap)
        " TLogDBG a:map .' '. a:remap
        exec a:map .' '. a:remap
    endif
    let keys = substitute(a:keys, '<\ze\w\+\(-\w\+\)*>', '\\<', 'g')
    let keys = eval('"'. escape(keys, '"') .'"')
    " TLogVAR keys, a:keys
    call feedkeys(keys)
endf


function! s:MapMode(map) "{{{3
    return matchstr(a:map, '\<\([incvoslx]\?\)\ze\(nore\)\?map')
endf


let s:scanner = {
            \ 'c': {
            \   'rx':  '^\s*:\?com\%[mand]!\?\s\+\(-\S\+\s\+\)*\zs\w\+',
            \   'fmt': {'cargs3': 'TPluginCommand %s %s %s'}
            \ },
            \ 'f': {
            \   'rx':  '^\s*:\?fu\%[nction]!\?\s\+\zs\(s:\|<SID>\)\@![^[:space:].]\{-}\ze\s*(',
            \   'fmt': {'cargs3': 'TPluginFunction %s %s %s'}
            \ },
            \ 'p': {
            \   'rx':  '\c^\s*:\?\zs[incvoslx]\?\(nore\)\?map\s\+\(<\(silent\|unique\|buffer\|script\)>\s*\)*<plug>\w\+',
            \   'fmt': {'sargs3': 'call TPluginMap(%s, %s, %s)'}
            \ },
            \ }


function! s:ScanSource(file, repo, plugin, what, lines) "{{{3
    let text = join(a:lines, "\n")
    let text = substitute(text, '\n\s*\\', '', 'g')
    let lines = split(text, '\n')
    let rx = join(filter(map(copy(a:what), 'get(get(s:scanner, v:val, {}), "rx", "")'), '!empty(v:val)'), '\|')
    call filter(lines, 'v:val =~ rx')
    call map(lines, 's:ScanLine(a:file, a:repo, a:plugin, a:what, v:val)')
    call filter(lines, '!empty(v:val)')
    return lines
endf


function! s:ScanLine(file, repo, plugin, what, line) "{{{3
    " TLogVAR a:file, a:repo, a:plugin, a:what, a:line
    if a:file =~ '[\/]'. a:repo .'[\/]autoload[\/]'
        let plugin = '-'
    else
        let plugin = a:plugin
    endif
    for what in a:what
        let scanner = get(s:scanner, what, {})
        if !empty(scanner)
            let m = matchstr(a:line, scanner.rx)
            if !empty(m)
                " TLogVAR m
                if !has_key(s:scan_repo_done, what)
                    let s:scan_repo_done[what] = {}
                endif
                if has_key(s:scan_repo_done[what], m)
                    return ''
                else
                    let s:scan_repo_done[what][m] = 1
                    let fmt = scanner.fmt
                    if has_key(fmt, 'arr1')
                        return printf(fmt.arr1, string([m, a:repo, plugin]))
                    elseif has_key(fmt, 'sargs3')
                        return printf(fmt.sargs3, string(m), string(a:repo), string(plugin))
                    else
                        return printf(fmt.cargs3, escape(m, ' \'), escape(a:repo, ' \'), escape(plugin, ' \'))
                    endif
                endif
            endif
        endif
    endfor
endf


" Write autoload information for all known root directories to 
" "ROOT/tplugin.vim".
function! s:ScanRoots(immediate, roots, args) "{{{3
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

        if !isdirectory(root)
            continue
        endif

        let pos0 = len(root) + 1
        " TLogVAR pos0
        let out = [
                    \ '" This file was generated by TPluginScan.',
                    \ 'if g:tplugin_autoload == 2 && g:loaded_tplugin != '. g:loaded_tplugin .' | throw "TPluginScan:Outdated" | endif'
                    \ ]

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

        let files0 = split(glob(join([root, '**', '*.vim'], '/')), '\n')
        call filter(files0, '!empty(v:val) && v:val !~ ''[\/]\(\.git\|.svn\|CVS\)\([\/]\|$\)''')
        let exclude_rx = '\V'. join(g:tplugin_autoload_exclude, '\|')
        call filter(files0, 'v:val !~ exclude_rx')
        " TLogDBG len(files0)
        " TLogDBG strpart(files0[0], pos0)
        if index(what, 'a') != -1
            let filelist = filter(copy(files0), 'strpart(v:val, pos0) =~ ''^[^\/]\+[\/]\(plugin\|autoload\)[\/].\{-}\.vim$''')
        else
            let filelist = filter(copy(files0), 'strpart(v:val, pos0) =~ ''^[^\/]\+[\/]plugin[\/][^\/]\{-}\.vim$''')
        endif
        " TLogDBG len(filelist)

        let progressbar = exists('g:loaded_tlib')
        if progressbar
            call tlib#progressbar#Init(len(filelist), 'TPluginscan: Scanning '. escape(root, '%') .' %s', 20)
        else
            echo 'TPluginscan: Scanning '. root .' ...'
        endif

        if index(what, 't') != -1
            for ftdetect in filter(copy(files0), 'strpart(v:val, pos0) =~ ''^[^\/]\+[\/]ftdetect[\/][^\/]\{-}\.vim$''')
                call add(out, 'augroup filetypedetect')
                call extend(out, readfile(ftdetect))
                call add(out, 'augroup END')
            endfor

            let ftd = {}

            let ftypes= filter(copy(files0), 'strpart(v:val, pos0) =~ ''^[^\/]\+[\/]\(ftplugin\|ftdetect\|indent\|syntax\)[\/].\{-}\.vim$''')
            " TLogVAR ftypes
            for ftfile in ftypes
                let ft = matchstr(ftfile, '[\/]ftplugin[\/]\zs.\{-}\ze_.\{-}\.vim$')
                if empty(ft)
                    let ft = fnamemodify(ftfile, ':t:r')
                endif
                " TLogVAR ftfile, ft
                if !has_key(ftd, ft)
                    let ftd[ft] = {}
                endif
                let repo = matchstr(ftfile, '^.\{-}\%'. (len(root) + 2) .'c[^\/]\+')
                " TLogVAR ftfile, repo
                let ftd[ft][repo] = 1
            endfor

            " Add ftplugin subdirectories
            for ftplugin in filter(copy(files0), 'strpart(v:val, pos0) =~ ''^[^\/]\+[\/]ftplugin[\/][^\/]\+[\/].\{-}\.vim$''')
                let ftdir = fnamemodify(ftplugin, ':h')
                let ft    = fnamemodify(ftdir, ':t:r')
                if isdirectory(ftdir) && ft != 'ftplugin'
                    " TLogVAR ftplugin, ft, ftdir
                    " TLogDBG has_key(ftd, ft)
                    " TLogDBG isdirectory(ftplugin)
                    if !has_key(ftd, ft)
                        let ftd[ft] = {}
                    endif
                    let repo = matchstr(ftplugin, '^.\{-}\%'. (len(root) + 2) .'c[^\/]\+')
                    " TLogVAR repo
                    let ftd[ft][repo] = 1
                endif
            endfor

            for [ft, repos] in items(ftd)
                " TLogVAR ft, repos
                let repo_names = map(keys(repos), 'strpart(v:val, pos0)')
                call add(out, 'call TPluginFiletype('. string(ft) .', '. string(repo_names) .')')
            endfor
        endif

        let s:scan_repo_done = {}
        try
            let fidx = 0
            let menu_done = {}
            for file in filelist
                " TLogVAR file
                if progressbar
                    let fidx += 1
                    call tlib#progressbar#Display(fidx)
                endif
                let repo   = matchstr(strpart(file, pos0), '^[^\/]\+\ze[\/]')
                let plugin = matchstr(file, '[\/]\zs[^\/]\{-}\ze\.vim$')
                " TLogVAR repo, plugin

                if !empty(g:tplugin_menu_prefix) && strpart(file, pos0) =~ '^[^\/]\+[\/]plugin[\/][^\/]\{-}\.vim$'
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

                let out += s:ScanSource(file, repo, plugin, what, readfile(file))
            endfor
        finally
            unlet s:scan_repo_done
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


" :nodoc:
function! TPluginMenu(item, cmd) "{{{3
    if !empty(g:tplugin_menu_prefix)
        exec 'amenu '. g:tplugin_menu_prefix . a:item .' '. a:cmd
    endif
endf


function! s:CanonicFilename(filename) "{{{3
    let filename = substitute(a:filename, '[\/]\+$', '', '')
    let filename = substitute(filename, '\\', '/', 'g')
    return filename
endf


function! s:SetRoot(dir) "{{{3
    let root = s:CanonicFilename(fnamemodify(a:dir, ':p'))
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
            try
                exec 'source '. fnameescape(autoload)
            catch /^TPluginScan:Outdated$/
                silent call s:ScanRoots(1, s:roots, [])
            catch
                echohl Error
                echom v:exception
                echom "Maybe the problem can be solved by running :TPluginScan"
                echohl NONE
            endtry
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
    " TLogVAR repos, a:repos
    " call tlog#Debug(string(keys(s:done)))
    if !empty(repos)
        for repo in repos
            let tplugin_repo = fnamemodify(repo, ':h') .'/tplugin_'. fnamemodify(repo, ':t') .'.vim'
            " TLogVAR repo, tplugin_repo
            exec 'silent! source '. fnameescape(tplugin_repo)
            let repo_tplugin = fnamemodify(repo, ':h') .'/'. fnamemodify(repo, ':t') .'/tplugin.vim'
            exec 'silent! source '. fnameescape(repo_tplugin)
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
    " TLogVAR done
    if has_key(done, '*')
        return
    endif
    let pos0 = len(a:repo) + 1
    for plugin in a:plugins
        " TLogVAR plugin
        if plugin != '-' && !has_key(done, plugin)
            let done[plugin] = 1
            if filereadable(plugin)
                " TLogVAR plugin
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
    let repo = s:CanonicFilename(repo)
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
        let pos0  = len(root) + 1
        let files = split(glob(join([root, '*'], '/')), '\n')
        call map(files, 'strpart(v:val, pos0)')
        call filter(files, 'stridx(v:val, a:ArgLead) != -1')
        " TLogVAR files
    else
        let pdir  = join([repo, 'plugin'], '/')
        let dir   = join([root, pdir], '/')
        let pos0  = len(dir) + 1
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
"
" IF PLUGIN is "-", the REPOSITORY will be enabled but no plugin will be 
" loaded.
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
            \ call s:ScanRoots(!empty("<bang>"), s:roots, [<f-args>])


call s:SetRoot(s:Join([s:rtp[0], 'repos']))


augroup TPlugin
    autocmd!
    autocmd VimEnter * call s:Process()

    if g:tplugin_autoload
        autocmd FuncUndefined * call s:AutoloadFunction(expand("<afile>"))
        autocmd FileType * if has_key(s:ftypes, &ft) | call s:Filetype(&ft) | endif
    endif

augroup END


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
- :TPluginDisable command
- Replaced :TPluginMap with a function TPluginMap()

0.5
- Support for ftdetect
- Per repo metadata (ROOT/REPO/tplugin.vim)
- FIX: s:ScanRoots(): Remove empty entries from filelist
- Support for ftplugins in directories and named {&FT}_{NAME}.vim
- FIX: Filetype-related problems
- Relaxed the rx for functions
- FIX: Don't load any plugins when autoloading an "autoload function"
- :TPlugin accepts "-" as argument, which means load "NO PLUGIN".
- Speed up :TPluginScan (s:ScanRoots(): run glob() only once, filter file 
contents before passing it to s:ScanSource())
- :TPluginScan: don't use full filenames as arguments for 
TPluginFiletype()
- g:tplugin_autoload_exclude: Exclude repos from autoloading
- Removed :TPluginDisable
- TPluginMap(): Don't map keys if the key already is mapped (via 
maparg())
- If g:tplugin_autoload == 2, run |:TPluginScan| after updating tplugin.
- FIX: Don't add autoload files to the menu.
- FIX: s:ScanLine: Don't create duplicate autoload commands.

