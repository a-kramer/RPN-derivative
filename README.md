# Reverse Polish notation and Derivatives

With this code, I try to calculate the symbolic derivative, say
`d(y*x)/dx = y`, with as simple means as possible, without using
external libraries.

The input expression must be balanced: `x y z +` has an unused operand, `x +` lacks an operand.

An unbalanced expression produces an empty line in the output.

## Usage

The programs in this repository are meant to be used via pipes:
```bash
... | to_rpn | derivative x | simplify
```
They all read _n_ lines from standard input (stdin) and output _n_ lines to standard output (stdout).

### Conversion to rpn

The program `to_rpn` reads `stdin` for math expressions in infix
notation (the normal kind) and tries to convert them into reverse
Polish notation:

```
$ bin/to_rpn < math.txt
[...]
```

This program takes no command line arguments.

### derivative

```
$ bin/to_rpn < math.txt | derivative 't'
```

The `derivative` function takes one mandatory command line argument,
the name of a variable _t_. The derivative of the input expressions
will be calculated with respect to the named variable.

### simplify

`simplify` tries to reduce the length of an rpn expression by eliminating
obviously unnecessary operations like `x 0 +`.

```bash
echo "x 0 0 + +" | simplify [n]
```

This program has one optional parameter _n_ (an integer):
simplification will be repeated _n_ times. This is equivalent to
repeated calls to `simplify`:

```
$ echo "x 0 0 + +" | bin/simplify 
x 0 +
$ echo "x 0 0 + +" | bin/simplify | bin/simplify
x
$ echo "x 0 0 + +" | bin/simplify 2
x
```

#### Note

To calculate the derivative of `x*y/(a+b)` with respect to `y`:

```bash
$ echo -e "x y * a b + /" | ./derivative y | ./simplify 3
```
produces:
```
x a b + * a b + a b + * /
```

which is `x*(a+b)/((a+b)*(a+b))` in infix notation (so
`x/(a+b)`). This is almost right (technically correct, but
unnecessary).

So, `simplify` doesn't really know math, it merely tries some simple
pattern recognition.

An easier example `d[x*y*(y+2)]/dy`:

```bash
$ echo -e "x y * y 2 + *" | ./derivative y | ./simplify 2
```

outputs:
```
x y 2 + * x y * +
```

which is `x*(y+2) + x*y` (OK). In some cases, it may be easy enough to
parse the output with `sed` and get rid of unnecessary terms.

## Mathematical Functions

To make it easy to parse math expressions, standard math functions
shall be prefixed with an `@`. This is to avoid confusion with
variable names. It would have been possible to distinguish functions
and variable names by string matching and reserving a list of names
for functions. 

But, a function may very well not yet be implemented and thus be
understood as a variable name. But with a leading `@` an error will
occur if the function is not understood.

Currently: `@exp, @log, @sin, @cos`

## Limitations

Many. Very few operator symbols and functions are and will ever be
supported. Notably, the _power(a,b)_ function is currently missing as
are all logical opertors, bitwise operators and integer arithmetic
(e.g. remainder/modulus).

There are very few checks to see if the input is a _valid_ RPN expression.

All variables must be one letter.

This will never become a scripting language like `dc`, with registers
and user defined macros (or other things that are too hard for me to
implement).

## Documentation

The [doc](./doc) folder contains developer documentation in html form,
created with [codedoc](https://github.com/michaelrsweet/codedoc).

The [src](./src) folder contains further notes on the code
organization.

## Small Tests

It is possible to manually test simple cases numerically, without
external software. We use [dc](https://linux.die.net/man/1/dc) to do
this, as it is probably installed on every unix like/related
system. The `dc` program wants reverse polish notation as input, so it
is perfectly suited to check output from `bin/derivative` before it
has been converted to R or C code (see the next Section).

There are two shell scripts in the `tests` folder that help with the
testing: 

1. [numerical.sh](tests/numerical.sh) 
2. [eval.sh](tests/eval.sh)

The first script calculates the finite difference approximation of a
derivative a given an rpn expression for `f`: `(f(x+h)-f(x-h))/(d*h)`;
the second script evaluates any rpn expression using `dc` (it does all
necessary substitutionsso that `dc` will accept the expression).

```bash
echo "x a @pow" | tests/numerical.sh x 2 0.0001 | tests/eval.sh a=3
```

The above instruction will calculate the finite difference at `x=2`
and `h=0.001` and pass the expression on to `eval.sh`, which in turn will substitute all occurences of `a` with `2`. 

This finally calls `dc` with the following instruction:
```dc
2.0001 3 ^ 1.9999 3 ^ - 2 0.0001 * / p
```

The final instruction _p_ prints the result `12`:
```bash
$ dc -e '2.0001 3 ^ 1.9999 3 ^ - 2 0.0001 * / p'
12
```

which is correct. We can compare this to the analytical derivative:

```bash
$ echo 'x a @pow' | bin/derivative x | bin/simplify 3 | tests/eval.sh a=3 x=2
12.0000000000
$ echo "x a @pow" | tests/numerical.sh x 2 0.0001 | tests/eval.sh a=3
12.0000005000
```

*note* normally `dc` will floor fractions, to avoid this we set the
precision to 10 digits: `dc -e '3 2 / p'` prints `1` (floor(3/2) is
1).

## Plans

Near future: automatic conversion from rpn strings to C code. Then, it will be possible to do this (perhaps): 
```bash
$ # planned:
$ echo "x*y" | to_rpn | derivative x | simplify 3 | rpn_to_c 
```

maybe like this
```
double derivative(double x, double y)
{
 return y;
}
```

Or something similar. But specifically, this project aims to
automatically calculate the Jacobian of a vector valued function used
as right hand side in ordinary differential equations.
