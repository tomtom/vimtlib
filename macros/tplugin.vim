" plugin.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-04.
" @Last Change: 2010-01-05.
" @Revision:    0.0.119

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:tplugin_helptags')
    " If non-nil, optionally generate helptags for the repository's doc 
    " subdirectory.
    let g:tplugin_helptags = 1   "{{{2
endif


function! s:Join(filename_parts) "{{{3
    let parts = map(copy(a:filename_parts), 'substitute(v:val, ''[\/]\+$'', "", "")')
    return join(parts, '/')
endf


let s:dir = s:Join([split(&rtp, ',')[0], 'repos'])
let s:rtp = split(&rtp, ',')
let s:reg = {}
let s:done = {}
let s:immediate = 0


augroup TPlugin
    autocmd!
    autocmd VimEnter * call s:Process()
augroup END


function! s:AddRepo(repos) "{{{3
    let rtp = split(&rtp, ',')
    let idx = index(rtp, s:rtp[0])
    if idx == -1
        let idx = 1
    else
        let idx += 1
    endif
    let repos = filter(copy(a:repos), '!has_key(s:done, v:val)')
    let rtp += map(copy(repos), "s:Join([v:val, 'after'])")
    for repo in repos
        call insert(rtp, repo, idx)
        if g:tplugin_helptags
            let doc = s:Join([repo, 'doc'])
            if !filereadable(s:Join([doc, 'tags']))
                if isdirectory(doc)
                    exec 'helptags '. fnameescape(doc)
                endif
            endif
        endif
        let s:done[repo] = 1
    endfor
    let &rtp = join(rtp, ',')
endf


function! s:Enable(repo, plugins) "{{{3
    let pos0 = len(a:repo) + 1
    for plugin in a:plugins
        " TLogVAR plugin
        if filereadable(plugin)
            " TLogDBG 'source '. plugin
            exec 'source '. fnameescape(plugin)
            " TLogDBG 'runtime! after/'. strpart(plugin, pos0)
            exec 'runtime! after/'. fnameescape(strpart(plugin, pos0))
        endif
    endfor
endf


function! s:Process() "{{{3
    " TLogDBG "Plugin:Process"
    call s:AddRepo(keys(s:reg))
    if !empty(s:reg)
        " TLogVAR &rtp
        for [repo, plugins] in items(s:reg)
            call s:Enable(repo, plugins)
        endfor
    endif
    let s:immediate = 1
endf


function! s:Plugin(immediate, repo, ...) "{{{3
    let repo = s:Join([s:dir, a:repo])
    if empty(a:000)
        let plugins = split(glob(s:Join([repo, 'plugin', '*.vim']), 1), '\n')
    else
        let plugins = map(copy(a:000), 's:Join([repo, "plugin", v:val .".vim"])')
    endif
    if s:immediate || a:immediate
        call s:AddRepo([repo])
        call s:Enable(repo, plugins)
    else
        if !has_key(s:reg, repo)
            let s:reg[repo] = []
        endif
        let s:reg[repo] += plugins
    end
endf


function! s:TPluginComplete(ArgLead, CmdLine, CursorPos) "{{{3
    let pos0 = len(s:dir) + 1
    let files = split(glob(s:Join([s:dir, a:ArgLead .'*'])), '\n')
    call map(files, 'strpart(v:val, pos0)')
    return files
endf


" :display: :TPlugin[!] REPOSITORY [PLUGINS ...]
" Register certain plugins for being sourced at |VimEnter| time.
" See |tplugin.txt| for details.
" With the optional '!', the plugin will be loaded immediately.
" In interactive use, i.e. once vim was loaded, plugins will be loaded 
" immediately anyway.
command! -bang -nargs=+ -complete=customlist,s:TPluginComplete TPlugin
            \ call s:Plugin(!empty("<bang>"), <f-args>)


" :display: :TPluginRoot DIRECTORY
" Define the root directory for the following |:TPlugin| commands.
command! -nargs=1 -complete=dir TPluginRoot
            \ let s:dir = substitute(fnamemodify(<q-args>, ':p'), '[\/]\+$', '', '')


let &cpo = s:save_cpo
unlet s:save_cpo
