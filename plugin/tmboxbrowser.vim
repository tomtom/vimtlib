" tmboxbrowser.vim
" @Author:      Thomas Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2007-04-21.
" @Last Change: 2007-08-27.
" @Revision:    0.4.76
" GetLatestVimScripts: 1906 1 tmboxbrowser.vim
"
" TODO:
" - Sending e-mails?
" - Handle thunderbird drafts mbox?

if &cp || exists("loaded_tmboxbrowser")
    finish
endif
if !exists('loaded_tlib') || loaded_tlib < 10
    echoerr 'tlib >= 0.10 is required'
    finish
endif
let loaded_tmboxbrowser = 4

exec tlib#var#Let('g:tmboxbrowser_if_no_unread_mails_show_all', 1)

if !exists('g:tmboxbrowser_attachments_dir')
    let g:tmboxbrowser_attachments_dir = resolve(fnamemodify(tempname(), ':p:h'))
endif

if !exists('g:tmboxbrowser_attachments_filter') "{{{2
    let g:tmboxbrowser_attachments_filter = [
                \ '\.jpe\?g$', '\.gif$', '\.png$',
                \ '\.pdf$', '\.od.$',
                \ '\.doc$', '\.xls$'
                \ ]
endif

if !exists('g:tmboxbrowser_decode_base64')
    let g:tmboxbrowser_decode_base64 = '!base64 -i -d %s > %s'
endif
if !exists('g:tmboxbrowser_decode_jpeg')
    " let g:tmboxbrowser_decode_jpeg = '!jave image2ascii %s algorithm=edge_detection > %s'
    let g:tmboxbrowser_decode_jpeg = '!java -jar jave5.jar image2ascii %s algorithm=edge_detection > %s'
endif

if !exists('g:tmboxbrowser_convert_text_html')
    let g:tmboxbrowser_convert_text_html = '!w3m -dump -T text/html'
endif

" if !exists('g:tmboxbrowser_datadir')
"     let g:tmboxbrowser_datadir = fnamemodify(split(&runtimepath, ',')[0], ':p') .'cache_tmbox/'
" endif

if !exists('g:tmboxbrowser_sort')
    " let g:tmboxbrowser_sort = ''
    let g:tmboxbrowser_sort = '-'
endif

if !exists('g:tmboxbrowser_path')
    let g:tmboxbrowser_path = ''
endif

command! -bang -bar -nargs=? -complete=file TMBoxBrowser call tmboxbrowser#TMBoxBrowse("<bang>", <q-args>)
command! -bang -bar TMBoxSelect call tmboxbrowser#TMBoxSelect("<bang>")

