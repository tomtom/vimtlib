" tGpg.vim -- Yet another plugin for encrypting files with gpg
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim-tGpg)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2006-12-31.
" @Last Change: 2010-05-29.
" @Revision:    0.5.944
" GetLatestVimScripts: 1751 1 tGpg.vim
"
" TODO: Remove gpg messages from the top of the file & display them with 
" echom
" TODO: :read doesn't work ('<,'>:write?)
" TODO: test special characters (new template syntax)
" TODO: test multiple recipients
" TODO: passphrase vs multiple recipients?
" TODO: signing & verification (embedded vs detached)
" TODO: save cached values between sessions in a gpg encoded file?


if &cp || exists("loaded_tgpg") "{{{2
    finish
endif
let loaded_tgpg = 5


if !exists('g:tgpg_timeout')
    " Reset cached passwords after N seconds.
    " 1800 ... 30 Minutes
    let g:tgpg_timeout = 1800 "{{{2
endif

if !exists('g:tgpg_dont_reset_rx')
    " Don't reset the keys for filenames matching this |regexp|.
    let g:tgpg_dont_reset_rx = ''  "{{{2
endif

if !exists('g:tgpg_gpg_cmd')
    " The gpg command. Should be a full filename.
    let g:tgpg_gpg_cmd = '/usr/bin/gpg' "{{{2
endif
" if !executable(g:tgpg_gpg_cmd)
"     echom 'tGpg: Not an executable g:tgpg_gpg_cmd='. string(g:tgpg_gpg_cmd)
" endif

if !exists('g:tgpg_gpg_md5_check')
    " The command to calculate the md5 checksum.
    let g:tgpg_gpg_md5_check = 'md5sum '. g:tgpg_gpg_cmd "{{{2
endif

if !exists('g:tgpg_gpg_md5_sum')
    " The known md5 checksum of gpg binary.
    " If empty, the binary's integrity won't be checked.
    let g:tgpg_gpg_md5_sum = '' "{{{2
endif
if empty(g:tgpg_gpg_md5_check) && !empty(g:tgpg_gpg_md5_sum)
    echoerr 'tGpg: g:tgpg_gpg_md5_check is empty but g:tgpg_gpg_md5_sum is set'
endif

if !exists('g:tgpg_options')
    " Set these options during read/write operations.
    let g:tgpg_options = {'verbosefile': '', 'verbose': 0} "{{{2
endif

if !exists('g:tgpg_registers')
    " Reset these registers (eg the clipboard) after leaving/deleting a 
    " gpg encoded buffer.
    let g:tgpg_registers = '"-/_*+' "{{{2
    " .:%#
    " let g:tgpg_registers = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"-/_*+~'
endif

if !exists('g:tgpgCachePW')
    " 2 ... cache passwords
    " 1 ... buffer-wise caching only???
    " 0 ... disable caching
    let g:tgpgCachePW = 2 "{{{2
endif

if !exists('g:tgpgBackup')
    " When writing, make backups (in case something goes wrong).
    let g:tgpgBackup = 1 "{{{2
endif

if !exists('g:tgpgMode')
    " The default run mode. Pre-defined values include:
    " - symmetric (default)
    " - encrypt
    " - clearsign
    " See also |g:tgpgModes|
    let g:tgpgMode = 'symmetric' "{{{2
endif

if !exists('g:tgpgModes')
    " A list of known modes.
    let g:tgpgModes = ['symmetric', 'encrypt', 'clearsign'] "{{{2
    " 'sign'
endif

" :doc:
" -----------------------------------------------------------------------
" Mode definitions~
"
" The template values are returned by functions 
" s:TGpgUserInput_{FIELD}(params).

if !exists('g:tgpgPattern_symmetric')
    let g:tgpgPattern_symmetric = g:tgpgMode == 'symmetric' ? '*.\(gpg\|asc\|pgp\)' : '' "{{{2
endif

if !exists('g:tgpgWrite_symmetric')
    let g:tgpgWrite_symmetric = '!%{GPG} %{G_OPTIONS} %{B_OPTIONS} %{PASSPHRASE} -o %{FILE} -c' "{{{2
    " let g:tgpgWrite_symmetric = '!gpg %{G_OPTIONS} %{B_OPTIONS} %{PASSPHRASE} -c'
endif

