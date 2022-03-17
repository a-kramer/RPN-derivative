# Note on PATH and convenience 

The programs can be installed via `make install` (then you can just
call them by name). But, if you prefer not to do that, you can use the
binaries from the directory they were built in directly.

Calling (executing) the programs just by their name, like `derivative`
usually needs the program's location to be part of the
[PATH](https://en.wikipedia.org/wiki/PATH_(variable)) environment
variable. If you don't want to meddle with your `PATH`, an
[alias](https://www.man7.org/linux/man-pages/man1/alias.1p.html) will
do the trick. Otherwise, a relative-, or absolute path is
needed when calling them, e.g.: `./derivative`, or
`~/RPN-Derivative/bin/derivative`. 

## Using Aliases

As an example, let's assume that the binaries are all in the `bin`
directory in the current user's home:

```sh
alias derivative="${HOME}/bin/derivative"
alias simplify="${HOME}/bin/derivative"
alias to_rpn="${HOME}/bin/to_rpn"
alias to_infix="${HOME}/bin/to_infix"
```

If there is a name conflict with another program called any of those
words, then the alias can of course be any other word.

Alias definition don't persist over sessions, unless you put these
statements into an init file: `~/.bashrc`, `~/.bash_aliases`, or
`~/.profile`.
