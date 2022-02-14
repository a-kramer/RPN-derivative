#!/bin/sh

echo "linked lists"
echo "============"
[ -f ./tests/ll_test ] && ./tests/ll_test
W=40;
echo "binaries"
echo "========"
echo "(1) compare to known solutions"

printf "test: %${W}s\t\e[32m" "derivative of 'x y *' w.r.t y"
[ -f ./bin/derivative ] && echo "x y *" | bin/derivative y | sed -e 's/0 y [*] x 1 [*] +/success/'
echo -n "\e[0m"

printf "test: %${W}s\t\e[32m" "simplify 'x 0 *'"
[ -f ./bin/simplify ] && echo "x 0 *"  | bin/simplify | sed -e 's/^0[ ]*$/success/'
echo -n "\e[0m"

printf "test: %${W}s\t\e[32m" "simplify 'x 1 * 0 +'"
[ -f ./bin/simplify ] && echo "x 1 * 0 +"  | bin/simplify 2 | sed -e 's/^x[ ]*$/success/'
echo -n "\e[0m"

printf "test: %${W}s\t\e[32m" "simplify 'x 0 * @sin @cos'"
[ -f ./bin/simplify ] && echo "x 0 * @sin @cos"  | bin/simplify 4 | sed -e 's/^1[ ]*$/success/'
echo -n "\e[0m"

printf "test: %${W}s\t\e[32m" "derivative '-1 a * t * @exp'"
[ -f ./bin/derivative ] && echo "-1 a * t * @exp"  | bin/derivative t | bin/simplify 4 | sed -e 's/^-1 a [*] t [*] @exp -1 a [*] [*][ ]*$/success/'
echo -n "\e[0m"

echo "(2) compare to numerical solutions"
printf "test: %${W}s\t" "derivative of '-1 a * t 3 @pow *'"
[ -f bin/derivative ] && echo "-1 a * t 3 @pow *"  | bin/derivative t | bin/simplify 4 | tests/eval.sh t=2 a=0.1

printf "test: %${W}s\t" "finite diff. '-1 a * t 3 @pow *'"
[ -f tests/numerical.sh ] && echo "-1 a * t 3 @pow *" | tests/numerical.sh t 2 0.0001 | tests/eval.sh a=0.1

