" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2009-03-01.
" @Last Change: 2009-03-14.
" @Revision:    124

let s:save_cpo = &cpo
set cpo&vim


function! s:Init(options) "{{{3
    " TLogVAR a:options
    let s:options_initial = {}
    for o in keys(a:options)
        exec 'let s:options_initial[o] = '. o
    endfor
endf


function! spec#speckiller#Reset() "{{{3
    " TLog "SpecKiller: Reset"
    if exists('s:options_initial')
        for o in keys(s:options_initial)
            exec 'let '. o .' = s:options_initial[o]'
        endfor
    endif
endf


" Return the i'th option set.
function! spec#speckiller#OptionSets(options, i) "{{{3
    " TLog "spec#speckiller#OptionSets"
    " TLogVAR a:options, a:i
    if a:i >= len(a:options)
        return 0
    endif
    let options = a:options[a:i]
    if type(options) == 1
        if options == 'vim'
            let options0 = s:OptionsDefault(options)
        elseif options == 'vi'
            let options0 = s:OptionsDefault(options)
        endif
        unlet options
        let options = options0
    endif
    call s:Init(options)
    for [name, value] in items(options)
        exec 'let '. name .' = value'
        " TLog name
    endfor
    return 1
endf


let &cpo = s:save_cpo
unlet s:save_cpo


let s:option_file = expand('<sfile>:p:h') .'/options_default_'. hostname() .'.dat'
let s:option_blacklist = [
            \ 'all',
            \ 'compatible',
            \ 'guifont',
            \ 'modified',
            \ 'termcap',
            \ 'term',
            \ 'ttytype',
            \ 'vim',
            \ ]


function! s:OptionsDefault(...) "{{{3
	if !exists('s:option_default')
		if filereadable(s:option_file)
			exec 'let s:option_default = '. join(readfile(s:option_file, 'b'), "\n")
		else
			let default = '&'. (a:0 >= 1 ? a:1 : 'vim')
			" From: Andy Wokula
			" Date: Mon, 09 Feb 2009 23:56:25 +0100
			" Subject: Re: A few questions(accessing the Vim code in VimL)
			" http://groups.google.com/group/vim_dev/msg/80d91c0a5e2ef4e4?hl=en
			exec "silent normal! :set \<C-A>'\<C-B>\<C-Right>\<C-U>\<Del>let str='\r"
			let optnames = split(str)
			exec "silent normal! :setlocal \<C-A>'\<C-B>\<C-Right>\<C-U>\<Del>let str='\r"
			let optnames_local = split(str)
			let s:option_default = {}
			" TLogVAR &cpo, &viminfo
			for opt in optnames
				if index(s:option_blacklist, opt) == -1
					if index(optnames_local, opt) == -1
						let prefix = '&g:'
						let set = 'set'
					else
						let prefix = '&l:'
						let set = 'setlocal'
					endif
					exec 'let val = '. prefix . opt
					" TLogVAR opt, val
					exec set .' '. opt . default
					exec 'let s:option_default[prefix . opt] = '. prefix . opt
					exec 'let '. prefix . opt .' = val'
				endif
			endfor
			call writefile([string(s:option_default)], s:option_file, 'b')
		endif
	endif
	return s:option_default
endfunc 

