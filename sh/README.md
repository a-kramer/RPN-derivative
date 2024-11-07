# ODE code Generator for the GSL solver suite `<gsl/gsl_odeiv2>`

The [GNU Scientific
Library](https://www.gnu.org/software/gsl/doc/html/ode-initval.html)
defines function interfaces for an ordinary differential equation (ODE) system.

$$
\begin{align}
\dot y &= f(t,y;p)\,\\
 y(t_0) &= y_0\,\\
 F(t_k,y(t_k);p) - z_k &\sim \mathcal{N}(0,\Sigma_k)\,
\end{align}
$$

where the *output function* $F$ models the *measurement* process at
least partially and corresponds to measured data $z$ in some way. This
is only relevant if the ODE system corresponds to some real system
($F$ is optional).

In some cases, $F$ and $z$ cannot be compared directly due to a complex
normalization. In that case the value of $F$ and $z$ have to be passed
into a likelihood function or objective function (cost function) which
performs the needed normalization.

The script [ode.sh](./ode.sh) generates this right-hand-side
function $f$, in C or R (perhaps more languages later). Additionally
the script writes an analytical *Jacobian* $df/dy$, *parameter
Jacobian* $df/dp$, and an output function that models *observable
quanities* together with its partial derivatives.

**Note on platforms** we try to make this script run with GNU
coreutils, busybox, and BSD implementations of the coreutils (i.e.:
options to *find*, *awk*, and *sed*/*perl*).

**Note on C functions:** In addition to the requirements of the
GNU scientific library, the functions return the length of the return buffer they
expect when called with `NULL` pointers instead of allocated output
buffers. For the demo model in [../examples/](../examples), this is:

```c
/* the DemoModel has 6 state variables: A, B, C, AB, AC, and ABC */
double t=12;
int status=DemoModel_vf(t,NULL,NULL,NULL); /* returns 6 */
```
So, we would make sure to allocate `sizeof(double)*6` bytes for `f` and `y`.

A normal call:

```c
double t=12;
double y[6];
double par[14];
double f[6];
int status=DemoModel_vf(t,y,f,par); /* returns GSL_SUCCESS (0) */
```

This is to allow dynamic loading (dlopen/dlsym) and probing for system size.

Note that the functions created by the script are not minimal, they
declare lots of unused variables. The script declares _all_ variables
that could be used by the function (generally) rather than the ones 
that are actually used.  The removal is left to the compiler.

## Usage

The script has no manual page, but prints a `--help` text:

```sh
$ ./ode.sh -h
```

otputs:

```
ode.sh [-R|-C] [-H] [-N [0-9]+] ModelFile.[vf|zip|tar.gz] > Model_src.[R|c]

OPTIONS with default values
===========================

                          --help|-h  print this help.
                      --c-source|-C  write C source code (default is C).
                      --r-source|-R  write R source code (default is C).
                       --hessian|-H  also write all possible Hessians (ODE-f or output function F, with respect to state variables or parameters)
                   --simplify|-N 10  simplify derivative results 10 times
         --temp|-t /dev/shm/ode_gen  where to write intermediate files (an empty directory).
               --no-clean|--inspect  keep intermediate files to check for errors (default is to clear them).
                        --maxima|-M  use maxima to calculate derivatives
                                     (default is RPN derivative (this package)).
                         --yacas|-Y  use yacas to calculate derivatives
                                     (default is RPN derivative (this package)).
EXAMPLE
=======

	mkdir .tmp
	sh/ode.sh -t ./.tmp --inspect -R myModel.vf > myModel.R
	ls .tmp
```

## Backends

Instead of the derivative function supplied here, it is possible to use `maxima` or `yacas`. The switches are:

|          option | backend choice                           |
|----------------:|:----------------------------------------:|
| `--maxima` `-M` | [maxima](https://maxima.sourceforge.io/) |
|  `--yacas` `-Y` | [yacas](http://www.yacas.org/)           |
|         default | `derivative`                             |

### NOTE

All backends require some output molding to translate it to C source
code (or R, etc.). Each language has its idiosyncrasies (C does not
see `^` as power, while R and maxima do). So, the output must be
checked for errors andverified.

## Output

The script's output is printed on screen and can be redirected into a
file. Standard is internally redirected to `$TMP/error.log`.

The created functions include all Jacobians ($df/dy$, $df/dp$,
$dF/dy$, $dF/dp$), and if the `-H` option is supplied also Hessians
(also all possible combinations, for output functions
$d^2F(t,y;p)/dp_i dp_j$, $d^2F(t,y;p)/dy_i dy_j$ and ODE vector field
$f(t,y;p)$).

## Input Files

This script assumes the presence of text files that describe a dynamic
system, these files can be obtained by `awk` from [SBtab](sbtab.net)
files, and are created automatically by `sbtab_to_vfgen()` in the
[SBtabVFGEN](a-kramer/SBtabVFGEN) package. These files may be archived 
together in `ModelName.tar.gz` or `ModelName.zip`. In that case a typical call would be:

```sh
$ ./ode.sh ModelName.zip > ModelName_gvf.c
```
or
```sh
$ ./ode.sh -R ModelName.zip > ModelName.R
```
to create [R](https://www.r-project.org) code.

The naming of the Model files is somewhat flexible. The names may be
capitalized (`parameters` or `Parameters`). Plural forms are optional
(`ReactionFormula.txt` or `ReactionFormulae.txt`). Longer and shorter
names are possible (`Expression.txt` or `ExpressionFormula.txt`).

In addition, the text files may have names ending in tsv and use tabs
as separators. For files containing math formulae tabs are mandatory
as math can contain spaces. The file can still end in txt, regardless
of field separator used.

```sh
$ tar tf DemoModel.tar.gz
Constant.txt
ExpressionFormula.txt
Function.txt
ODE.txt
Parameters.txt
Variables.txt
```

The above is OK in terms of naming. These _are_ tab-separated files
(`.tsv` is more correct), but on some systems it is easier to create/open
`txt` files because they open the default text editor while files ending
in tsv do not.

Generally, math can contain equalities and inequalities, e.g. `(a<b)`
or `(a==b)`, for this reason, we cannot use `=` as a column
separator. The derivatives of such statements are considered as `0`,
and integration should not go past the point where these relationships
flip. The integrator should stop there and re-start.

*Note on readability*: The goal was to parse these files with standard
posix tools, and a line like `Ca = a*exp(-t)*(t>0) + b*(t<=0)` is
easier to parse if the assignment `=` is replaced by a tab, and then
do `awk -F '\t' '{print $2} file.txt | to_rpn | derivative a'` to
process such lines. We may in the future make it possible to use an
initial `=` and do something like:

```sh
sed -E 's/^\([a-zA-Z][a-zA-Z0-9_]*\)[ ]*=[ ]*/\1\t/'
```

### Constants (optional)

A file named `Constant.txt` or `Constants.txt` (tsv ending should work as well).

Contains a list of named constants, with values separated by a tab or
a space (things that awk accepts as field separator). One constant per
line.

[Example](../examples):

```tsv
N_Avogadro	6.022e+23
```

### Parameters

A file named `Parameters.txt` (or `Parameter.txt`, see above regarding flexibility).

A column of parameter names and default values, separated by tabs, one per line.

The values will be used to write the function
`${ModelName}_default(double t, void *par)`, it will fill the vector
par with the default values.

[Example](../examples):

```tsv
kf_R0	1.0
kr_R0	1.0
kf_R1	1.0
kr_R1	1.0
kf_R2	1.0
kr_R2	1.0
kf_R3	1.0
kr_R3	1.0
kf_R4	1.0
kr_R4	1.0
kf_R5	1.0
kr_R5	1.0
u	1
t_on	0
```

### State Variables

A file named `StateVariables.txt` or `Variables.txt` (and other
possible names). Like Parameters, it contains names and values, as a
table, like all other files (a table for awk). May contain units
(unchecked for consistency), this is for human readers to interpret.


[Example](../examples):

```tsv Variables.txt
A	1000	micromole/liter
B	10	micromole/liter
C	10	micromole/liter
AB	0	micromole/liter
AC	0	micromole/liter
ABC	0	micromole/liter
```

### Expressions (optional)

Expressions can also be called intermediate _assignments_, where a
calculated mathematical expression is assigned to a name, so that it
can be resued.

Example for an expression in general:

```c
/* [...] */
double exp_nxt = exp(-x*t); /* an expression */
/* [...] */
y[0] = -exp_nxt*0.5;
y[1] = +exp_nxt*0.1;
/* and so forth */
```

The contents of the file are: `name \t formula`, one expression per line (tab separated, because tabs are never part of math expressions).

Expression.txt:

```tsv Example.txt
Activation	1.0/(1.0-exp(-(t-t_on)*inv_tau))
```

### Functions (optional)

Functions or rather *Output Functions* will be translated into one c
function that returns a vector of values that depend on a state
vector, parameters and time (and internally on the constants, of
course). These functions can be used to model observable quantities of
an experiment (for such cases where the state of the system cannot be
observed entirely).

This is an example for an output function:

```
/* ode Functions F(t,y;p) */
int DemoModel_func(double t, const double y_[], double *func_, void *par)
{
	double *p_=par;
	if (!y_ || !func_) return 3;
	double inv_tau=1000;
	double kf_R0=p_[0];
	double kr_R0=p_[1];
	double kf_R1=p_[2];
	double kr_R1=p_[3];
	double kf_R2=p_[4];
	double kr_R2=p_[5];
	double kf_R3=p_[6];
	double kr_R3=p_[7];
	double kf_R4=p_[8];
	double kr_R4=p_[9];
	double kf_R5=p_[10];
	double kr_R5=p_[11];
	double u=p_[12];
	double t_on=p_[13];
	double A=y_[0];
	double B=y_[1];
	double C=y_[2];
	double AB=y_[3];
	double AC=y_[4];
	double ABC=y_[5];
	double Activation=1.0/(1.0-exp(-(t-t_on)*inv_tau));
	func_[0] = A+AB+AC+ABC;
	func_[1] = B+AB+ABC;
	func_[2] = C+AC+ABC;
	return GSL_SUCCESS;
}

```

The above file has been created from this input:

```tsv Functions.txt
sumA	A+AB+AC+ABC
sumB	B+AB+ABC
sumC	C+AC+ABC
```

### Transformations

This file describes transformations the system should be capable of
during scheduled events.

This is a convenience function. When the solver hits an event time
$t_e$, the solver is stopped, and the state variables and parameters
are transformed according to this function. Then the solver is reset
and integration continues from this new state. This loop has to be
implemented in the code that uses these functions.

The file has the structure:

```txt
eventName	var	A	A+B
eventName	var	B	0.0
```

All lines with the same event label (column 1) form a group and happen
together.

The fist column names the event, this is used as to form a C `enum`
and a `switch` determines which group of transformations apply. The
second column can be either `var` or `par` to select whether a state
variable or a parameter is to be transformed (this could be determined
by name, but these var/par labels can be pre-fetched and this is
overall faster). The third column names the variable to transform. The
last column is a mathematical expression, the value is assigned to the
previously named variable.

The file is tab separated. The generated event function has the interface:

```C
int modelName_event(double t, double y[], void *par, int eventLabel, double dose)
```

where `eventLabel` is an offset, `0` selects the first event name that
appears in `Transformations.txt`, `1` skips over the first named event
and applies the second, if there is one.

Each value expression (column 4) can also use the value of `dose`,
which is a scalar intensity of the transformative event. This is
optional.

## SED and PERL

Note that this folder contains many `sed` scripts. Hwever, posix `sed`
cannot match word boundaries. BSD and MACOS use `[[:<:]]` and
`[[:>:]]`, but GNU systems use `\<`, `\>`, and `\b` (for which BSD sed
has no equivalent).

It would be nice if MACOS had gsed (GNU sed) reliably, so that we
could just replace all calls to `sed` with `gsed` or `gnu-sed` (or
whatever). But, we cannot assume this.

Instead, we opt to use `perl -p` as a replacement for `sed -[Er]`, as
perl is part of coreutils and has `\b` on all unix-like systems that we
have tested on so far. We don't use perl other than this workaround.
