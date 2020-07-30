check :
	nvim -u NONE --cmd 'set rtp+=.' +'source plugin/crazy8.vim' +'lua require"crazy8"' +'source t/test.vim'

.PHONY : check
