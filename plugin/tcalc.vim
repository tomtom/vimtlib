" tcalc.vim -- A RPN calculator for vim
" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-10-07.
" @Last Change: 2010-01-03.
" @Revision:    359
" GetLatestVimScripts: 2040 1 tcalc.vim
"
" TODO: Error checks for malformed input
" TODO: Pretty printing (of arrays)
" TODO: Doesn't work: [ 1 2 3 ] ( [ 'Numeric 'Numeric 'Numeric ] ) assert
" TODO: Integrate with some CAS package/library

if &cp || exists("loaded_tcalc") || !has('ruby')
    finish
endif
let loaded_tcalc = 13

let s:save_cpo = &cpo
set cpo&vim


" :display: TCalc[!]
" With !, reset stack & input queue.
command! -bang -nargs=* -bar TCalc call tcalc#Calculator(!empty('<bang>'), <q-args>)

" command! -nargs=* -bar TCalcEval call tcalc#Eval(<q-args>)


let &cpo = s:save_cpo
unlet s:save_cpo

finish
CHANGES:
0.1
- Initial release

0.2
- Arguments were not properly reverted: 12 4 / now yields 3.
- The input will be split into tokens, i.e. you can input "1 2 + <cr>" 
or "1<cr>2<cr>+<cr>". (Command-line completions doesn't work properly 
though.)
- The syntax has slightly changed: "CmdCount,Arg", eg, "y3,a"

0.3
- The swap count argument is increased by one (for conformance with the 
rot command).
- Shortcuts are now RPN expression (elements at the stack can be 
referred to by # (= top element) or #N).
- Removed g:tcalc_reverse_display
- Positions on the stack can be referred to by #N.
- rot works the other way round
- d, dup command
- clear command
- print, hex, HEX, oct, dec, bin, float, format commands
- Removed dependency on tlib
- Variables; ls, vars, let, =, rm commands
- Command line completion for variables and commands

0.4
- COUNT can be "#", in which case the top number on the stack will be 
used (e.g. "3 dup3" is the same as "3 3 dup#")
- Disabled vars, (, ) commands
- Variables are words
- New words can be defined in a forth-like manner ":NAME ... ;"
- Built-in commands get evaluated before any methods.
- Messages can be sent to objects on the stack by "#N,METHOD", e.g. "1 2 
g2 3 #1,<<" yields "[1,2,3]"
- The copyN, cN command now means: push a copy of element N.
- ( ... ) push unprocessed tokens as array
- recapture command (feed an array of unprocessed tokens to the input 
queue)
- if, ifelse commands
- delN, deleteN commands
- Can push strings ("foo bar")
- "Symbols" à la 'foo (actually a string)

0.5
- Minor fix: command regexp

0.6
- Included support for rational and complex numbers
- Included matrix support 
- Syntax for pushing arrays [ a b c ... ]
- New at method to select an item from array-like objects
- Removed shortcut variables.

0.7
- Comments: /* ... */
- New words:
    - assert: Display an error message if the stack doesn't match the 
    assertion.
    - validate: Like assert but push a boolean (the result of the check) 
    on the stack.
    - do: synonym for recapture.
    - source: load a file (see also g:tcalc_dir)
    - require: load a ruby library
    - p: print an object (doesn't do much, but prettyprint seems 
    to have problems)
    - history (useful when using tcalc as stand-alone calculator)
- tcalc.rb can now be used as stand-alone program.

0.8
- Named arguments: args is a synonym for assert but provides for named 
arguments.
- New words: Sequence/seq, map, mmap, plot (a simple ASCII function 
plotter), stack_size, stack_empty?, iqueue_size, iqueue_empty?
- Syntactic sugar for assignments: VALUE -> VAR
- Defined "Array" as a synonym for "group"
- "define" command as alternative to the forth-like syntax for defining 
words
- Dynamic binding of words/variables (the words "begin ... end" 
establish a new scope)
- The stack, the input queue, and the dictionary are accessible like 
words (__STACK__, __IQUEUE__, __WORDS__)
- TCalc and tcalc#Calculator take initial tokens as argument.
- TCalc! with [!] will reset the stack & input queue.
- Completion of partial commands
- Readline-support for CLI mode (--no-curses).
- Simple key handling for the curses-based frontend
- Non-VIM-versons save the history in ~/.tcalc/history.txt
- #VAR,METHOD has slightly changed.
- TCalc syntax file.
- FIX: Command line completion

0.9
- FIX: Curses frontend: Display error messages properly
- FIX: readline support.
- FIX: sort words on completion
- Distribute as zip

0.10
- rm,* ... Remove all words
- If g:tcalc_lines < 0, use fixed window height.
- VIM: use the tcalc window to display plots, lists etc.
- FIX: Nested words

0.11
- New words: all?, any?, array_*, and, or, !=
- Debugger (sort of)
- Curses frontend: Show possible completions; map 127 to backspace, F1 
to 'ls'.
- FIX: Nested blocks & more

0.12
- Force arrity for methods: METHOD@N -> pass the N top items on the 
stack as arguments to method

0.13
- Moved the definition of some variables from plugin/tcalc.vim to 
autoload/tcalc.vim


" - TCalcEval command that evaluates an expression and copies the result 
" to the unnamed "" register.

