#!/bin/sh

printf "## R matrices are filled column-wise by default\n"
printf "jac <- matrix(c(dfdx1, \n\tdfdx2))\n" > jac.R
printf "x1*x2/(x1+x2)\nx1*x2*x3*x4" > f.txt

for x in x1 x2 ; do
	## the awk command just prints the result as a comma separated R character array: dfdx[12] <- c(LIST)
	to_rpn < f.txt | derivative $x | simplify 4 | to_infix | awk -v x=$x -v n=2 'BEGIN {printf "dfd%s <- c(", x}; {printf("%s%c", $0, NR<n?",":"")}; END {print ")"}' > dfd$x.R
done

cat dfdx*.R jac.R
