" A ref source for js reference documentation.
" Version: 0.0.1
" Author : pekepekesamurai<pekepekesamurai@gmail.com>
" License: MIT License

let s:save_cpo = &cpo
set cpo&vim

let s:is_win = has('win32') || has('win64') || has('win16')
" config. {{{1
if !exists('g:ref_jsextra_cmd')  " {{{2
  let g:ref_jsextra_cmd =
  \ executable('elinks') ? 'elinks -dump -no-numbering -no-references %s' :
  \ executable('w3m')    ? 'w3m -dump %s' :
  \ executable('links')  ? 'links -dump %s' :
  \ executable('lynx')   ? 'lynx -dump -nonumbers %s' :
  \ ''
endif
" g:ref_jsextra_defines {{{2
" TODO : sample -> help
let g:ref_jsextra_defines = get(g:, 'ref_jsextra_defines', {})
let g:ref_jsextra_complete_head = get(g:, 'ref_jsextra_complete_head', 1)

" constants {{{1
let s:ROOT = expand('<sfile>:p:h:h:h')
let s:STORE = "cache"
let s:DICT = s:STORE . "/dict.json"
let s:REPOS_DEFINE = s:STORE . "/repos_defines.json"
let s:BINDIR = "."
let s:BIN = s:BINDIR . "/parse.js"



let s:source = {'name': 'jsextra'}  " {{{1

function! s:source.available()  " {{{2
  return !empty(g:ref_jsextra_defines)
  \      && len(g:ref_jsextra_cmd)
endfunction



function! s:source.get_body(query)  " {{{2
  let items = self.complete(a:query)
  let size = len(items)
  if size == 1
    return s:filter(s:execute(items[0]))
  elseif size > 1
    let items = filter(items, 'v:val ==# a:query')
    if len(items) == 1
      return s:filter(s:execute(items[0]))
    else
      return join(items, "\n")
    endif
  endif

  throw 'no match: ' . a:query
endfunction



function! s:source.opened(query)  " {{{2
  call s:syntax()
endfunction



function! s:source.complete(query)  " {{{2
  let list = keys(s:get())
  if g:ref_jsextra_complete_head
    return sort(filter(list, 'v:val =~? "^[^.]*" . a:query . "[^.]*$"'))
  endif
  return sort(filter(list, 'v:val =~? "[^.]*" . a:query . "[^.]*$"'))
  " let name = substitute(a:query, '\$', 'jsextra', '')
  " let pre = g:ref_jsextra_path . '/'

  " let list = filter(copy(s:cache()), 'v:val =~# name')
  " if list != []
  "   return list
  " endif
  " return []
endfunction



function! s:source.get_keyword()  " {{{2
  let isk = &l:isk
  setlocal isk& isk+=. isk+=$
  let kwd = expand('<cword>')
  let &l:isk = isk
  let kwd = substitute(kwd, '^\.', '', '')
  return kwd
endfunction



" functions. {{{1
function! s:syntax()  " {{{2
  if exists('b:current_syntax') && b:current_syntax == 'ref-jsextra'
    return
  endif

  syntax clear
  unlet! b:current_syntax

  " TODO
  " syntax include @refJsExtra syntax/javascript.vim
  " syntax region jsextraHereDoc    matchgroup=jsStringStartEnd start=+\n\(var\s\)\@=+ end=+^$+ contains=@refJsExtra
  " syntax region jsextraHereDoc    matchgroup=jsStringStartEnd start=+^\(.*\s=\s\)\@=+ end=+^$+ contains=@refJsExtra

  syntax region jsextrarefKeyword  matchgroup=jsextrarefKeyword start=+^\(Summary$\|Syntax$\|Parameters$\|Description$\|Properties$\|Methods$\|Examples$\|See\sAlso$\)\@=+ end=+$+
  " yui
  syntax region jsextrarefKeyword  matchgroup=jsextrarefKeyword start=+^\(Constructor$\|Parameters:$\|Returns:\|(Methods\|Properties\|Events) inherited from\)\@=+ end=+$+
  " jsdoc
  syntax region jsextrarefKeyword  matchgroup=jsextrarefKeyword start=+^\(Constructor$\|Parameters:$\|Returns:$\|Defined in:\|\s*\(Class\|Method\|Field\) Summary\|\(Namespace\|Class\|Method\|Field\) Detail$\|\(Class\|Method\|Field\) borrowed from class \)\@=+ end=+$+

  highlight def link jsextrarefKeyword Title

  let b:current_syntax = 'ref-jsextraref'
