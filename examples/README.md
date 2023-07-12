# Examples

This follder contains a very small example Model: a small chemical
reaction network which models the concentrations `A`, `B`, and `C`
over time.

# Example Model

This ODE model is meant to demonstrate how the programs in this
repository can be useful. Here, we lay out the meaning of each text
file in this folder. The next section is about the class of this model
and its interpretation (there is no file that describes the reactions
listed below). The shell script [ode.sh](ode.sh) orchestrates the
creation of a gsl_odeiv2 C source file for this model by creating some
intermediate files with derivatives that can be inspected afterwards.

Usage:

```sh
$ cd examples
$ ../sh/ode.sh --c-source DemoModel.tar.gz > DemoModel_gvf.c
```

The script creates intermediate file that may be helpful to find
errors (`/dev/shm/ode_gen` on GNU/Linux).

## Reactions

The model represents the change in concentration of three substances
in a well mixed homogeneous container. The reaction formulae are:

```
  A + B <=> AB
  A + C <=> AC
 AB + C <=> ABC
 AC + B <=> ABC
```

Each word (or symbol) potentially corresponds to a state variable,
unless some method of model reduction is used before writing the ODE.

The values of the state variables are the concentrations of the
reacting molecules. We will not distinguish between the
molecule/concentration symbol `A` and the symbol of the state variable
`A` as they represent aspects of the same entity (others make the
choice that `A` is the name of the molecule and `[A]` is it's
concentration).

Each direction of a reaction corresponds to a reaction flux, informed
by a reaction kinetic (e.g. the law of mass action).

## ODE

Each line in [ODE.txt](./ODE.txt) represents a line of an ordinary
differential equation (a value of `dy[i]/dt`).

## Variables

The file [Variables.txt](Variables.txt) lists all state variable
names, one per line, as well as (default) initial conditions.

## Jacobian Files

The [ode.sh](../sh/ode.sh) script writes the columns of the Jacobian matrix
into intermediate files, by column.

## Note on Conservation Laws

The number of state variables can be reduced by observing that the
variables are not algebraically independent. But, we won't do this
here.
