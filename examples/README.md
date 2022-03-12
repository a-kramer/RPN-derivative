# Example Model

This ODE model is meant to demonstrate how the programs in this
repository can be useful.

## Reactions

The model represents the change in concentration of three substances
in a well mixed homogenious container. The reaction formulae are:

```
A + B <=> AB
A + C <=> AC
AB + C <=> ABC
AC + B <=> ABC
```

Here `ABC` represents a complex that contains `A`, `B`, and `C` (each
word is potentially a state variable).


## Conservation Laws

The number of conservation laws can be reduced by observing that the
variables are not independent.
