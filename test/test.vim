set list listchars=eol:$,tab:>>,trail:+,space:+,nbsp:+

function! g:Expect(expected)
	let got = {'ts': &ts, 'sw': &sw, 'sts': &sts, 'et': &et}
	if a:expected !=# got
		call append(0, ['Expected: '.string(a:expected).';', '     got: '.string(got).'.'])
		redraw
		messages
		call getchar()
		1cquit
	endif
endfunction

function! g:Test(lines, expected)
	" Test two different values for each options since we also want to test it
	" if plugin touched them or not.
	for et in [0, 1]
		for n in [1, 2]
			%delete

			setlocal tw=80
			let &l:ts = n
			let &l:sw = n
			let &l:sts = n
			let &l:et = et
			let expected = extend(deepcopy(a:expected), {'ts': &ts, 'sw': &sw, 'sts': &sts, 'et': &et}, 'keep')

			if type(a:lines) ==# v:t_list
				call setline(1, a:lines)
			else
				execute 'normal!' a:lines
			endif
			set ft=text

			call Expect(expected)
		endfor
	endfor
endfunction

call Test(":setlocal ts=2 sw=3 sts=4\<CR>", {'ts': 2, 'sw': 3, 'sts': 4})
call Test([], {})

call Test(['I'], {})

call Test(["\tI"], {'et': 0})
call Test(["  I"], {'ts': 2, 'sw': 2, 'sts': 2, 'et': 1})

call Test([
\" \t \tA",
\], {})

call Test([
\"",
\], {})

call Test([
\"\tI",
\" I",
\], {'et': 0})

call Test([
\"\tI",
\"",
\"\tI",
\"",
\"\tI",
\], {'et': 0})

call Test([
\"\tA",
\"\t\tB",
\"\t\t\tC",
\], {'et': 0})

call Test([
\"   I",
\"",
\"   I",
\"",
\"   I",
\], {'ts': 3, 'sw': 3, 'sts': 3, 'et': 1})

call Test([
\"",
\"   I\t\t\t",
\"",
\"   I\t",
\], {'ts': 3, 'sw': 3, 'sts': 3, 'et': 1})

call Test([
\"\tI",
\" I",
\"\tI",
\], {'et': 0})

call Test([
\"\tI",
\"",
\"\tI",
\"      I",
\"      I",
\"      I",
\"      I",
\"",
\"\tI",
\], {'et': 0})

call Test([
\"I",
\"",
\"   I",
\"      I",
\"\tI",
\"\tI",
\"\tI",
\"",
\"   I",
\], {'ts': 9, 'sw': 3, 'sts': 3, 'et': 0})

call Test([
\"I",
\"",
\"   I",
\"\tI",
\"\tI",
\"\tI",
\"\tI",
\"",
\"   I",
\], {'ts': 6, 'sw': 3, 'sts': 3, 'et': 0})

call Test([
\">>\t<",
\">\t<",
\">>>\t<",
\">>>>>\t<",
\">>>>>>>\t<",
\], {'ts': 8, 'sw': 8, 'sts': 8, 'et': 0})

call Test([
\"  >>\t<",
\"  >\t<",
\"  >>>\t<",
\"  >>>>>\t<",
\"  >>>>>>>\t<",
\], {'ts': 10, 'sw': 2, 'sts': 2, 'et': 1})

call Test([
\"XXXXXXX\tYYY,\tXXXXXXXXXX,\tZ",
\"\tYYY,\t\tX,\t\tZ",
\], {'ts': 6, 'sw': 6, 'sts': 6, 'et': 0})

call Test([
\"XXXXXXXXXXX	XXX,",
\"Y\tYYY,\tY,\tY,",
\], {'ts': 2, 'sw': 2, 'sts': 2, 'et': 0})

" Prefers current value.
%delete
set ts=7 sw=9 sts=11
call setline(1, ["L\tI", "LL\tI"])
set ft=text
call Expect({'ts': 7, 'sw': 7, 'sts': 7, 'et': 0})

if empty(v:errmsg)
	0cquit
else
	redraw
	messages
	call getchar()
	1cquit
endif