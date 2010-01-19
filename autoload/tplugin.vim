" tplugin.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-05.
" @Last Change: 2010-01-19.
" @Revision:    0.0.399

let s:save_cpo = &cpo
set cpo&vim


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


let s:helptags = []
let s:ftypes = {}
let s:functions = {}


function! tplugin#RegisterFunction(def) "{{{3
    let s:functions[a:def[1]] = a:def
endf


" args: A string it type == 1, a list if type == 2
function! tplugin#Autoload(type, def, bang, range, args) "{{{3
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


function! tplugin#Help(tags) "{{{3
    call add(s:helptags, a:tags)
endf


function! tplugin#Filetype(filetype, repos) "{{{3
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
        call tplugin#Autoload(2, def, '', [], [])
        " Ignored
        return 1
    endif
endf


function! tplugin#Map(root, def) "{{{3
    let [m, repo, plugin] = a:def
    let def = [a:root, repo, plugin]
    let plug = matchstr(m, '\c<plug>\w\+$')
    if !empty(plug)
        exec m .' <C-\><C-G>:call tplugin#Remap('. string(plug) .', '. string(m) .', '. string(def) .')<cr>'
    endif
endf


function! tplugin#Remap(keys, m, def) "{{{3
    " TLogVAR a:keys, a:m, a:def
    let mode = matchstr(a:m, '\<\([incvoslx]\?\)\ze\(nore\)\?map')
    exec mode .'unmap '. a:keys
    call call('TPlugin', [1] + a:def)
    let keys = substitute(a:keys, '<\ze\w\+\(-\w\+\)*>', '\\<', 'g')
    let keys = eval('"'. escape(keys, '"') .'"')
    " TLogVAR keys
    call feedkeys(a:keys)
endf


let s:rx = {
            \ 'c': '^\s*:\?com\%[mand]!\?\s\+\(-\S\+\s\+\)*\zs\w\+',
            \ 'f': '^\s*:\?fu\%[nction]!\?\s\+\zs\(s:\|<SID>\)\@![[:alnum:]#]\+',
            \ 'p': '\c^\s*:\?\zs[incvoslx]\?\(nore\)\?map\s\+\(<\(silent\|unique\|buffer\|script\)>\s*\)*<plug>\w\+',
            \ }

let s:fmt = {
            \ 'c': {'cargs3': 'TPluginCommand %s %s %s'},
            \ 'f': {'cargs3': 'TPluginFunction %s %s %s'},
            \ 'p': {'arr1': 'call tplugin#Map(TPluginGetRoot(), %s)'},
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
function! tplugin#Scan(immediate, roots, args) "{{{3
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
                " call add(out, 'call tplugin#Help('. string(tags) .')')
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
            let filetypes  = glob(join([root, '*', 'syntax', '*.vim'], '/'))
            let filetypes .= glob(join([root, '*', 'indent', '*.vim'], '/'))
            let filetypes .= glob(join([root, '*', 'ftplugin', '*.vim'], '/'))
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
                call add(out, 'call tplugin#Filetype('. string(ft) .','. string(keys(repos)) .')')
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
                        call add(out, 'call tplugin#Menu('. string(mrepo .'.Repository') .', '.
                                    \ string(':TPlugin! '. repo .'<cr>') .')')
                        call add(out, 'call tplugin#Menu('. string(mrepo .'.-'. mrepo .'-') .', ":")')
                        let menu_done[repo] = 1
                    endif
                    call add(out, 'call tplugin#Menu('. string(mrepo .'.'. mplugin) .', '.
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


function! tplugin#Menu(item, cmd) "{{{3
    if !empty(g:tplugin_menu_prefix)
        exec 'amenu '. g:tplugin_menu_prefix . a:item .' '. a:cmd
    endif
endf


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


let &cpo = s:save_cpo
unlet s:save_cpo