if !exists('g:tgpgRead_symmetric')
    let g:tgpgRead_symmetric = '!%{GPG} %{G_OPTIONS} %{B_OPTIONS} %{PASSPHRASE} -d %{FILE}' "{{{2
    " let g:tgpgRead_symmetric = '!gpg %{G_OPTIONS} %{B_OPTIONS} %{PASSPHRASE} -d'
endif

if !exists('g:tgpgPattern_encrypt')
    let g:tgpgPattern_encrypt = g:tgpgMode == 'encrypt' ? '*.\(gpg\|asc\|pgp\)' : '' "{{{2
endif

if !exists('g:tgpgWrite_encrypt')
    let g:tgpgWrite_encrypt = '!%{GPG} %{G_OPTIONS} %{RECIPIENTS} %{B_OPTIONS} -e -o %{FILE}' "{{{2
endif

if !exists('g:tgpgRead_encrypt')
    let g:tgpgRead_encrypt = '!%{GPG} %{G_OPTIONS} %{B_OPTIONS} %{PASSPHRASE} -d %{FILE}' "{{{2
endif

if !exists('g:tgpgPattern_clearsign')
    let g:tgpgPattern_clearsign = '' "{{{2
endif

if !exists('g:tgpgWrite_clearsign')
    let g:tgpgWrite_clearsign = '!%{GPG} %{G_OPTIONS} %{B_OPTIONS} %{PASSPHRASE} -o %{FILE} --clearsign' "{{{2
    " let g:tgpgWrite_clearsign = '!gpg %{G_OPTIONS} %{B_OPTIONS} %{RECIPIENTS} %{PASSPHRASE} -o %{FILE} --clearsign'
endif

" if !exists('g:tgpgRead_clearsign') | let g:tgpgRead_clearsign = '!gpg %{G_OPTIONS} --verify %s' | endif

" if !exists('g:tgpgPattern_sign') | let g:tgpgPattern_sign = '*.\(sig\)' | endif
" if !exists('g:tgpgWrite_sign') | let g:tgpgWrite_sign = '!gpg %{G_OPTIONS} -r %s -s -o %s' | endif
" " if !exists('g:tgpgRead_sign') | let g:tgpgDecrypt = '' | endif

" :doc:
" -----------------------------------------------------------------------
" gpg options~

if !exists('g:tgpgOptions')
    " G_OPTIONS: The default options.
    let g:tgpgOptions = '-q --no-secmem-warning' "{{{2
    " --no-mdc-warning
endif

if !exists('g:tgpgCmdRecipient')
    " RECIPIENTS: How to pass recipients.
    let g:tgpgCmdRecipient = '-r "%s"' "{{{2
endif

if !exists('g:tgpgSepRecipient')
    " Separators the user may use when naming multiple recipients.
    let g:tgpgSepRecipient = ';|/&' "{{{2
endif

if !exists('g:tgpgCmdPassphrase')
    " PASSPHRASE: How to pass the passphrase.
    let g:tgpgCmdPassphrase = '--passphrase "%s"' "{{{2
endif

if !exists('g:tgpgShellQuote')
    " More characters that should be quoted.
    let g:tgpgShellQuote = '&'.&shellxquote "{{{2
endif

if !exists('g:tgpgTempSuffix')
    " The suffix for backups and temporary files.
    let g:tgpgTempSuffix = '.~tGpg~' "{{{2
endif

if !exists('g:tgpgInputsecret')
    " A function to input "secrets".
    let g:tgpgInputsecret = 'inputsecret' "{{{2
    " let g:tgpgInputsecret = 'input'
endif


for s:var in [
            \ 'tgpg_timeout', 'tgpg_gpg_cmd', 'tgpg_gpg_md5_check', 'tgpg_gpg_md5_sum',
            \ 'tgpg_options', 'tgpg_registers', 'tgpg_registers', 'tgpgCachePW',
            \ 'tgpgBackup', 'tgpgInputsecret', 'tgpgOptions', 'tgpgMode',
            \ 'tgpgCmdRecipient', 'tgpgSepRecipient',
            \ 'tgpgCmdPassphrase', 'tgpgShellQuote', 'tgpgTempSuffix',
            \ 'tgpgWrite_symmetric', 'tgpgRead_symmetric',
            \ 'tgpgWrite_encrypt', 'tgpgRead_encrypt',
            \ 'tgpgWrite_clearsign', 'tgpgRead_clearsign',
            \ 'tgpgWrite_sign', 'tgpgRead_sign',
            \ ]
    if exists('g:'. s:var)
        let s:{s:var} = g:{s:var}
        unlet g:{s:var}
    endif
