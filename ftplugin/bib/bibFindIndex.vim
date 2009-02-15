" bibFindIndex.vim -- Jump to an index
" @Author:      Tom Link (micathom AT gmail com?subject=vim)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     06-Feb-2004.
" @Last Change: 2009-02-15.
" @Revision:    0.1.67

if exists("b:did_ftplugin_bibFindIndex")
    finish
endif
let b:did_ftplugin_bibFindIndex = 1

if !exists(":BibGotoIndex")
    fun! s:BibGotoIndex(text, delta)
        let txt  = a:text
        let i    = strlen(a:text) - 1
        let f    = 0
        let chrs = "-:0123456789abcdefghijklmnopqrstuvwxyz"
        if exists("g:bibFindIndexAllowSpaces") && g:bibFindIndexAllowSpaces
            let pre = '\c^@\s*\(\w\+\)\s*{\s*'
        else
            let pre = '\c^@\(\w\+\){'
        endif
        go 1
        while !f && i >= 0
            let tc = a:text[i]
            let lc = strpart(chrs, stridx(chrs, tc) + a:delta)
            if lc == ""
                let i = i - 1
                continue
            else
                let lc = '['. lc .']'
            endif
            let txt = strpart(a:text, 0, i) . lc
            while 1
                let f = search(pre.txt)
                if f == 0
                    break
                else
                    let l = getline('.')
                    let s = substitute(l, pre .'.*$', '\1', '')
                    if s != l && s != ''
                        if s != 'string'
                            break
                        end
                    else
                        echom 'BibGotoIndex: Internal error: No match on line '. line('.')
                    endif
                endif
            endwh
            let i   = i - 1
        endwh
        if !f
            norm! G
        endif
    endfun

    command! -nargs=1 BibGotoIndex call s:BibGotoIndex(<q-args>, 0)
    command! -nargs=1 BibGotoNextIndex call s:BibGotoIndex(<q-args>, 1)
endif

if !hasmapto(':BibGotoIndex')
    noremap <buffer> <LocalLeader>g :BibGotoIndex 
endif
if !hasmapto(':BibGotoNextIndex')
    noremap <buffer> <LocalLeader>n :BibGotoNextIndex 
endif

finish

Description:

This is a small ftplugin that helps jumping to a key in a bibtex file. 
It assumes a bibtex file that is alphabethically ordered by the bibitem 
key.

Type <LocalLeader>g and a bibtex-key you want to find.
Type <LocalLeader>n to jump to the next key in line.

Example use:

If the keys in the file were: 
    
    @article{aa,
    ...}
    @article{ab
    ...}
    @article{aba
    ...}
    @article{ac
    ...}

then '<LL>gab<cr>' would take you to "ab" but '<LL>nab<cr>' to "ac". 
Actually BibGotoNextIndex is the main reason for why I wrote this one.

If g:bibFindIndexAllowSpaces is true, the "entry head" may include whitespace. 
(I'm not sure if this is legal bibtex, though.)

