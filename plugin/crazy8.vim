" LICENSE: GPLv3 or later
" AUTHOR: zsugabubus
if exists('g:loaded_crazy8')
	finish
endif
let g:loaded_crazy8 = 1

lua require'crazy8'
augroup vim_crazy8
	autocmd!
	autocmd BufReadPost,FileType,Syntax * lua Crazy8()
	autocmd BufNewFile * autocmd BufWritePost <buffer=abuf> ++once lua Crazy8()
augroup END