endfor
unlet s:var


let s:rotta = join(map(range(32,126), 'nr2char(v:val)'), '')
let s:rottb = ''
let s:rott_list = split(s:rotta, '\ze')
let s:rott_n = localtime() % 79181
while !empty(s:rott_list)
    let s:rott_n = (97613 * s:rott_n) % 79181
    if s:rott_n < 0
        let s:rott_n = -s:rott_n
    end
    let s:rottb .= remove(s:rott_list, s:rott_n % len(s:rott_list))
endwh
unlet s:rott_list s:rott_n


" :doc:
" -----------------------------------------------------------------------
" Commands and functions~

command! TGpgResetCache if empty(g:tgpg_dont_reset_rx) 
            \ |   let s:heights = {}
            \ | else
            \ |   call filter(s:heights, 'v:key =~ g:tgpg_dont_reset_rx')
            \ | endif
" command! TGpgShowCache echo string(s:heights)
" command! TGpgShowTable echo s:rottb
TGpgResetCache

let s:last_access = 0


function! s:EscapeShellCmdChars(text) "{{{3
    return escape(a:text, '%#'. s:tgpgShellQuote)
endf


function! s:EscapeFilename(file) "{{{3
    return escape(a:file, ' ')
endf


function! s:GetMode(mode) "{{{3
    if empty(a:mode)
        return exists('b:tgpgMode') ? b:tgpgMode : s:tgpgMode
    else
        return a:mode
    endif
endf


function! s:GetRecipients(iomode, default) "{{{3
    " TAssert IsList(a:default)
    call inputsave()
    let user = input('Recipients (seperated by ['.s:tgpgSepRecipient .']): ', join(a:default, s:tgpgSepRecipient[0].' '))
    call inputrestore()
    return split(user, '['. s:tgpgSepRecipient .']\s*')
endf


function! s:FormatRecipients(recipients) "{{{3
    " TAssert IsList(a:recipients)
    let luser = map(copy(a:recipients), 'printf(s:tgpgCmdRecipient, v:val)')
    return join(luser, ' ')
endf


function! s:GetPassphrase(iomode, default) "{{{3
    " TAssert IsString(a:default)
    " TAssert IsExistent('*'.s:tgpgInputsecret)
    call inputsave()
    " call TLog('GetPassphrase default='. a:default)
    echo
    while 1
        let secret = {s:tgpgInputsecret}('Passphrase: ', a:default)
        if secret != '' && secret != a:default && a:iomode ==? 'w' && s:tgpgInputsecret =~? 'inputsecret'
            let secret0 = {s:tgpgInputsecret}('Please retype your passphrase: ', a:default)
            if secret0 != secret
                echo "Passphrases didn't match!"
                continue
            endif
        endif
        break
    endwh
    call inputrestore()
    echo
    return secret
endf


function! s:CacheKey(id, file) "{{{3
    " TAssert IsString(a:id)
    " TAssert IsString(a:file)
    if has('fname_case')
        let file = a:file
    else
        " let file = substitute(a:file, '^\w\+\ze:', '\U&', '')
        let file = tolower(a:file)
    endif
    let rv = a:id .'*'. file
    return rv
endf


function! s:GoHome(value) "{{{3
    return tr(string(a:value), s:rotta, s:rottb)
endf


function! s:ComeHere(text) "{{{3
    " TAssert IsString(a:text)
    return eval(tr(a:text, s:rottb, s:rotta))
endf


function! s:CheckTimeout() "{{{3
    if !empty(s:heights)
        let now = localtime()
        if s:last_access && now - s:last_access > s:tgpg_timeout
            TGpgResetCache
        endif
        let s:last_access = now
    endif
endf


function! s:GetCacheVar(id, file, default) "{{{3
    call s:CheckTimeout()
    let id = s:GoHome(s:CacheKey(a:id, a:file))
    if has_key(s:heights, id)
        let rv = s:ComeHere(s:heights[id])
        " call TLog('GetCacheVar '. id .'='. rv)
        return rv
    else
        " return s:PutCacheVar(a:id, a:file, a:default)
        return a:default
    endif
