" LICENSE: GPLv3 or later
" AUTHOR: zsugabubus
lua require'crazy8'
augroup vim_crazy8
	autocmd BufReadPost,FileType,Syntax * lua Crazy8()
augroup END
