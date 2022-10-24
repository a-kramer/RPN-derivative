# ODE code Generator for the GSL solver suite `<gsl/gsl_odeiv2>`

The [GNU Scientific
Library](https://www.gnu.org/software/gsl/doc/html/ode-initval.html)
defines function interfaces for an ordinary differential equation (ODE) system.

$$ \dot y = f(t,y;p) $$

$$ y(t_0) = y_0 $$

The script [ode.sh](./ode.sh) generates these right-hand-side functions $f$ in C or R (perhaps more languages later). Additionally the script writes an analytical *Jacobian* $df/dy$, *parameter Jacobian* $df/dp$, and an output function that models *observable quanities*.

**Note on platforms** we try to make this script run with GNU tools as well as BSD tools (i.e.: options to *find*, *awk*, and *sed*).

**Note on C functions:** In addition to the requirements of the 
GNU scientific library, the functions return the length of the return buffer they
expect when called with NULL pointers instead of allocated output
buffers. For the demo model in [../examples/](../examples), this is:

```c
/* the DemoModel has 6 state variables: A,B,C,AB,AC, and ABC */
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
The above is OK in terms of naming.

### Constants (optional)

A file named `Constant.txt` or `Constants.txt` (tsv ending should work as well).

Contains a list of named constants, with values separated by a tab or
a space (things that awk accepts as field separator). One constant per
line.

[Example](../examples):

```
inv_tau 1000
```

### Parameters

A file named `Parameters.txt` (or `Parameter.txt`, see above regarding flexibility).

A column of parameter names and default values, separated by tabs or spaces, one per line.

The values will be used to write the function
`${ModelName}_default(double t, void *par)`, it will fill the vector
par with the default values.

[Example](../examples):

```
kf_R0 1.0
kr_R0 1.0
kf_R1 1.0
kr_R1 1.0
kf_R2 1.0
kr_R2 1.0
kf_R3 1.0
kr_R3 1.0
kf_R4 1.0
kr_R4 1.0
kf_R5 1.0
kr_R5 1.0
u 1
t_on 0
```

### State Variables

A file named `StateVariables.txt` or `Variables.txt` (and other
possible names). Like Parameters, it contains names and values, as a
table, like all other files (a table for awk). May contain units
(unchecked for consistency), this is for human readers to interpret.


[Example](../examples):

```tsv Variables.txt
A 1000 micromole/liter
B 10 micromole/liter
C 10 micromole/liter
AB 0 micromole/liter
AC 0 micromole/liter
ABC 0 micromole/liter
```

### Expressions (optional)

Expressions can also be called assignments, where a calculated
mathematical expression is assigned to a name, so that it can be
resued.

Example for an expression in general:

```c
/* [...] */
double exp_nxt = exp(-x*t); /* an expression */
/* [...] */
y[0] = -exp_nxt*0.5;
y[1] = +exp_nxt*0.1;
/* and so forth */
```

(or whatever).

The contents of the file are: `name␣formula`, one expression per line (tab or space, both work).

Expression.txt:

```tsv Example.txt
Activation	1/(1-exp(-(t-t_on)*inv_tau))
```

### Functions (optional)

Functions or rather *Output Functions* will be translated into on c
function that returns a vector of values that depend on a state
vector, parameters and time. These functions can be used to model
observable quantities of an experiment (for such cases where the state
of the system cannot be observed entirely).

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
        double Activation=1/(1-exp(-(t-t_on)*inv_tau));
        func_[0] = A+AB+AC+ABC;
        func_[1] = B+AB+ABC;
        func_[2] = C+AC+ABC;
        return GSL_SUCCESS;
}

```

The above file has been created from this input:

```tsv Functions.txt
A+AB+AC+ABC
B+AB+ABC
C+AC+ABC
```