endf


function! s:UnsetCacheVar(ids, params) "{{{3
    " TLogVAR a:ids, a:params
    let file = a:params['file']
    let mode = a:parms['mode']
    for id in a:ids
        let tid = s:CacheKey(id . mode, file)
        unlet! s:heights[s:GoHome(tid)]
    endfor
endf


function! s:PutCacheVar(id, file, secret) "{{{3
    call s:CheckTimeout()
    let id = s:CacheKey(a:id, a:file)
    let s:heights[s:GoHome(id)] = s:GoHome(a:secret)
    return a:secret
endf


function! s:GetCache(id, file, default) "{{{3
    " TAssert IsString(a:id)
    " let tgpgCachePW = exists('b:tgpgCachePW') ? b:tgpgCachePW : s:tgpgCachePW
    let tgpgCachePW = s:tgpgCachePW
    if tgpgCachePW
        if tgpgCachePW >= 2
            return s:GetCacheVar(a:id, a:file, a:default)
        endif
        if exists('b:tgpgSecret_'. a:id) && !empty(b:tgpgSecret_{a:id})
            return b:tgpgSecret_{a:id}
        endif
    endif
    return a:default
endf


function! s:PutCache(id, file, secret) "{{{3
    " TAssert IsString(a:id)
    " let tgpgCachePW = exists('b:tgpgCachePW') ? b:tgpgCachePW : s:tgpgCachePW
    let tgpgCachePW = s:tgpgCachePW
    if tgpgCachePW && !empty(a:secret)
        if tgpgCachePW >= 2
            call s:PutCacheVar(a:id, a:file, a:secret)
        elseif tgpgCachePW >= 1
            let b:tgpgSecret_{a:id} = a:secret
        endif
    endif
endf


function! s:CallInDestDir(autocommand, file, mode, FunRef, args) "{{{3
    if expand('%:p') != a:file
        let buf = bufnr('%')
        exec 'silent! buffer! '. bufnr(a:file)
    else
        let buf = -1
    endif
    let bin = &bin
    " let pos = getpos('.')
    let view = winsaveview()
    let t   = @t
    let parms = {'autocommand': a:autocommand, 'file': a:file, 'mode': s:GetMode(a:mode), 'pwd': getcwd()}
    try
        if empty(parms['file'])
            let parms['file'] = expand('%:p')
        endif
        " call TLog('file='. parms['file'])
        let parms['hfile'] = fnamemodify(parms['file'], ':p:h')
        let parms['tfile'] = fnamemodify(parms['file'], ':t')
        let parms['gfile'] = parms['tfile'] . s:tgpgTempSuffix
        silent exec 'cd '. s:EscapeShellCmdChars(s:EscapeFilename(parms['hfile']))
        set bin
        set noswapfile
        " set nobackup
        " set nowritebackup
        if !exists('b:tgpgMode')
            let b:tgpgMode = a:mode
        endif
        " set buftype=acwrite
        call call(a:FunRef, [parms] + a:args)
    finally
        let &bin = bin
        let @t   = t
        " call setpos('.', pos)
        call winrestview(view)
        silent exec 'cd '. s:EscapeShellCmdChars(s:EscapeFilename(parms['pwd']))
        if buf != -1
            exec 'silent! buffer! '. buf
        endif
    endtry
endf


function! s:TemplateValue(label) "{{{3
    " call TLog('TemplateValue: success='. s:templateSuccess)
    " TLog 'TemplateValue: '. a:label
    if s:templateSuccess
        if has_key(s:templateValues, a:label)
            " call TLog('TemplateValue => '. s:templateValues[a:label])
            return s:templateValues[a:label]
        endif
        if exists('*s:TGpgUserInput_'. a:label)
            let [s:templateSuccess, rv] = s:TGpgUserInput_{a:label}(s:templateValues)
            " TLog 'TemplateValue* => '. rv
            return rv
        endif
        let s:templateSuccess = 0
    endif
    return ''
endf


