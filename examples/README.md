# Example Model

This ODE model is meant to demonstrate how the programs in this
repository can be useful. Here, we lay out the meaning of each text
file in this folder. The next section is about the class of this model
and its interpretation (there is no file that describes the reactions
listed below). The shell script [ode.sh](ode.sh) orchestrates the
creation of a gsl_odeiv2 C source file for this model. The script
creates some intermediate files that can be inspected afterwards.

Usage: 

```sh
$ cd example 
$ ./ode.sh > DemoModel_gvf.c
```

## Reactions

The model represents the change in concentration of three substances
in a well mixed homogeneous container. The reaction formulae are:

```
A + B <=> AB
A + C <=> AC
AB + C <=> ABC
AC + B <=> ABC
```

All single letter variables are primary substances that within this
system are indivisible. Multiple letter variables represent a complex
of constituents, e.g. `ABC` contains `A`, `B`, and `C` bound into one
molecule. The `+` signs above are symbolic and mean something like
_react together_.

Each word potentially corresponds to a state variable, unless some
method of model reduction is used before writing the ODE. 

The values of the state variables are the concentrations of the
reacting molecules. We will no distinguish between the molecule symbol
`A` and the symbol of the state variable `A` as they represent aspects
of the same entity (sometimes authors make the choice that `A` is the
name of the molecule and `[A]` is it's concentration).

Each direction of a reaction corresponds to a reaction flux, informed
by a reaction kinetic (e.g. the law of mass action).

## ODE

Each line in [ODE.txt](ODE.txt) represents a line of an ordinary
differential equation (`dy[i]/dt`). It is phrased in terms of reaction
fluxes (algebraic expressions of state variables and parameters).

## Variables

The file [Variables.txt](Variables.txt) lists all state variable
names, one per line.

## Jacobian Files

The [ode.sh](ode.sh) script writes the columns of the Jacobian matrix
into files named `Jac_%i.txt` where the placeholder `%i` corresponds
to the column number.

The derivative `df[2](t,y)/dy[3]` can be found in file `Jac_3.txt` on
line 2 (here all numbering starts with 1). 

### Fluxes and their derivatives

To create the Jacobian files, the ode script first creates the
_reaction flux_ derivatives, named `Flux_${sv}.txt` where `$sv` is
any of the state variables, so `d(ReactionFlux0(t,y))/dC` can be found
in file [Flux_C.txt](Flux_C.txt) on line 1.

The fluxes themselves are stored in
[ReactionFlux.txt](ReactionFlux.txt).

## Note on Conservation Laws

The number of state variables can be reduced by observing that the
variables are not algebraically independent. But, we won't do this
here.
