"
" neovim-ghcid
"
" Author:       Alexis Sellier <http://cloudhead.io>
" Version:      0.1

if exists("g:ghcid_loaded") || &cp || !has('nvim')
  finish
endif
let g:ghcid_loaded = 1

let g:ghcid_lines = 10
let s:ghcid_base_sign_id = 100
let s:ghcid_sign_id = s:ghcid_base_sign_id
let s:ghcid_dummy_sign_id = 99
let s:ghcid_job_id = 0

command! Ghcid     call s:ghcid()
command! GhcidKill call s:ghcid_kill()

sign define ghcid-error text=× texthl=ErrorSign
sign define ghcid-dummy

function! s:ghcid_init()
  exe 'sign' 'place'  s:ghcid_dummy_sign_id  'line=9999' 'name=ghcid-dummy' 'buffer=' . bufnr('%')
endfunction

autocmd BufWritePost,FileChangedShellPost *.hs call s:ghcid_clear_signs()
autocmd TextChanged                       *.hs call s:ghcid_clear_signs()
autocmd BufEnter                          *.hs call s:ghcid_init()

let s:ghcid_error_regexp=
  \   '\s*\([^\t\r\n:]\+\):\(\d\+\):\(\d\+\): error:\r'
  \ . '\s\+\([^\t\r\n:]\+\)'

function! s:ghcid_parse_error(str) abort
  let result = matchlist(a:str, s:ghcid_error_regexp)
  if !len(result)
    return { 'valid': 0 }
  endif

  let file = result[1]
  let lnum = result[2]
  let col  = result[3]
  let text = result[4]

  return { 'type': 'E',
         \ 'valid': 1,
         \ 'filename': expand(file),
         \ 'bufnr': bufnr(expand(file)),
         \ 'lnum': str2nr(lnum),
         \ 'col': str2nr(col),
         \ 'text': text }
endfunction

function! s:ghcid_add_to_qflist(l, e)
  for i in a:l
    if i.lnum == a:e.lnum && i.bufnr == a:e.bufnr
      return
    endif
  endfor
  call add(a:l, a:e)
  call setqflist(a:l)
endfunction

function! s:ghcid_update(ghcid, data) abort
  let error = s:ghcid_parse_error(join(a:data))
  let filename = expand('%:p')
  let qflist = getqflist()

  if error.valid
    call s:ghcid_add_to_qflist(qflist, error)
    let s:ghcid_sign_id += 1
    silent exe "sign"
      \ "place"
      \ s:ghcid_sign_id
      \ "line=" . error.lnum
      \ "name=ghcid-error"
      \ "file=" . error.filename
  endif

  if !empty(matchstr(a:data, "All good"))
    if !a:ghcid.closed
      let a:ghcid.closed = 1
      drop ghcid
      quit
    endif
    echo "Ghcid: OK"
  elseif error.valid && a:ghcid.closed
    let a:ghcid.closed = 0
    bot split ghcid
    execute 'resize' g:ghcid_lines
    normal! G
    wincmd p
  endif
endfunction

function! s:ghcid_clear_signs() abort
  for i in range(s:ghcid_base_sign_id, s:ghcid_sign_id)
    silent exe 'sign' 'unplace' i
  endfor
  cexpr ""
  let s:ghcid_sign_id = s:ghcid_base_sign_id
endfunction

function! s:ghcid() abort
  let command = "ghcid"
  let opts = { 'closed': 0 }

  function! opts.on_exit(id, code)
  endfunction

  function! opts.on_stdout(id, data, event) abort
    call s:ghcid_update(self, a:data)
  endfunction

  below new
  execute 'resize' g:ghcid_lines
  call termopen(command, opts)
  let s:ghcid_job_id = b:terminal_job_id
  file ghcid
  wincmd p
endfunction

function! s:ghcid_kill() abort
  if !empty(bufname('ghcid'))
    silent bwipeout! ghcid
    echo "Ghcid: Killed"
  else
    echo "Ghcid: Not running"
  endif
endfunction
