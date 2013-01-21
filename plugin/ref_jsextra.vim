" A ref source for js reference documentation.
" Version: 0.0.1
" Author : pekepekesamurai<pekepekesamurai@gmail.com>
" License: MIT License

if v:version < 700
  echoerr "does not work this version of Vim(' . v:version . ')'
  finish
elseif exists('g:loaded_ref_jsextra')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! RefJsExtraInstall call ref#jsextra#install()
command! RefJsExtraClearArchive call ref#jsextra#clear_archive()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_ref_jsextra = 1

" vim: foldmethod=marker
