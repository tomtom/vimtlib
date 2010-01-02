" pim.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=vim)
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     30-Okt-2005.
" @Last Change: 2009-08-04.
" @Revision:    0.1.1071
"
" TODO: :PimDelete
" TODO: :PimArchive, :PimFinish (move to archive) (or always save a copy 
" in the archive and simply delete obsolete entries?)
" TODO: Alarms
" TODO: Keywords, categories (show only certain categories)
" TODO: Sort tasks: date, category, priority
" TODO: Show obsolete tasks, tasks of some categories only ...
" TODO: Sync with palm, pi/ki (in ruby?)
" TODO: Portable PimSortTasks & PimSortDates (or wait for vim7)
" TODO: insert a small calendar in overviews
" TODO: general name pattern for all record types: category.name (use 
" directories instead of file name patterns?)
" TODO: Subcategories/overviews per tags (or simply use grep?)
"
" TEST:
" - events: repeat, multiple dates
"

if &cp || exists("loaded_pim") "{{{2
    finish
endif
if !exists('loaded_viki') "{{{2
    runtime plugin/viki.vim
endif
if !exists("loaded_viki") || loaded_viki < 109 "{{{2
    echoerr "pim.vim requires viki.vim >= 109"
    finish
endif
if !exists('g:loaded_tlib') || g:loaded_tlib < 9
    runtime plugin/02tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 9
        echoerr 'tlib >= 0.9 is required'
        finish
    endif
endif
let loaded_pim = 1

if !exists('g:pimHome') "{{{2
    let g:pimHome = split(&rtp, ',')[0].'/pim/'
endif

function! s:CanonicFilename(fname)
    return substitute(a:fname, '[\/]\+', '/', 'g')
endf

let g:pimHome = s:CanonicFilename(g:pimHome)
if g:pimHome !~ '/$' "{{{2
    let g:pimHome = g:pimHome.'/'
endif

if !exists('g:pimFileSuffix')      | let g:pimFileSuffix = '.pim'    | endif "{{{2
if !exists('g:pimSplit')           | let g:pimSplit = 'split'        | endif "{{{2
if !exists('g:pimNameLength')      | let g:pimNameLength = 0         | endif "{{{2
if !exists('g:pimOutdated')        | let g:pimOutdated = 12 * 60     | endif "{{{2
if !exists('g:pimWarnings')        | let g:pimWarnings = 'il'        | endif "{{{2
if !exists('g:pimTimeZoneShift')   | let g:pimTimeZoneShift = 0      | endif "{{{2
if !exists('g:pimShortDatePrefix') | let g:pimShortDatePrefix = '20' | endif "{{{2
if !exists('g:pimMenuPrefix')      | let g:pimMenuPrefix = 'Plugin.Pim.' | endif "{{{2
if !exists('g:pimDaysPast')        | let g:pimDaysPast = 183         | endif "{{{2
if !exists('g:pimDaysFuture')      | let g:pimDaysFuture = 365       | endif "{{{2

let g:pimExtractline = 0
let g:pimExecAC      = 1
let g:pimDayshift    = 60 * 60 * 24
let g:pimLocale      = g:pimHome . 'locale/'
let g:pimIndex       = g:pimHome . 'index/'
let g:pimTemplates   = g:pimHome . 'templates/'

if !exists('*PimCanonicDate') "{{{2
    " It's up to you how you want to write down your dates, you have to make 
    " sure though, that this function return the date in the form: 
    " YEAR-MONTH-DAY.
    function! PimCanonicDate(date) "{{{3
        if !empty(a:date) && a:date !~ '^\d\d\(\d\d\)\?\(-\d\d\?\(-\d\d\?\)\?\)\?$'
            echohl WarningMsg
            echom 'PIM: Malformed date (should match YEAR-MONTH-DAY): '. a:date
            echohl None
        end
        return a:date
    endf
endif

