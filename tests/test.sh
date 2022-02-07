#!/bin/sh

[ -f ./tests/ll_test ] && ./tests/ll_test
[ -f ./bin/derivative ] && echo "x y *" | bin/derivative y | sed -e 's/0 y [*] x 1 [*] +/success/'

