" my_tinymode.vim
" @Created:     2008-05-02.
" @Last Change: 2009-11-02.

if &cp || exists("loaded_my_tinymode")
    finish
endif
let loaded_my_tinymode = 1

let s:save_cpo = &cpo
set cpo&vim


" Mode2: cycle through 'cursorline' and 'cursorcolumn', enter mode with
" <Leader>c or <Leader>C
" call tinymode#EnterMap("cucl", "<Leader>c", "c")
call tinymode#EnterMap("cucl", "<Leader>C", "C")
call tinymode#ModeMsg("cucl", "Toggle 'cuc'+'cul' [c/C/o(f)f]")
call tinymode#Map("cucl", "c", "let [&l:cuc,&l:cul] = [&cul,!&cuc]")
call tinymode#Map("cucl", "C", "let [&l:cuc,&l:cul] = [!&cul,&cuc]")
call tinymode#Map("cucl", "f", "setl nocuc nocul")


" Mode4: change window size
call tinymode#EnterMap("winsize", "<C-W>>", ">")
call tinymode#EnterMap("winsize", "<C-W><", "<")
call tinymode#EnterMap("winsize", "<C-W>+", "+")
call tinymode#EnterMap("winsize", "<C-W>-", "-")
call tinymode#ModeMsg("winsize", "Change window size +/-/</>/t/b/w/W")
call tinymode#Map("winsize", ">", "#wincmd >")
call tinymode#Map("winsize", "<", "#wincmd <")
call tinymode#Map("winsize", "+", "#wincmd +")
call tinymode#Map("winsize", "-", "#wincmd -")
call tinymode#Map("winsize", "_", "#wincmd -")
call tinymode#Map("winsize", "t", "#wincmd t")
call tinymode#Map("winsize", "b", "#wincmd b")
call tinymode#Map("winsize", "w", "sil! #wincmd w")
call tinymode#Map("winsize", "W", "sil! #wincmd W")
" keep the mode active when typing digits:
call tinymode#ModeArg("winsize", "owncount", "#")


" tabmode: cycle tab pages, enter mode with "gt" or "gT", keys in the mode:
" "0", "t", "T", "$", type a Normal mode command to leave mode or wait 3 s
call tinymode#EnterMap("tabmode", "gt", "t")
call tinymode#EnterMap("tabmode", "gT", "T")
call tinymode#ModeMsg("tabmode", "Cycle tab pages [0/t/T/$] ([n]ew, [c]lose)", 1)
call tinymode#ModeArg("tabmode", "owncount")
call tinymode#Map("tabmode", "0", "tabfirst")
call tinymode#Map("tabmode", "t", "norm! [N]gt")
call tinymode#Map("tabmode", "T", "norm! [N]gT")
call tinymode#Map("tabmode", "$", "tablast")
" easter eggs
call tinymode#Map("tabmode", "n", "tabnew")
call tinymode#Map("tabmode", "c", "tabclose")



" Move paragraphs

" call tinymode#EnterMap("para_move", "gp")
" call tinymode#ModeMsg("para_move", "Move paragraph: Up/Down/j/k")
" call tinymode#Map("para_move", "j", "call tlib#paragraph#Delete() | silent norm! [N]}}{p")
" call tinymode#Map("para_move", "k", "call tlib#paragraph#Delete() | silent norm! k[N]{p")
" call tinymode#ModeArg("para_move", "owncount", 1) 

call tinymode#EnterMap("para_move", "gp")
call tinymode#ModeMsg("para_move", "Move paragraph: j/k")
call tinymode#Map("para_move", "j", "sil call ParaMove('Down', '[N]')")
call tinymode#Map("para_move", "k", "sil call ParaMove('Up', '[N]')")
call tinymode#ModeArg("para_move", "owncount", 1)

func! ParaMove(direction, count)
   let line1 = nextnonblank(line("'{"))
   let line2 = line("'}")
   let blank_line2 = prevnonblank(line2) != line2
   if a:direction == "Down"
       if line2 == line("$")
           return
       endif
       exec line2
       exec "norm!" a:count."}"
       if prevnonblank(".") == line(".")
           put _
       endif
       exec line1.",".line2."move ."
       '[
   elseif a:direction == "Up"
       if line1 <= 2
           return
       endif
       exec line1 - 1
       exec "norm!" a:count."{"
       if nextnonblank(".") == line(".")
           exec line1.",".line2."move 0"
       else
           exec line1.",".line2."move ."
       endif
       if !blank_line2
           call append(".", "")
       endif
       '[
   endif
endfunc 




let &cpo = s:save_cpo
unlet s:save_cpo