function! s:ProcessTemplate(parms, iomode, template, vars) "{{{3
    " TAssert IsDictionary(a:parms)
    " TAssert IsString(a:iomode) && IsNotEmpty(a:iomode)
    " TAssert IsString(a:template) && IsNotEmpty(a:template)
    " TAssert IsDictionary(a:vars)
    let rv = a:template
    let s:templateValues = {'iomode': a:iomode}
    call extend(s:templateValues, a:vars)
    call extend(s:templateValues, a:parms)
    let s:templateSuccess = 1
    " TLog 'Template pre: '. rv
    let rv = substitute(rv, '\C\(^\|[^%]\)\zs%{\([A-Z_]\+\)}', '\=escape(s:TemplateValue(submatch(2)), ''\&'')', 'g')
    unlet s:templateValues
    " TLog 'Template after: '. rv
    if s:templateSuccess
        let rv = substitute(rv, '%%', "%", "g")
    else
        let rv = ''
    endif
    unlet s:templateSuccess
    return rv
endf


function! s:StandardOptions()
    for [key, value] in items(s:tgpg_options)
        " TLogVAR key, value
        let okey = s:GoHome('option_'. key)
        exec 'let s:heights[okey] = &l:'. key
        exec 'let &l:'. key ' = value'
    endfor
endf


function! s:ResetOptions() "{{{3
    for key in keys(s:tgpg_options)
        let okey = s:GoHome('option_'. key)
        if has_key(s:heights, okey)
            exec 'let &l:'. key ' = s:heights[okey]'
            unlet s:heights[okey]
        endif
    endfor
endf


function! s:SaveRegisters() "{{{3
    for reg in split(s:tgpg_registers, '\zs')
        let okey = 'register_'. reg
        exec 'let s:heights[okey] = @'. reg
    endfor
endf


function! s:ResetRegisters() "{{{3
    for reg in split(s:tgpg_registers, '\zs')
        let okey = 'register_'. reg
        if has_key(s:heights, okey)
            exec 'let @'. reg .' = s:heights[okey]'
            unlet s:heights[okey]
        endif
    endfor
endf


function! s:TGpgUserInput_GPG(parms) "{{{3
    if !empty(s:tgpg_gpg_md5_sum) && !empty(s:tgpg_gpg_md5_check)
        let rv = system(s:tgpg_gpg_md5_check)
        let sum = matchstr(rv, '^\w\+')
        if sum != s:tgpg_gpg_md5_sum
            echohl error
            echom 'Wrong Checksum for '. s:tgpg_gpg_cmd .': '. sum .' ('. s:tgpg_gpg_md5_sum .')'
            echohl NONE
            sleep 1
            return [0, '']
        endif
    endif
    return [1, s:tgpg_gpg_cmd]
endf


function! s:TGpgUserInput_G_OPTIONS(parms) "{{{3
    return [1, s:tgpgOptions]
endf


function! s:TGpgUserInput_B_OPTIONS(parms) "{{{3
    let id = a:parms['mode'] .'_'. a:parms['iomode']
    let rv = exists('b:tgpg_'. id .'_options') ? b:{a:id}_options : ''
    return [1, rv]
endf


function! s:TGpgUserInput_PASSPHRASE(parms) "{{{3
    let id  = 'PW_'. a:parms['mode']
    " call TLog('s:TGpgUserInput_PASSPHRASE id='. id)
    " call TLog('s:TGpgUserInput_PASSPHRASE file='. a:parms['file'])
    let default = s:GetCache(id, a:parms['file'], '')
    " call TLog('s:TGpgUserInput_PASSPHRASE default='. default)
    let val = s:GetPassphrase(a:parms['iomode'], default)
    if !empty(val)
        call s:PutCache(id, a:parms['file'], val)
        return [1, printf(s:tgpgCmdPassphrase, val)]
    endif
    return [0, '']
endf


function! s:TGpgUserInput_RECIPIENTS(parms) "{{{3
    let default = s:GetCache('recipients', a:parms['file'], [])
    let recipients = s:GetRecipients(a:parms['iomode'], default)
    if !empty(recipients)
        call s:PutCache('recipients', a:parms['file'], recipients)
        return [1, s:FormatRecipients(recipients)]
    endif
    return [0, '']
endf


