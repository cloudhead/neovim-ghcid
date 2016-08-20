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
let s:ghcid_error_header = {}

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

let s:ghcid_error_header_regexp=
  \   '^\s*\([^\t\r\n:]\+\):\(\d\+\):\(\d\+\): error:'

let s:ghcid_error_text_regexp=
  \   '\s\+\([^\t\r\n]\+\)'

function! s:ghcid_parse_error_text(str) abort
  let result = matchlist(a:str, s:ghcid_error_text_regexp)
  if !len(result)
    return
  endif
  return result[1]
endfunction

function! s:ghcid_parse_error_header(str) abort
  let result = matchlist(a:str, s:ghcid_error_header_regexp)
  if !len(result)
    return {}
  endif

  let file = result[1]
  let lnum = result[2]
  let col  = result[3]

  return { 'type': 'E',
         \ 'filename': expand(file),
         \ 'bufnr': bufnr(expand(file)),
         \ 'lnum': str2nr(lnum),
         \ 'col': str2nr(col) }
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
  let data = copy(a:data)

  " If we see 'All good', then there are no errors and we
  " can safely close the ghcid window and reset the qflist.
  if !empty(matchstr(join(data), "All good"))
    if bufwinnr('^ghcid$') > 0
      drop ghcid
      quit
    endif
    echo "Ghcid: OK"
    call setqflist([])
  endif

  " Try to parse an error header string. If it succeeds, set the top-level
  " variable to the result.
  let error_header = s:ghcid_error_header
  if empty(error_header)
    while !empty(data)
      let error_header = s:ghcid_parse_error_header(data[0])
      let data = data[1:]

      if !empty(error_header)
        let s:ghcid_error_header = error_header
        break
      endif
    endwhile

    " If we haven't found a header and there is nothing left to parse,
    " there's nothing left to do.
    if empty(error_header) || empty(data)
      return
    endif
  endif

  " Try to parse the error text. If we got to this point, we have
  " an error header and some data left to parse.
  let error_text           = s:ghcid_parse_error_text(join(data))
  let error                = copy(error_header)
  let error.text           = error_text
  let error.valid          = 1
  let s:ghcid_error_header = {}

  let qflist = getqflist()
  call s:ghcid_add_to_qflist(qflist, error)

  " Since we got here, we must have a valid error.
  " Open the ghcid window.
  if bufwinnr('^ghcid$') < 0
    bot split ghcid
    execute 'resize' g:ghcid_lines
    normal! G
    wincmd p
  endif

  silent exe "sign"
    \ "place"
    \ s:ghcid_sign_id
    \ "line=" . error.lnum
    \ "name=ghcid-error"
    \ "file=" . error.filename

  let s:ghcid_sign_id += 1
endfunction

function! s:ghcid_clear_signs() abort
  for i in range(s:ghcid_base_sign_id, s:ghcid_sign_id)
    silent exe 'sign' 'unplace' i
  endfor
  let s:ghcid_sign_id = s:ghcid_base_sign_id
endfunction

function! s:ghcid() abort
  let command = "ghcid"
  let opts = {}

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
  let b = bufnr('^ghcid$')
  if b > 0
    silent exe 'bwipeout!' b
    echo "Ghcid: Killed"
  else
    echo "Ghcid: Not running"
  endif
endfunction
