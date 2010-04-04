" cache.vim
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-06-30.
" @Last Change: 2010-04-03.
" @Revision:    0.1.119


" |tlib#cache#Purge()|: Remove cache files older than N days.
TLet g:tlib#cache#purge_days = 31

" Purge the cache every N days. Disable automatic purging by setting 
" this value to a negative value.
TLet g:tlib#cache#purge_every_days = 31

" The encoding used for the purge-cache script.
" Default:
" &shell == bash: latin-1
" &shell == cmd.exe: cp850
TLet g:tlib#cache#script_encoding = ''

" Whether to run the directory removal script:
"    0 ... No
"    1 ... Query user
"    2 ... Yes
TLet g:tlib#cache#run_script = 1


" :display: tlib#cache#Dir(?mode = 'bg')
" The default cache directory
function! tlib#cache#Dir(...) "{{{3
    TVarArg ['mode', 'bg']
    let dir = tlib#var#Get('tlib_cache', mode)
    if empty(dir)
        let dir = tlib#file#Join([tlib#dir#MyRuntime(), 'cache'])
    endif
    return dir
endf


" :def: function! tlib#cache#Filename(type, ?file=%, ?mkdir=0)
function! tlib#cache#Filename(type, ...) "{{{3
    " TLogDBG 'bufname='. bufname('.')
    let dir = tlib#cache#Dir()
    if a:0 >= 1 && !empty(a:1)
        let file  = a:1
    else
        if empty(expand('%:t'))
            return ''
        endif
        let file  = expand('%:p')
        let file  = tlib#file#Relative(file, tlib#file#Join([dir, '..']))
    endif
    " TLogVAR file, dir
    let mkdir = a:0 >= 2 ? a:2 : 0
    let file  = substitute(file, '\.\.\|[:&<>]\|//\+\|\\\\\+', '_', 'g')
    let dirs  = [dir, a:type]
    let dirf  = fnamemodify(file, ':h')
    if dirf != '.'
        call add(dirs, dirf)
    endif
    let dir   = tlib#file#Join(dirs)
    " TLogVAR dir
    let dir   = tlib#dir#PlainName(dir)
    " TLogVAR dir
    let file  = fnamemodify(file, ':t')
    " TLogVAR file, dir
    if mkdir && !isdirectory(dir)
        call mkdir(dir, 'p')
    endif
    let cache_file = tlib#file#Join([dir, file])
    " TLogVAR cache_file
    return cache_file
endf


function! tlib#cache#Save(cfile, dictionary) "{{{3
    if !empty(a:cfile)
        " TLogVAR a:dictionary
        call writefile([string(a:dictionary)], a:cfile, 'b')
    endif
endf


function! tlib#cache#Get(cfile) "{{{3
    call tlib#cache#MaybePurge()
    if !empty(a:cfile) && filereadable(a:cfile)
        let val = readfile(a:cfile, 'b')
        return eval(join(val, "\n"))
    else
        return {}
    endif
endf


" Call |tlib#cache#Purge()| if the last purge was done before 
" |g:tlib#cache#purge_every_days|.
function! tlib#cache#MaybePurge() "{{{3
    if g:tlib#cache#purge_every_days < 0
        return
    endif
    let dir = tlib#cache#Dir('g')
    let last_purge = tlib#file#Join([dir, '.last_purge'])
    let last_purge_exists = filereadable(last_purge)
    if last_purge_exists
        let threshold = localtime() - g:tlib#cache#purge_every_days * g:tlib#date#dayshift
        let should_purge = getftime(last_purge) < threshold
    else
        let should_purge = 1
    endif
    if should_purge
        let yn = last_purge_exists ? 'y' : inputdialog("TLib: The cache directory '". dir ."' should be purged of old files.\nDelete files older than ". g:tlib#cache#purge_days ." days now? (yes/NO/edit)")
        if yn =~ '^y\%[es]$'
            call tlib#cache#Purge()
        else
            echohl WarningMsg
            echom "TLib: Please run :call tlib#cache#Purge() to clean up ". dir
            echohl NONE
        endif
    endif
endf


" Delete old files.
function! tlib#cache#Purge() "{{{3
    echohl WarningMsg
    echom "TLib: Delete files older than ". g:tlib#cache#purge_days ." days from ". dir
    echohl NONE
    let threshold = localtime() - g:tlib#cache#purge_days * g:tlib#date#dayshift
    let dir = tlib#cache#Dir('g')
    let files = reverse(split(glob(tlib#file#Join([dir, '**'])), '\n'))
    let deldir = []
    let newer = []
    let msg = []
    for file in files
        if isdirectory(file)
            if empty(filter(copy(newer), 'strpart(v:val, 0, len(file)) ==# file'))
                call add(deldir, file)
            endif
        else
            if getftime(file) < threshold
                if delete(file)
                    call add(msg, "TLib: Could not delete cache file: ". file)
                else
                    " call add(msg, "TLib: Delete cache file: ". file)
                    echo "TLib: Delete cache file: ". file
                endif
            else
                call add(newer, file)
            endif
        endif
    endfor
    if !empty(msg)
        echo join(msg, "\n")
    endif
    if !empty(deldir)
        if &shell =~ 'sh\(\.exe\)\?$'
            let scriptfile = 'deldir.sh'
            let rmdir = 'rm -rf %s'
            let enc = 'latin1'
        else
            let scriptfile = 'deldir.bat'
            let rmdir = 'rmdir /S /Q %s'
            let enc = 'cp850'
        endif
        let enc = tlib#var#Get('tlib#cache#script_encoding', 'g', enc)
        if has('multi_byte') && enc != &enc
            call map(deldir, 'iconv(v:val, &enc, enc)')
        endif
        let scriptfile = tlib#file#Join([dir, scriptfile])
        if filereadable(scriptfile)
            let script = readfile(scriptfile)
        else
            let script = []
        endif
        let script += map(copy(deldir), 'printf(rmdir, shellescape(v:val, 1))')
        let script = tlib#list#Uniq(script)
        call writefile(script, scriptfile)
        call inputsave()
        if g:tlib#cache#run_script == 0
            echohl WarningMsg
            echom "TLib: Please review and execute ". scriptfile
            echohl NONE
        else
            try
                let yn = g:tlib#cache#run_script == 2 ? 'y' : inputdialog("TLib: Could not delete some directories.\nDirectory removal script: ". scriptfile ."\nRun script to delete directories now? (yes/NO/edit)")
                if yn =~ '^y\%[es]$'
                    exec 'cd '. fnameescape(dir)
                    exec '! '. shellescape(scriptfile, 1)
                    exec 'cd -'
                    call delete(scriptfile)
                elseif yn =~ '^e\%[dit]$'
                    exec 'edit '. fnameescape(scriptfile)
                endif
            finally
                call inputrestore()
            endtry
        endif
    endif
    let last_purge = tlib#file#Join([dir, '.last_purge'])
    call writefile([], last_purge)
endf

