#!/bin/sh

echo "linked lists"
echo "============"
[ -f ./tests/ll_test ] && ./tests/ll_test

echo "binaries"
echo "========"
echo -n "test: derivative of 'x y *' w.r.t y\t\t\t"
[ -f ./bin/derivative ] && echo "x y *" | bin/derivative y | sed -e 's/0 y [*] x 1 [*] +/success/'
echo -n "test: simplify 'x 0 *'\t\t\t\t"
[ -f ./bin/simplify ] && echo "x 0 *"  | bin/simplify | sed -e 's/0/success/'

