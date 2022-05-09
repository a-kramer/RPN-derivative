# Reverse Polish notation and Derivatives

With this code, we try to calculate the symbolic derivative, say
`d(y*x)/dx = y`, with as simple means as possible, without using
external libraries.

Specifically, this project aims to automatically calculate the
Jacobian of a vector valued function used as right hand side in
ordinary differential equations.

There are many software packages that can do this and much more
(computer algebra systems). Here is a [list of alternatives](alternatives.md).

## Summary

Especially the `derivative` program requires the input to be math in
reverse Polish notation (rpn), e.g.: `1 2 +` (for 1+2); this notation
does not *need*, nor *allow* parentheses.

The [dc](https://linux.die.net/man/1/dc) program works with this notation,
so it may be familiar to the reader.

RPN math is easier (*citation needed*) to process (at least for what
we do here) as there are no parentheses and evaluation follows a very
simple algorithm.

The input expression must be *balanced*, unlike: `x y z +`, which has
an unused operand, or `x +`, which lacks an operand (`dc` would not care
much about the former and print a warning about the latter).

An unbalanced expression produces an empty line in the output of any
program in this repository (or possibly a line with an error message).

All programs read from stdin. In any case, we try to keep the line
numbers of input and output the same (the derivative of input line *n*
will be in output line *n*).

Although it is of course possible to use `derivative` and `simplify`
by themselves, you can also use `to_rpn` to convert more conventional
math to rpn notation and `to_infix` to translate the result back.

## Compiling

The default compiler in the [Makefile](Makefile) is
[gcc](https://gcc.gnu.org/), but [tcc](https://repo.or.cz/tinycc.git)
will also work. In the root directory of this repository these
commands:

```bash
$ mkdir bin
$ make
$ make test
```

These commands will create the binaries `derivative`, `simplify`, and `ll_test`; `make test` will run [test.sh](tests/test.sh).

The [symbol](src/symbol.h) component takes a macro that fixes the
maximum length of variable names: `MAX_NAME_SIZE`. It can be defined on
the command line, when compiling: `gcc -DMAX_NAME_SIZE=10 [...]`.

Installation is optional, see this [note](note.md).

## Installation

The default target directory for installation is `/usr/local/bin`:

```sh
$ sudo make install
```

Afterwards, these commands should work:

```sh
$ which derivative
/usr/local/bin/derivative
$ man derivative
```

If you prefer a different location, edit the `PREFIX` variable in
[Makefile](./Makefile).

## Usage

The programs in this repository are meant to be used via pipes:
```bash
[...] | to_rpn | derivative x | simplify
```
They all read _n_ lines from standard input (stdin) and write _n_ lines to standard output (stdout).

### Conversion to RPN

The program `to_rpn` reads `stdin` for math expressions in infix
notation (the normal kind) and tries to convert them into reverse
Polish notation:

```
$ bin/to_rpn < math.txt
```

This program takes no command line arguments.

#### Caveat: Ambiguity and Spacing

This program tries to convert an item it encounters to a number
_first_, only if that fails does it consider other possibilities: the
item could then be an operator, function, or variable name. This
creates an ambiguity with the unary minus (and plus). Consequently,
some strings are not interpreted right: `1-2` is read as `+1` and `-2`
(a sequence of two numbers), but `1 - 2` is understood correctly as
the operation _minus(1,2)_, `a-b` works perfectly fine because `b` is
not a valid number.

The `dc` program resolves this ambiguity by using the underscore to
denote negative numbers: `dc -e '_1 1 + p'` prints 0; but, we don't do that
underscore thing.

The output consists of space separated rpn expressions, so no mixups
of this sort are likely to happen downstream.

### derivative

```sh
$ cd RPN-Derivative
$ to_rpn < math.txt | derivative t
```

The `derivative` function takes one mandatory command line argument,
the name of a variable _t_. The derivative of the input expressions
will be calculated with respect to the named variable.

### simplify

`simplify` tries to reduce the length of an rpn expression by eliminating
obviously unnecessary operations like `x 0 +`.

```sh
$ echo "x 0 0 + +" | simplify [n]
```

This program has one optional parameter _n_ (an integer):
simplification will be repeated _n_ times. This is equivalent to
repeated calls to `simplify`:

```sh
$ echo "x 0 0 + +" | simplify
x 0 +
$ echo "x 0 0 + +" | simplify | simplify
x
$ echo "x 0 0 + +" | simplify 2
x
```

Simplify tries to reduce fractions by finding common factors. If a
common factor is found within a sum, it will be factored out. Not all
obvious common factors are detected.

#### Note

To calculate the derivative of `x*y/(a+b)` with respect to `y`, we would type:

```bash
$ echo "x y * a b + /" | derivative y | simplify 3
```
this produces the output:
```
x a b + * a b + a b + * /
```

which is `x*(a+b)/((a+b)*(a+b))` in infix notation (so
`x/(a+b)`). This is almost right (technically correct, but
unnecessary). This fraction is reduced correctly, now ~Currently, no amount of simplifying will reduce the
fraction unless it reduces to 1;~ This is still true: `simplify` doesn't really know math,
it merely tries some simple pattern recognition.

If you encounter a specific case where you automate code creation for
a computational task and it always produces a difficult type of
fraction, you can use `sed` and regular expressions to further
manipulate the result. The file
[reduce_fraction.sed](sh/reduce_fraction.sed) contains some examples:

```sh
$ echo '(pow(x,3)*(4/x))' | sed -E -f sh/reduce_fraction.sed
(pow(x,(3)-1)*4)
$ echo '(pow(x,3)/x)' | sed -E -f sh/reduce_fraction.sed
(pow(x,(3)-1))
```


#### a simple case

In this example `d[x*y*(y+2)]/dy`, the derivative is just not
problematic at all and does not require any special treatment:

```sh
$ echo "x y * y 2 + *" | derivative y | simplify 2
x y 2 + * x y * +
```

which is `x*(y+2) + x*y` (OK).

### rpn to infix

The output of the programs lilsted in previous Sections can be
converted back into infix notation like this:

```sh
$ bin/to_infix < rpn_math.txt
```

#### Optional parameters

`-s` (safe fractions)
`--safe-fractions=1e-10`

This option is useful when denominators are known/required/assumed to
be non-negative. With `-s`, `to_infix` will add a small safety
constant to denominators to prevent division by zero. This could of
course be terribly wrong, because it does change the printed
expression, we assume that the user is aware of the risks.

In part, this is a safety measure for cases where reduction of fractions didn't
work:

```
x*x/x
```

The above is a perfectly fine fraction, but it cannot be naïvely evaluated at *x*=0
(numerically); it *has* to be reduced to `x`. In contrast, a similar fraction

```
x*x/(1e-16 + x)
```

would work numerically without smart fraction reduction for all arguments *x*>0.
And finally the expression:

```
x*x/(1e-16 + fabs(x))
```

works for all *x*. So, a procedure now can call the resulting math
more carelessly and not crash while doing so.

By default the safety constant is the smallest positive double
precision floating point value (rounded by printing):

```sh
echo 'x x * x /' | to_infix -s
((x*x)/(2.22507e-308 + fabs(x)))
```

Obviously, this should only be used when stability is more important
than accuracy: i.e. the function must never crash. This is sometimes
the case with optimization (a model is called thousands of times in a
row, with sketchy trial arguments). And the above example is for
illustration only, because:

```sh
$ echo 'x x * x /' | simplify 2 | to_infix
x
```

#### Example

Like all other programs in this repository, `to_infix` reads from
standard input and writes to standard output.

```bash
$ echo "@pow(t,3)" | to_rpn | derivative t | simplify 4 | to_infix
(pow(t,3)*(3/t))
```

There will be many superfluous parentheses to produce safe expressions
(they can be used as sub-expressions). The `@` symbol will
be stripped from functions to make it easier to use the expressions
elsewhere.

## Mathematical Functions

To make it ~easy~ convenient to parse math expressions, standard math
functions shall be prefixed with an `@`. This is to avoid confusion
with variable names. It would have been possible to distinguish
functions and variable names by string matching and reserving a list
of names for functions.

A function may be not implemented (yet) and thus its name be
understood as a variable name (e.g. sinh). But with a leading `@` an error will
occur if the function is not known.

Currently: `@exp, @log, @sin, @cos, @pow` are known.

## Limitations: Many

1. Very few operator symbols and functions are and will ever be
supported. All logical opertors are missing, bitwise operators and integer arithmetic
(e.g. remainder/modulus) as they are difficult to differentiate.
2. There are very few checks to see if the input is a _valid_ RPN expression.
3. ~All variables must be one letter~ the maximum length of variables can be set at compile time.
4. Conversion back into infix notation writes many unnecessary parentheses; this is probably fine.
5. Because `simplify` doesn't reliably reduce all fractions, some perfectly finite derivatives cannot be evaluated at, e.g.: _x=0_.

This tool-set will never become a scripting language like `dc`, with
multiple registers and user defined macros (or other things that are
too hard for me to implement).

## Documentation

The [doc](./doc) folder contains developer documentation in html form,
created with [codedoc](https://github.com/michaelrsweet/codedoc).

The [src](./src) folder contains further notes on the code
organization.

## Small Tests

No formal testing framework is used here, but `make test` will run a
series of tests from a [shell script](tests/test.sh).

It is possible to manually test simple cases numerically, without
external software. We use [dc](https://linux.die.net/man/1/dc) to do
this, as it is probably installed on every unix like/related
system. The `dc` program wants reverse polish notation as input, so it
is ~perfectly~ well suited to check output from `bin/derivative` before it
has been converted to R or C code (see the next Section).

There are two shell scripts in the `tests` folder that help with the
testing:

1. [numerical.sh](tests/numerical.sh)
2. [eval.sh](tests/eval.sh)

The first script calculates the finite difference approximation of a
derivative a given an rpn expression for `f`: `(f(x+h)-f(x-h))/(2*h)`;
the second script evaluates any rpn expression using `dc` (it does all
necessary substitutionsso that `dc` will accept the expression), e.g.:

```sh
$ echo "x a @pow" | tests/numerical.sh x 2 0.0001 | tests/eval.sh a=3
12.0000005000
```

The above instruction will calculate the finite difference at _x_=2
and _h_=1e-4 and pass the expression on to `eval.sh`, which in turn
will substitute all occurences of _a_ with 3.

Finally, `eval.sh` calls `dc` with the following instruction:
```dc
2.0001 3 ^ 1.9999 3 ^ - 2 0.0001 * / p
```

The last `dc` command item, _p_, prints the result (12):
```bash
$ dc -e '2.0001 3 ^ 1.9999 3 ^ - 2 0.0001 * / p'
12
```

which is correct (but was rounded). We can compare this to the analytical derivative:

```bash
$ echo 'x a @pow' | bin/derivative x | bin/simplify 3 | tests/eval.sh a=3 x=2
12.0000000000
$ echo "x a @pow" | tests/numerical.sh x 2 0.0001 | tests/eval.sh a=3
12.0000005000
```

*note* normally *dc* will floor fractions. To avoid heavy losses in
accuracy, we set *dc*'s precision (*k*) to 10 digits: `dc -e '3 2 /
p'` prints `1` (because floor(3/2) is 1); `dc -e '3 k 3 2 / p'` prints
`1.500` with precision _k_=3.

