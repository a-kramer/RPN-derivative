# Reverse Polish notation and Derivatives

With this code, I try to calculate the symbolic derivative, say
`d(y*x)/dx = y`, with as simple means as possible, without using
external libraries.

## Usage

To calculate the derivative of `x*y/(a+b)` with respect to `y`:

```bash
$ echo -e "x y * a b + /" | ./derivative y | ./simplify 3
```
produces:
```
x a b + * a b + a b + * /
```
which is `x*(a+b)/((a+b)*(a+b))` in infix notation (so `x`). This is almost right, and technically correct.

simplify doesn't know math, it only tries some simple pattern recognition.

A better working example `d[x*y*(y+2)]/dy`:

```bash
$ echo -e "x y * y 2 + *" | ./derivative y | ./simplify 2
```
outputs:
```
x y 2 + * x y * +
```
which is `x*(y+2) + x*y`, which looks OK.

## Limitations

Many. Very few symbols and functions are and will ever be supported.

## Plans

I want to add conversion between infix and rpn notation as well as
automatic conversion from rpn strings to C code. Then, it will be possible to do this (perhaps): 
```bash
$ # planned:
$ echo "x*y" | infix_to_rpn | derivative x | simplify 3 | rpn_to_c 
```
```
double derivative(double x, double y)
{
 return y;
}
```
Or something like this.