if !exists('*PimCanonicTime') "{{{2
    " PimCanonicTime(time, ?shift=0)
    function! PimCanonicTime(time, ...) "{{{3
        let shift  = a:0 >= 1 ? a:1 : ''
        let hstart = matchstr(a:time, '^\d\+\ze')
        let mstart = matchstr(a:time, ':\zs\d\+$')
        if hstart == ''
            let hstart = '00'
        endif
        if mstart == ''
            let mstart = '00'
        endif
        if shift != ''
            let hshift = matchstr(shift, '^\d\+')
            let mshift = matchstr(shift, ':\d\+$')
            if hshift != ''
                let hstart = hstart + hshift
            endif
            if mshift != ''
                let mstart = mstart + mshift
            endif
        endif
        if strlen(hstart) == 1
            let hstart = '0'. hstart
        endif
        if strlen(mstart) == 1
            let mstart = '0'. mstart
        endif
        return hstart.':'.mstart
    endf
endif            


""" Autocommands "{{{1
augroup Pim
    autocmd!
    exec 'autocmd BufNewFile '. g:pimHome .'*'. g:pimFileSuffix .' if g:pimExecAC | call pim#NewFile() | endif'
    exec 'autocmd BufRead '.    g:pimHome .'*'. g:pimFileSuffix .' call pim#EditFile()'
    exec 'autocmd BufWritePost '. g:pimHome .'*'. g:pimFileSuffix .' call pim#UpdateIndex()'
    exec 'autocmd BufNewFile,BufRead '. g:pimHome .'*'. g:pimFileSuffix .' call pim#SetBufferMaps()'
    
    exec 'autocmd BufRead '. g:pimHome .'Today'. g:pimFileSuffix .' call pim#BuildOverview(0)'
    exec 'autocmd BufRead '. g:pimHome .'Week'. g:pimFileSuffix .' call pim#BuildOverview(7)'
    exec 'autocmd BufRead '. g:pimHome .'Month'. g:pimFileSuffix .' call pim#BuildOverview(31)'
augroup END

""" Commands "{{{1
call viki#Define('PIM', g:pimHome . 'db', g:pimFileSuffix)
for fn in split(glob(g:pimHome . 'db/*'), '\n')
    if isdirectory(fn)
        call pim#DefClass(fnamemodify(fn, ':t'))
    elseif fnamemodify(fn, ':e') == 'vim'
        exec 'source '. tlib#arg#Ex(fn)
    endif
endfor

command! -bang -narg=? PimToday call pim#Today("<bang>", <q-args>)
command! -bang -narg=? PimWeek  call pim#Week("<bang>", <q-args>)
command! -bang -narg=? PimMonth call pim#Month("<bang>", <q-args>)

command! PimRebuild call pim#Rebuild()

command! PimCleanEntry %s/^.*<+.\{-}+>.*\n//e

if !exists(':PimSortTasks') "{{{2
    command! -range PimSortTasks <line1>,<line2>sort n
endif
if !exists(':PimSortDates') "{{{2
    command! -range PimSortDates <line1>,<line2>sort n
endif

if g:pimMenuPrefix != ''
    exec 'amenu '. g:pimMenuPrefix .'&Today :PimToday<cr>'
    exec 'amenu '. g:pimMenuPrefix .'&Week  :PimWeek<cr>'
    exec 'amenu '. g:pimMenuPrefix .'&Month :PimMonth<cr>'
endif

function! s:CheckVersion(version)
    " let vf = g:pimHome.'VERSION'
    let vf = glob(g:pimHome.'VERSION-*')
    let v  = matchstr(vf, '-\zs\d\+$')
    if v == a:version
        return
    elseif vf != ''
        call delete(vf)
    endif
    if exists('*PimUpdate'. v)
        call PimUpdate{v}()
    endif
    call writefile([], g:pimHome .'VERSION-'. a:version)
endf

call s:CheckVersion(loaded_pim)


finish "{{{1
_____________________________________________________________________________

PIM

Install~
Set g:pimInstallCalendar if you want pim.vim to hook into calender.vim.

Requirements:
    - viki.vim (which requires multvals.vim)

Optional Requirements:
    - calendar.vim (:Calendar)
    - system_utils.vim (:Sort)


Rules~

    Dates :: must have the form YEAR-MONTH-DAY (or redefine 
        PimCanonicDate to return dates in this form)
        
    Times :: must be one of: HOURS, HOURS:MINUTES (hours must be in 24 
        hours mode, no am/pm allowed, or redefine PimCanonicTime to return 
        times as HOURS:MINUTES)


CHANGES
0.1
- Initial release

