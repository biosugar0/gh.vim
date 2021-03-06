" pulls
" Author: skanehira
" License: MIT

function! s:set_pull_list(resp) abort
  nnoremap <buffer> <silent> <Plug>(gh_pull_list_next) :<C-u>call <SID>pull_list_change_page('+')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_pull_list_prev) :<C-u>call <SID>pull_list_change_page('-')<CR>
  nmap <buffer> <silent> <C-l> <Plug>(gh_pull_list_next)
  nmap <buffer> <silent> <C-h> <Plug>(gh_pull_list_prev)

  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found pull requests')
    return
  endif

  let lines = []
  let b:pulls = []
  let url = printf('https://github.com/%s/%s/pull/', b:pull_list.repo.owner, b:pull_list.repo.name)

  let dict = map(copy(a:resp.body), {_, v -> {
        \ 'number': printf('#%s', v.number),
        \ 'state': v.state,
        \ 'user': printf('@%s', v.user.login),
        \ 'title': v.title,
        \ }})
  let format = gh#gh#dict_format(dict, ['number', 'state', 'user', 'title'])

  for pr in a:resp.body
    call add(lines, printf(format,
          \ printf('#%s', pr.number), pr.state, printf('@%s', pr.user.login), pr.title))
    call add(b:pulls, {
          \ 'number': pr.number,
          \ 'url': url . pr.number,
          \ })
  endfor

  call setbufline(b:gh_pulls_list_bufid, 1, lines)

  nnoremap <buffer> <silent> <Plug>(gh_pull_open_browser) :<C-u>call <SID>pull_open()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_pull_diff) :<C-u>call <SID>open_pull_diff()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_pull_url_yank) :<C-u>call <SID>gh_pull_url_yank()<CR>
  nmap <buffer> <silent> <C-o> <Plug>(gh_pull_open_browser)
  nmap <buffer> <silent> ghd <Plug>(gh_pull_diff)
  nmap <buffer> <silent> ghy <Plug>(gh_pull_url_yank)
endfunction

function! s:gh_pull_url_yank() abort
  let url = b:pulls[line('.') -1].url
  call gh#gh#yank(url)
  call gh#gh#message('copied ' .. url)
endfunction

function! s:pull_list_change_page(op) abort
  if a:op is# '+'
    let b:pull_list.param.page += 1
  else
    if b:pull_list.param.page < 2
      return
    endif
    let b:pull_list.param.page -= 1
  endif

  let cmd = printf('vnew gh://%s/%s/pulls?%s',
        \ b:pull_list.repo.owner, b:pull_list.repo.name, gh#http#encode_param(b:pull_list.param))
  call gh#gh#delete_buffer(b:, 'gh_pulls_list_bufid')
  call execute(cmd)
endfunction

function! s:pull_open() abort
  call gh#gh#open_url(b:pulls[line('.')-1].url)
endfunction

function! gh#pulls#list() abort
  setlocal ft=gh-pulls
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls?*\(.*\)')

  let b:gh_pulls_list_bufid = bufnr()

  let param = gh#http#decode_param(m[3])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let b:pull_list = {
        \ 'repo': {
        \   'owner': m[1],
        \   'name': m[2],
        \ },
        \ 'param': param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#pulls#list(b:pull_list.repo.owner, b:pull_list.repo.name, b:pull_list.param)
        \.then(function('s:set_pull_list'))
        \.then({-> gh#map#apply('gh-buffer-pull-list', s:gh_pulls_list_bufid)})
        \.catch({err -> execute('call gh#gh#set_message_buf(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:open_pull_diff() abort
  let number = b:pulls[line('.')-1].number
  call execute(printf('belowright vnew gh://%s/%s/pulls/%s/diff',
        \ b:pull_list.repo.owner, b:pull_list.repo.name, number))
endfunction

function! s:set_diff_contents(resp) abort
  call setbufline(b:gh_preview_diff_bufid, 1, split(a:resp.body, "\r"))
  setlocal buftype=nofile
  setlocal ft=diff
endfunction

function! gh#pulls#diff() abort
  let b:gh_preview_diff_bufid = bufnr()

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls/\(.*\)/diff$')
  call gh#github#pulls#diff(m[1], m[2], m[3])
        \.then(function('s:set_diff_contents'))
        \.then({-> gh#map#apply('gh-buffer-pull-diff', b:gh_preview_diff_bufid)})
        \.catch({err -> execute('call gh#gh#set_message_buf(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

