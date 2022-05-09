# Alternatives

Here we list some alternative ways to get similar results, and also
comment on things that are not quite workable alternatives.

All numerical methods that approximate the derivative (even *very*
accurately) are obviously not alternatives, because the more accurate
a finite difference method is, the more evaluations of the function it
requires. This leads to unacceptable costs for the evaluation of
jacobian matrices during ODE integration and similar procedures
(gradients, Hessians, etc.).

Computer Algebra Systems
[CAS](https://en.wikipedia.org/wiki/Computer_algebra_system) can
easily calculate analytical derivatives.

The order is in decreasing usefulness as a replacement for this
package.

## maxima (cas)

[Maxima](https://maxima.sourceforge.io/) can do much more than
derivatives and has both a command line interface as well as graphical
interfaces like
[wxMaxima](https://wxmaxima-developers.github.io/wxmaxima/).

To make maxima output fit on one line and usable for code generation,
we have to set `display2s` to `false`.

```sh
$ echo "display2d:false$ diff(exp(x^2*k),x,1);" | maxima --very-quiet | tail -n1
2*k*x*%e^(k*x^2)
```

or even better:

```sh
$ echo "display2d:false$ diff(exp(x^2*k),x,1);" | maxima --very-quiet | sed -e '1d' -e 's/%e^/exp/g'
2*k*x*exp(k*x^2)
```

also works for more than one input function:

```sh
$ echo "display2d:false$ diff(exp(x^2*k),x,1); diff(exp(((x*y - k)/s)^2),x,1);" | maxima --very-quiet | sed -e '1d' -e 's/%e^/exp/g'
2*k*x*exp(k*x^2)
(2*y*(x*y-k)*exp((x*y-k)^2/s^2))/s^2
```

It is possible that maxima is interfaced with some scientific
scripting languages, e.g. [RMaxima](https://github.com/skranz/RMaxima)
(experimental).

## YACAS

[Yet Another Computer Algebra System](http://www.yacas.org/) is a Free
Software that can be used a s a replacement for the code provided in
this repository.

```sh
$ echo 'D(x) Exp(-k*x^2/s^2)' | yacas -c -f | sed -e 's/Exp/exp/g'
-(exp(-(k*x^2)/s^2)*k*2*x)/s^2;
```

This algebra system is available from within
[R](https://www.r-project.org/) as
[ryacas](https://cran.r-project.org/web/packages/Ryacas/index.html).

## GiNaC

[GiNaC](https://www.ginac.de/) is Not a Cas (but it is, kind of). This
is a c++ library that can be used to perform differentiation in any
c++ program.

It cannot be used as a command line tool to achievce our goals, but
[vfgen](https://warrenweckesser.github.io/vfgen/) can to some extent
(it uses GiNaC internally). VFGEN explicitly outputs programming
language code (with many targets), rather than string math
expressions. So it is a valid solution to the overall goal of
automatic model code creation.

In the past [GNU Octave](https://www.gnu.org/software/octave/index)
had a symbolic math package with GiNaC under the hood (but not
anymore).

## SymPy

[SymPy](https://www.sympy.org/en/index.html) is a
[python](https://medium.com/nerd-for-tech/python-is-a-bad-programming-language-2ab73b0bda5)
package.

At the time of writing it is also the backend of [GNU Octave](https://www.gnu.org/software/octave/index)'s
[symbolic](https://octave.sourceforge.io/symbolic/) package.

Another science scripting language that interfaces with SymPy is
[R](https://www.r-project.org/): The package
[rSymPy](https://github.com/FedericoComoglio/rSymPy) (it uses Jython, a
Java implementation of Python).

## Mathematica, Maple, MATLAB

There are very powerful commercial software packages, all three can easily calculate analytical derivatives:

* [Wolfram Mathematica](https://www.wolfram.com)
* [Maple](https://www.maplesoft.com)
* [MathWorks](https://www.mathworks.com) [MATLAB](https://www.mathworks.com/products/matlab.html)
    - [symbolic toolbox](https://www.mathworks.com/help/symbolic)

The proprietary nature of the license disqualifies all three from further consideration here.

This concern is not entirely about the exchange of money. With proproietary, licensed software, frequently:

* it is unclear who owns a piece of work when the work is deeply
  embedded in a company's infrastructure (cloud storage, cloud computing, etc.)
* know which rights the author of a script has and which rights the user of a script has
* the user of the software is controlled by means of *license servers*, *license files*, *codes*, or *keys*
    - once a key is temporarily inaccessible, the work with that software is interrupted
    - the user has to set up the licensing mechanism (register, create an "account")
    - the script can never be published as part of another
      institution's infrastructure that is not licensed to use the
      problematic software
    - there is administrative overhead for an institution that doesn't
      have a license related *accounting procedure* in place.
* users of proprietary software for scientific purposes can lose access to it when
    - their institution cancels or changes the licensing agreement
    - the comapany that makes the software goes out of business
    - a student (user) was under a student license and then graduates
      or otherwise loses prerequisites to a license


## Julia and Automatic Differentiation

In [Julia](https://julialang.org/), several packages exist that
perform automatic differentiation:
e.g. [ForwardDiff](https://github.com/JuliaDiff/ForwardDiff.jl), and
[Zygote](https://github.com/FluxML/Zygote.jl).

This can be a solution to the overall goal of this package (evaluating
the gradient or jacobian of a function repeatedly). If the user plans
to ultimately work in Julia and solve the model equations in that
environment these packages can make symbolic calculations
unnecessary. However, these julia packages are not a plug-in replacement for the
programs in this repository.
