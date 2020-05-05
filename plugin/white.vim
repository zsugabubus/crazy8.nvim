" LICENSE: GPLv3 or later
" AUTHOR: zsugabubus
function! s:text_width(width, tabs) abort

endfunction

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

		" We only care about code.
		let ignore = synIDattr(synIDtrans(synID(lnum, col, 1)), "name") =~? 'comment|string'
		if ignore
			continue
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

	let tsset = 0

	" Note: Ranges not inclusive, important when `lines` is 0.
	" 5%
	if et <# -lines / 20
		set noet
	elseif et ># lines / 20
		set et
		let tsset = 1
	endif

	for [sw, count] in items(swstat)
		if swsum <# count * 2
			let &sw = sw

			" If tabs have been expanded 'ts' and 'sts' is assumed to be equal to
			" 'sw', unless it will be overwritten explicitly.
			if et ># lines / 20
				let &ts=sw
				let tsset = 1
				let &sts=sw
			endif

			for [sts, count] in items(stsstat)
				if stssum <# count * 2
					let &sts = sts + sw " +1 indentation ('sw').
					let &ts = &sts
					let tsset = 1
					set noet
					break
				endif
			endfor
			break
		endif
	endfor

	if !tsset
		" No indentations found so could not determine 'tabstop'.
		let corpus = {}
		let lnum = 0

		while 1
			call cursor(lnum + 1, 1)
			" Find next line with leading tabs then spaces
			let lnum = searchpos('\v\t+', 'eW', 1000, 10)[0]
			if lnum ==# 0
				break
			endif

			let chunks = []

			let right = getline(lnum)
			while 1
				let [_, left, tabs, right; _] = matchlist(right, '\v^([^\t]*)(\t*)(.*)$')
				if tabs ==# ''
					break
				endif

				call add(chunks, [strwidth(left), strlen(tabs) - 1])
			endwhile
			if empty(chunks)
				continue
			endif

			let corpus[lnum] = chunks
			" FIXME: We should check hunks and not induvidual line count.
			if len(corpus) >=# 100 || lnum ==# line('$')
				break
			endif
		endwhile

		let tsstat = {}
		for ts in range(2, 32)
			let tsstat[ts] = 0
		endfor

		while !empty(corpus) && len(tsstat) ># 1
			let newcorpus = {}

			for [lnum, chunks] in items(corpus)
				if !has_key(corpus, lnum + 1)
					continue
				endif

				let [aleft, atabs] = chunks[0]
				let [bleft, btabs] = corpus[lnum + 1][0]

				for [ts, _] in items(tsstat)
					let tsstat[ts] +=
						\ aleft - aleft % ts + atabs * ts ==#
						\ bleft - bleft % ts + btabs * ts
				endfor

				if len(chunks) ># 1
					let newcorpus[lnum] = chunks[1:]
					let newcorpus[lnum + 1] = corpus[lnum + 1][1:]
				endif
			endfor
			let corpus = newcorpus

			let max = max(values(tsstat))
			call filter(tsstat, {_, count -> count ==# max})
		endwhile

		set noet
		let &ts = min(keys(tsstat))
		let &sw = &ts
		let &sts = &ts
	endif

	" echoe &ts &sw &sts tsset 'et' &et string(et) 'ln' string(lines) string(swstat) string(stsstat)
	call winrestview(view)
endfunction

augroup vim_detectindent
	autocmd BufReadPost,FileType,Syntax * profile start white.log|profile file *|profile func *|noautocmd keepjumps call s:detect()|profile stop
augroup END
