" tplugin.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-05.
" @Last Change: 2010-01-10.
" @Revision:    0.0.204

let s:save_cpo = &cpo
set cpo&vim


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


let s:functions = {}


function! tplugin#RegisterFunction(def) "{{{3
    let s:functions[a:def[1]] = a:def
endf


" args: A string it type == 1, a list if type == 2
function! tplugin#Autoload(type, def, bang, range, args) "{{{3
    " TLogVAR a:type, a:def, a:bang, a:range, a:args
    let [root, cmd; file] = a:def
    " TLogVAR root, cmd, file
    if len(file) >= 1 && len(file) <= 2
        call call('TPlugin', [1, root] + file)
    else
        echoerr 'Malformed autocommand definition: '. join(a:def)
    endif
    let range = join(filter(copy(a:range), '!empty(v:val)'), ',')
    " TLogDBG range . cmd . a:bang .' '. a:args
    if a:type == 1
        try
            exec range . cmd . a:bang .' '. a:args
        catch /^Vim\%((\a\+)\)\=:E481/
            exec cmd . a:bang .' '. a:args
        endtry
    elseif a:type == 2
    else
        echoerr 'Unsupported type: '. a:type
    endif
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


let s:rx = {
            \ 'c': '^\s*:\?com\%[mand]!\?\s\+\(-\S\+\s\+\)*\zs\w\+',
            \ 'f': '^\s*:\?fu\%[nction]!\?\s\+\zs\(s:\|<SID>\)\@![[:alnum:]#]\+',
            \ }

let s:fmt = {
            \ 'c': 'TPluginCommand %s %s %s',
            \ 'f': 'TPluginFunction %s %s %s',
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
            " let rx = rx[0:2] . substitute(rx[3:-1], '\C\\s', '\\(\\n\\s*\\\\\\s*\\|\\s\\+\\)', 'g')
            let m = matchstr(a:line, rx)
            if !empty(m)
                let fmt = s:fmt[what]
                return printf(fmt, m, a:repo, a:plugin)
            endif
        endif
    endfor
endf


" Write autoload information for all known root directories to 
" "ROOT/.tplugin.vim".
function! tplugin#Scan(immediate, roots, args) "{{{3
    let awhat = get(a:args, 0, '')
    if empty(awhat)
        let what = ['c', 'f']
    elseif awhat == 'all'
        let what = ['c', 'f', 'a']
    else
        let what = split(awhat, '\zs')
    endif
    " TLogVAR what, a:roots

    for root in a:roots

        let out = []
        let files = glob(join([root, '*', 'plugin', '*.vim'], '/'))
        let plugins = files
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
        let outfile = join([root, '.tplugin.vim'], '/')
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
        autocmd TPlugin FuncUndefined * call s:AutoloadFunction(expand("<afile>"))
    endif

else

    echoerr 'Load macros/tplugin.vim before using this file'

endif


let &cpo = s:save_cpo
unlet s:save_cpo
