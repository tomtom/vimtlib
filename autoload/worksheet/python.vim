" python.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-02-20.
" @Last Change: 2010-02-21.
" @Revision:    60
"
" EXPERIMENTAL AND HARDLY TESTED

if &cp || !has('python')
    throw "No +python support."
    finish
endif
let s:save_cpo = &cpo
set cpo&vim


let s:prototype = {'syntax': 'python'}


function! s:prototype.Evaluate(lines) dict "{{{3
    let code = join(a:lines, "\n")
    let value = ''
    python <<CODE
sys.stdout = VimWorksheetPrinter()
try:
    try:
        # http://vim.wikia.com/wiki/Evaluate_current_line_using_Python
        # eval(compile('\n'.join(vim.current.range),'<string>','exec'),globals())
        __wks_value__ = repr(repr(eval(vim.eval('code'), globals())))
    except:
        __wks_value__ = ""
        exec vim.eval('code')
    out = str(sys.stdout)
    if out:
        cmd = """let value = join(["%s", %s], "\n")""" %(re.sub('"', '\\"', out), __wks_value__)
    else:
        cmd = """let value = %s""" %(__wks_value__)
    vim.command(cmd)
finally:
    sys.stdout = sys.__stdout__
CODE
    redir END
    return value
endf


function! worksheet#python#InitializeInterpreter(worksheet) "{{{3
    python <<CODE
import vim
import re
class VimWorksheetPrinter:
    def __init__(self):
        self.content = []
    def write(self, string):
        self.content.append(string)
    def __str__(self):
        return "\n".join(self.content)
CODE
endf


function! worksheet#python#InitializeBuffer(worksheet) "{{{3
    call extend(a:worksheet, s:prototype)
    runtime indent/python.vim
    runtime ftplugin/python.vim
endf


let &cpo = s:save_cpo
unlet s:save_cpo
