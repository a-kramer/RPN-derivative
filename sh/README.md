# ODE code Generator for the GSL solver suite

The [GNU Scientific
Library](https://www.gnu.org/software/gsl/doc/html/ode-initval.html)
defines function interfaces for an ODE system.

The script [ode.sh](./ode.sh) generates these functions.

In addition, the functions return the length of the return buffer they
expect when called with NULL pointers instead of allocated output
buffers. For the demo model in [../examples/](../examples), this is:

```c
/* the DemoModel has 6 state variables: A,B,C,AB,AC, and ABC */
double t=12;
int status=DemoModel_vf(t,NULL,NULL,NULL); /* returns 6 */
```

whereas:

```c
double t=12;
double y[6];
double par[14];
double f[6];
int status=DemoModel_vf(t,y,f,par); /* returns GSL_SUCCESS (0) */
```

This is to allow dynamic loading (dlopen/dlsym) and probing for system size.

## Input Files

This script assumes the presence of text files that describe a dynamic
system, these files can be obtained by `awk` from [SBtab](sbtab.net)
files, and are created automatically by `sbtab_to_vfgen()` in the
[SBtabVFGEN](a-kramer/SBtabVFGEN) package.

We are using models in the area of biochemical reaction systems, so
some of the optional files are useful for that specific field (ReactionFluxes).

The naming of the files is somewhat flexible. The names may be
capitalized (`parameters` or `Parameters`). Plural forms are optional
(`ReactionFormula.txt` or `ReactionFormulae.txt`). Longer and shorter
names are possible (`Expression.txt` or `ExpressionFormula.txt`). 

In addition, the text files may have names ending in tsv and use tabs
as separators.

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

```
A 1000 micromole/liter
B 10 micromole/liter
C 10 micromole/liter
AB 0 micromole/liter
AC 0 micromole/liter
ABC 0 micromole/liter
```

### Expressions (optional)

