" LICENSE: GPLv3 or later
" AUTHOR: zsugabubus
if has('nvim')
	lua require'white'

	augroup vim_white
		autocmd BufReadPost,FileType,Syntax * lua detect()
	augroup END
else
	function! s:detect() abort
		let view = winsaveview()

		let prev_lnum = -1
		let swstat = {}
		let swsum = 0
		let ts = {}
		let stsstat = {}
		let stssum = 0
		let et = 0
		let noet = 0
		let lines = 0

		call cursor(1, 1)
		while 1
			" Find next line with leading tabs then spaces
			let [lnum, col] = searchpos('\v\C^\t* *\S', 'eW', 1000, 10)
			if lnum ==# 0
				break
			endif

			let [_, tabs, spaces; _] = matchlist(getline(lnum), '\v\C^(\t*)( *)')
			let ntabs = strlen(tabs)
			let nspaces = strlen(spaces)

			if lnum ==# prev_lnum + 1
				let lines += 1

				let diffspace = abs(nspaces - prev_nspaces)
				let difftab = abs(ntabs - prev_ntabs)
				if ntabs ==# prev_ntabs
					if diffspace !=# 0
						" Amount of space changed.
						let swsum += 1
						let swstat[diffspace] = get(swstat, diffspace, 0) + 1
						let et += 1
					endif
				else
					if diffspace ==# 0
						if difftab ==# 1
							" Indentation changed by one tab. No spaces.
							let et -= 1
						end
						" Otherwise it’s a garbage line.
					else
						if nspaces ==# 0 || prev_nspaces ==# 0
							" Some spaces become tab or vica versa.
							let stssum += 1
							let stsstat[diffspace] = get(stsstat, diffspace, 0) + 1
						endif
					endif
				endif

				if lines >=# 100
					" We have collected enough samples.
					break
				endif
			endif

			let prev_ntabs = ntabs
			let prev_nspaces = nspaces
			let prev_lnum = lnum
		endwhile
		call winrestview(view)
	endfunction

	augroup vim_white
		autocmd BufReadPost,FileType,Syntax * s:detect()
	augroup END
endif
