" LICENSE: GPLv3 or later
" AUTHOR: zsugabubus
if exists('#crazy8')
	finish
endif
augroup crazy8
	autocmd!
	autocmd BufNewFile,BufReadPost * ++once lua require'crazy8'
	" Needs to be run after syntax is fully loaded.
	autocmd BufReadPost * autocmd BufEnter <buffer=abuf> ++once lua Crazy8()
	autocmd BufNewFile * autocmd BufWritePost <buffer=abuf> ++once lua Crazy8()
augroup END
