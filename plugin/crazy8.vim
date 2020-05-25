" LICENSE: GPLv3 or later
" AUTHOR: zsugabubus
if exists('g:loaded_crazy8')
	finish
endif
let g:loaded_crazy8 = 1

augroup vim_crazy8
	autocmd!
	autocmd BufNewFile,BufReadPost * ++once lua require'crazy8'
	" Needs to be run after syntax is fully loaded.
	autocmd BufReadPost * autocmd BufEnter <buffer=abuf> ++once lua Crazy8()
	autocmd BufNewFile * autocmd BufWritePost <buffer=abuf> ++once lua Crazy8()
augroup END
