# Note on PATH and convenience 

Calling (executing) the programs just by their name, like `derivative`
usually needs the program's location to be part of the
[PATH](https://en.wikipedia.org/wiki/PATH_(variable)) environment
variable. If you don't want to meddle with your `PATH`, an
[alias](https://www.man7.org/linux/man-pages/man1/alias.1p.html) may
also simplify calling these. Otherwise, a relative or absolute path is
needed when calling them, e.g.: `./derivative` or
`~/RPN-Derivative/bin/derivative`. The examples in the
[README](README.md) uses the relative path syntax every once in a
while as a reminder.

## Using Aliases

```sh
alias derivative="${HOME}/bin/derivative"
alias simplify="${HOME}/bin/derivative"
alias to_rpn="${HOME}/bin/to_rpn"
alias to_infix="${HOME}/bin/to_infix"
```

If there is a name conflict with another program called any of those
words, then the alias can of course be any other word.
