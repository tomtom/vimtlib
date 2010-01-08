" localvariables.vim -- Set/let per-file-variables à la Emacs
" @Author:      Tom Link (micathom AT gmail com)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     08-Dec-2003.
" @Last Change: 2010-01-05.
" @Revision: 2.0.120
" 
" vimscript #853

if &cp || exists("s:loaded_localvariables")
    finish
endif
let s:loaded_localvariables = 1


command! LocalVariablesReCheck call localvariables#ReCheck()
" command! -nargs=1 LocalVariablesRunEventHook call localvariables#RunEventHook(<q-args>)
command! -nargs=1 -bang LocalVariablesRegisterHook call localvariables#RegisterHook(<q-args>, <q-bang>)


finish
CHANGES:
2.0:
- Use sandbox

" vim: ff=unix