endfunction



function! s:execute(file)  "{{{2
  if type(g:ref_jsextra_cmd) == type('')
    let cmd = split(g:ref_jsextra_cmd, '\s\+')
  elseif type(g:ref_jsextra_cmd) == type([])
    let cmd = copy(g:ref_jsextra_cmd)
  else
    return ''
  endif

  let file = s:get()[a:file]
  if stridx(file, "/") != 0
    let file = s:path(s:STORE . "/" . file)
  endif
  let file = substitute(file, '#.*$', "", "")
  let file = escape(file, '\')
  let res = ref#system(map(cmd, 'substitute(v:val, "%s", file, "g")')).stdout
  if &termencoding != '' && &termencoding !=# &encoding
    let converted = iconv(res, &termencoding, &encoding)
    if converted != ''
      let res = converted
    endif
  endif
  return res
endfunction



function! s:gather_func(name)  "{{{2
  " let list = glob(g:ref_jsextra_path . '/*')
  " return map(split(list, "\n"),
  "       \ 'substitute(v:val, "\\v".g:ref_jsextra_path."/", "", "")')
endfunction


function! s:func(name)  "{{{2
  return function(matchstr(expand('<sfile>'), '<SNR>\d\+_\zefunc$') . a:name)
endfunction



function! s:cache()  " {{{2
  return ref#cache('jsextra', 'function', s:func('gather_func'))
endfunction


function! s:filter(body) " {{{2
  return a:body
endfunction


function! s:path(relative) " {{{2
  let spath = s:ROOT . "/" . a:relative
  " let spath = s:ROOT . "/" . a:relative
  return spath
endfunction

function! ref#jsextra#a()
echoerr s:path("a/b")
endfunction

function! s:system_in(cmds, dir) " {{{2
  let cmds = type([]) == type(a:cmds) ? a:cmds : [a:cmds]
  let ret = ""
  let cwd = getcwd()
  execute 'lcd' a:dir
  for cmd in cmds
    let ret = ret . system(cmd)
  endfor
  execute 'lcd' cwd
  return ret
endfunction


function! s:get() " {{{2
  let src = {}
  if filereadable(s:path(s:DICT))
    let src = eval(join(readfile(s:path(s:DICT)), "\n"))
  endif
  let dict = {}

  for lib in keys(src)
    for name in keys(src[lib])
      let dict[name] = src[lib][name].path
      for prop in ["property", "methods", "events", "attributes"]
        for attr in keys(src[lib][name][prop])
          let dict[name . "." . attr] = src[lib][name][prop][attr]
        endfor
      endfor
    endfor
  endfor
  return dict
endfunction


function! s:install() " {{{2
  let store = s:path(s:STORE)
  if !isdirectory(store)
    call mkdir(store)
  endif

  call writefile([substitute(
        \ string(g:ref_jsextra_defines), "'", '"', 'g')
        \ ], s:path(s:REPOS_DEFINE))

  let bin = s:path(s:BIN)
  let bindir = s:path(s:BINDIR)

  echo s:system_in("npm install", bindir)
  echo s:system_in(printf("node %s", bin), store)
endfunction

function! ref#jsextra#install() " {{{2
  call s:install()
endfunction

function! ref#jsextra#clear_archive() " {{{2
  let cache_dir = s:path(s:STORE)
  let files = split(glob(cache_dir . "/*"), "\n")
  let dict_name = fnamemodify(s:DICT, ':t')
  let repo_def_name = fnamemodify(s:REPOS_DEFINE, ':t')
  for f in files
    let name = fnamemodify(f, ':t')
    if name =~? dict_name || name =~? repo_def_name
      continue
    endif
    let cmd = s:is_win ?  ['del', '/Q', '/F', f] : ['rm', '-rf', f]
    call ref#system(cmd)
  endfor
endfunction


function! ref#jsextra#define()  " {{{2
  return s:source
endfunction


call ref#register_detection('javascript', 'jsextra', 'append')



let &cpo = s:save_cpo
unlet s:save_cpo

