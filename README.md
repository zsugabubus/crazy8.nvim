# vim-detectindent

Zero-config (Neo)Vim plugin to automatically detect and set `'tabstop'`,
`'shiftwidth'`, `'softtabstop'` and `'expandtab'`.

## Features

- Uses AI, written in pure Vim script.
- Allows setting defaults using the plain old method (below). However note that as human beings
  getting more and more superseded by computers, this feature will be eventually
  dropped. You have been warned.

```vim
autocmd FileType c,cpp,xyz
	\ setlocal ts=6 sw=7 sts=8 noet yesai
```

## Why?

Why? You ask why? You must be kidding. Have you seen that bullshit that these
plugins do?
- [ciaranm/detectindent](https://github.com/ciaranm/detectindent),
- [tpope/vim-sleuth](https://github.com/tpope/vim-sleuth),
- [xi/vim-indent-detect](https://github.com/xi/vim-indent-detect),
- (TODO: add your shit here).
