#!/bin/bash

# the only precaution we take is the case of math-expressions having
# step-function characteristics, things like: (x < y), or (a >= b)
# step functions Θ(x) have δ(x) as their derivative, which is probably
# never useful in systems-biology modeling of the kind that we do.
# So, we do this: d(a > 0)/da = 0.0 for all a (and so forth). 
Derivative () {
	awk -F '\t' '{print $2}' | perl -p -e 's/[=<>]+/*0.0*/g;' | perl -p "${dir:-.}/math.sed" | to_rpn | derivative $1 | simplify ${N:-20} | to_infix
}

