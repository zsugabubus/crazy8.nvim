set list listchars=eol:$,tab:>>,trail:+,space:+,nbsp:+
syntax enable

function! g:Expect(expected) abort
	let got = {'ts': &ts, 'sw': &sw, 'sts': &sts, 'et': &et}
	if a:expected !=# got
		call append(0, ['Wanted: '.string(a:expected).';', 'Actual: '.string(got).'.'])
		redraw
		messages
		call getchar()
		1cquit
	endif
endfunction

function! g:Test(lines, expected) abort
	" Test two different values for each options since we also want to test it
	" if plugin touched them or not.
	for et in [0, 1]
		for n in [1, 2]
			%delete
			call setline(1, a:lines)
			filetype detect

			setlocal tw=80
			let &l:ts = n
			let &l:sw = n
			let &l:sts = n
			let &l:et = et
			let expected = extend(deepcopy(a:expected), {'ts': &ts, 'sw': &sw, 'sts': &sts, 'et': &et}, 'keep')

			lua Crazy8()

			echom &ft
			call Expect(expected)
		endfor
	endfor
endfunction

call Test([], {})

call Test(['I'], {})

call Test([
\"\tI"
\], {'et': 0})

call Test([
\'  I'
\], {'ts': 2, 'sw': 2, 'sts': 2, 'et': 1})

call Test([
\" \t \tA",
\], {})

call Test([
\"",
\], {})

call Test([
\"\tI",
\"  I",
\"  I",
\"  I",
\"  I",
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
\"  I",
\"\tI",
\"\t  I",
\"\t    I",
\], {'ts': 4, 'sw': 2, 'sts': 2, 'et': 0})

call Test([
\"I",
\"\tI",
\"\t  I",
\"\t    I",
\], {'et': 0})

call Test([
\"\tI",
\"\t  I",
\"\t    I",
\"\t      I",
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
\"XXXXXXXXXXX\tXXX,",
\"Y\tYYY,\tY,\tY,",
\], {'ts': 2, 'sw': 2, 'sts': 2, 'et': 0})

call Test([
\"XXXXXXXXXX\tXX,",
\"Y\tYYY,\tY,\tY,",
\], {'ts': 2, 'sw': 2, 'sts': 2, 'et': 0})

" Prefers current value.
%delete
set ts=7 sw=9 sts=11
call setline(1, ["L\tI", "LL\tI"])
lua Crazy8()
call Expect({'ts': 7, 'sw': 7, 'sts': 7, 'et': 0})

" Inconsistent spaces and tabs size drops sw.
call Test([
\'/*',
\' *',
\' *',
\' *',
\' *',
\' *',
\' */',
\'',
\"A234 <space",
\"\tB",
\"\t\tC",
\"\tB",
\"\t\tC",
\"\tB",
\"\t\tC",
\"A",
\], {'et': 0})

call Test([
\"\t I",
\"\t   I",
\"\t      I",
\"\t          I",
\], {'et': 0})

call Test([
\'P',
\'  Y',
\'    R',
\'      A',
\'    M',
\'  I',
\'D',
\'  Z4567( <--space we dont care about',
\"\tS",
\"\tS",
\"\tS",
\"\tS",
\"\tS",
\"\tS",
\"\tS",
\"\tS",
\"\tS",
\"\tS",
\"\tS",
\"\tS",
\"\tS",
\"\tS",
\'H',
\], {'ts': 4, 'sw': 2, 'sts': 2, 'et': 0})

" Zsh is full of such shit. But hey... no problem. :)
call Test([
\'if [[ -z "$_comp_no_ignore" ]]; then',
\'  zstyle -a ":completion:${curcontext}:$1" ignored-patterns _comp_ignore ||',
\'    _comp_ignore=()',
\'',
\'  if zstyle -s ":completion:${curcontext}:$1" ignore-line hidden; then',
\'    local -a qwords',
\'    current-shown)',
\"\t    [[ '$compstate[old_list]' = *shown* ]] &&",
\'            _comp_ignore+=( $qwords[CURRENT] );;',
\'    other)         _comp_ignore+=( $qwords[1,CURRENT-1]',
\"\t\t\t\t   $qwords[CURRENT+1,-1] );;",
\'',
\], {'ts': 8, 'sw': 2, 'sts': 2, 'et': 0})

call Test([
\'void****malloc(size_t size',
\"\t\t void*** something);"
\], {'ts': 7, 'sw': 7, 'sts': 7, 'et': 0})

" Tabs align well to each other. Prefer current. Expect if it’s zero.
call Test([
\'int __get_compat_msghdr(struct msghdr *kmsg,',
\"\t\t\tstruct compat_msghdr __user *umsg,",
\"\t\t\tstruct sockaddr __user **save_addr,",
\], {'ts': 2, 'sw': 2, 'sts': 2, 'et': 0})

call Test([
\'if (',
\'    ()) {',
\"\t/* ... */",
\'}'
\], {'ts': 4, 'sw': 4, 'sts': 4, 'et': 0})

call Test([
\'vim:ft=c:',
\'if (',
\'    ()) {',
\"\t/* ... */",
\"\tbreak;",
\'}',
\], {'et': 0})

if empty(v:errmsg)
	0cquit
else
	redraw
	messages
	call getchar()
	1cquit
endif