function! s:TGpgRead(parms, range) abort "{{{3
    " TLogVAR a:params, a:range
    if !filereadable(a:parms['tfile'])
        return
    endif
    call s:StandardOptions()
    try
        let read = 0
        if exists('s:tgpgRead_'. a:parms['mode'])
            let args = {'FILE': s:EscapeFilename(a:parms['tfile'])}
            " TLogVAR a:parms['tfile']
            let cmd  = s:ProcessTemplate(a:parms, 'r', s:tgpgRead_{a:parms['mode']}, args)
            if !empty(cmd)
                " TLogVAR cmd
                exec a:range . s:EscapeShellCmdChars(cmd)
                call s:SaveRegisters()
                " au BufLeave <buffer> call s:ResetRegisters()
                au BufUnload <buffer> call s:ResetRegisters()
                let read = 1
            endif
        endif
        if !read
            exec a:range .'read '. s:EscapeShellCmdChars(s:EscapeFilename(a:parms['tfile']))
        endif
    " catch
    "     call s:UnsetCacheVar(['PW_'], params)
    finally
        call s:ResetOptions()
    endtry
    let b:tmruExclude = 1
    " TLogVAR &buflisted, bufname('%')
    if a:parms['autocommand'] =~ '^Buf'
        " exec 'doautocmd BufRead '. s:EscapeFilename(expand("%"))
        exec 'doautocmd BufRead '. s:EscapeFilename(expand("%:r"))
    endif
endf


function! s:TGpgWrite(parms) abort "{{{3
    if exists('s:tgpgWrite_'. a:parms['mode'])
        call s:StandardOptions()
        try
            " TLogVAR a:parms['tfile']
            " TLogVAR a:parms['gfile']
            let ftime = getftime(a:parms['tfile'])
            let args = {'FILE': s:EscapeFilename(a:parms['tfile'])}
            let cmd = s:ProcessTemplate(a:parms, 'w', s:tgpgWrite_{a:parms['mode']}, args)
            if !empty(cmd)
                " TLogVAR cmd
                if filereadable(a:parms['tfile'])
                    call rename(a:parms['tfile'], a:parms['gfile'])
                endif
                let foldlevel = &foldlevel
                try
                    setlocal foldlevel=99
                    silent %yank t
                    " TLog "'[,']". cmd
                    exec "'[,']". s:EscapeShellCmdChars(cmd)
                    silent norm! ggdG"tPGdd
                    if filereadable(a:parms['tfile'])
                        if getfsize(a:parms['tfile']) == 0
                            echom 'tGpg: File size is zero -- writing has failed.'
                            if filereadable(a:parms['gfile'])
                                echom 'tGpg: Reverting to old file.'
                                call rename(a:parms['gfile'], a:parms['tfile'])
                            endif
                        else
                            set nomodified
                            if !s:tgpgBackup
                                call delete(a:parms['gfile'])
                            endif
                        endif
                    else
                        echom 'tGpg: Reverting to old file.'
                        call rename(a:parms['gfile'], a:parms['tfile'])
                    endif
                finally
                    let &foldlevel = foldlevel
                endtry
            else
                echom 'tGpg: Aborted!'
            endif
        finally
            call s:ResetOptions()
        endtry
    else
        exec "'[,']write ". s:EscapeShellCmdChars(s:EscapeFilename(a:parms['tfile']))
    endif
endf


function! s:TGpgWrite_clearsign(parms) abort "{{{3
    let iomode = empty(a:parms['autocommand']) ? 'W' : 'w'
    if exists('s:tgpgWrite_'. a:parms['mode'])
        call s:StandardOptions()
        try
            let args = {'FILE': s:EscapeFilename(a:parms['gfile'])}
            let cmd = s:ProcessTemplate(a:parms, iomode, s:tgpgWrite_{a:parms['mode']}, args)
            if !empty(cmd)
                if filereadable(a:parms['gfile'])
                    call delete(a:parms['gfile'])
                endif
                " TLog '%'. cmd
                silent exec '%'. s:EscapeShellCmdChars(cmd)
                " silent exec '0read '. s:EscapeShellCmdChars(s:EscapeFilename(a:parms['gfile']))
                silent exec '%read '. s:EscapeShellCmdChars(s:EscapeFilename(a:parms['gfile']))
                norm! ggdd
                call delete(a:parms['gfile'])
                exec 'write! '. s:EscapeShellCmdChars(s:EscapeFilename(a:parms['tfile']))
            else
                echom 'tGpg: Aborted!'
            endif
        finally
            call s:ResetOptions()
        endtry
    endif
endf


