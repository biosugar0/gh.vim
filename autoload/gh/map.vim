" map
" Author: skanehira
" License: MIT

let s:buffers = {}

function! gh#map#init() abort
  let s:buffers = {
      \ 'gh-buffer-issue-list': [],
      \ 'gh-buffer-issue-edit': [],
      \ 'gh-buffer-issue-new': [],
      \ 'gh-buffer-issue-comment-list': [],
      \ 'gh-buffer-issue-comment-new': [],
      \ 'gh-buffer-issue-comment-edit': [],
      \ 'gh-buffer-pull-list': [],
      \ 'gh-buffer-pull-diff': [],
      \ 'gh-buffer-repo-list': [],
      \ 'gh-buffer-repo-new': [],
      \ 'gh-buffer-repo-readme': [],
      \ 'gh-buffer-project-list': [],
      \ 'gh-buffer-project-column-list': [],
      \ 'gh-buffer-action-list': [],
      \ 'gh-buffer-file-list': [],
      \ }
endfunction

function! gh#map#apply(buffer, bufid) abort
  for m in s:buffers[a:buffer]
    exe printf('%dbufdo %s', a:bufid, m)
  endfor
endfunction

function! gh#map#add(buffer, mode, lhs, rhs) abort
  if !exists('s:buffers[a:buffer]')
    call gh#gh#error_message(printf('invalid buffer type: %s, please read :h gh-buffer', a:buffer))
    return
  endif
  let s:buffers[a:buffer] += [printf('%s <buffer> <silent> %s %s', a:mode, a:lhs, a:rhs)]
endfunction