augroup tGpg
    au!
    for s:mode in g:tgpgModes
        if !exists('g:tgpgPattern_'. s:mode)
            continue
        endif

        let s:rcmd = exists('*s:TGpgRead_'. s:mode) ? 's:TGpgRead_'. s:mode : 's:TGpgRead'
        let s:wcmd = exists('*s:TGpgWrite_'. s:mode) ? 's:TGpgWrite_'. s:mode : 's:TGpgWrite'
        let s:gcap = toupper(s:mode[0]).s:mode[1:-1]
        exec 'command! -range=% -nargs=? TGpg'. s:gcap .' call s:CallInDestDir("", <q-args>, "'. s:mode .'", function("'. s:wcmd .'"), [])'

        if empty(g:tgpgPattern_{s:mode})
            continue
        endif
        if exists('s:tgpgRead_'. s:mode)
            " I'm not sure. I never fully understood the difference between BufRead and FileRead.
            " exec 'autocmd BufReadCmd,FileReadCmd '. g:tgpgPattern_{s:mode} .' echom "DBG <afile>"'
            exec 'autocmd BufReadCmd  '. g:tgpgPattern_{s:mode} .' call s:CallInDestDir("BufReadCmd", expand("<afile>:p"), "'. s:mode .'", function("'. s:rcmd .'"), ["%"])'
            exec 'autocmd FileReadCmd '. g:tgpgPattern_{s:mode} .' call s:CallInDestDir("FileReadCmd", expand("<afile>:p"), "'. s:mode .'", function("'. s:rcmd .'"), ["''[,'']"])'
            for m in ['BufReadPre', 'FileReadPre', 'BufReadPost', 'FileReadPost']
                " exec 'autocmd '. m .' '. g:tgpgPattern_{s:mode} .' echom "DBG ". m ." ". escape(expand("<afile>:r"), "%")'
                exec 'autocmd '. m .' '. g:tgpgPattern_{s:mode} .' exec ":doautocmd '. m .'" . expand("<afile>:r")'
            endfor
        endif
        if exists('s:tgpgWrite_'. s:mode)
            exec 'autocmd BufWriteCmd '. g:tgpgPattern_{s:mode} .' call s:CallInDestDir("BufWriteCmd", expand("<afile>:p"), "'. s:mode .'", function("'. s:wcmd .'"), [])'
            exec 'autocmd FileWriteCmd '. g:tgpgPattern_{s:mode} .' call s:CallInDestDir("FileWriteCmd", expand("<afile>:p"), "'. s:mode .'", function("'. s:wcmd .'"), [])'
            for m in ['BufWritePre', 'FileWritePre', 'BufWritePost', 'FileWritePost']
                exec 'autocmd '. m .' '. g:tgpgPattern_{s:mode} .' exec ":doautocmd '. m .'" . expand("<afile>:r")'
            endfor
        endif
    endfor
    unlet s:mode s:rcmd s:wcmd s:gcap

    if s:tgpg_timeout > 0
        autocmd CursorHold,CursorHoldI,FocusGained,FocusLost call s:CheckTimeout()
    endif
augroup END


finish

CHANGE LOG:
0.1
- Initial release

0.2
- Made the cache a script local variable.
- Let user retype passwords when writing a file with a new or changed 
passphrase.
- Display a warning if the size of the output file is 0 & revert to old 
file.
- Keep the original when writing.
- Run BufRead autocommands on filename root after reading the buffer.
- Slightly obscure cached values.

0.3
- Changed command template syntax
- The user is now queried for information only as required by the 
command template
- Changed default value of g:tgpgTempSuffix
- Removed recipients from the clearsign template
- Make sure we're in the right buffer
- Enable buffer local command line options (eg 
b:tgpgWrite_symmetric_*_options)

0.4
- Reset cached passwords after g:tgpg_timeout seconds without access
- If g:tgpg_gpg_md5_sum is set, check gpg's checksum via 
g:tgpg_gpg_md5_check before doing anything.
- The gpg program must be configured via g:tgpg_gpg_cmd.
- Make sure certain options (e.g., verbosefile, verbose) are set to 
predefined values during read/write, see g:tgpg_options.
- Reset registers when unloading the buffer (this should prevent 
information copied to the clipboard to be written to the viminfo file; 
as it may have unintended consequences, you can turn it off by setting 
g:tgpg_registers to '')
- randomized replacement tables for encryption

0.5
- Make configuration variables script-local and delete the global value.
- Make most functions script-local

