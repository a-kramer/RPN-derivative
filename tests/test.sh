#!/bin/sh

echo "linked lists"
echo "============"
[ -f ./tests/ll_test ] && ./tests/ll_test
W1=35
W2=25

echo "binaries"
echo "========"
echo "(1) compare to known solutions"

printf "test 1a: %${W1}s\t" "derivative of 'x y *' w.r.t y"
[ -f bin/derivative ] && RES=`echo "x y *" | bin/derivative y `
printf "%${W2}s" "$RES"
[ "$RES" = '0 y * x 1 * +' ] && echo ' \e[32msuccess\e[0m' || echo ' \e[31mfailure\e[0m'

printf "test 1b: %${W1}s\t" "simplify 'x 0 *'"
[ -f bin/simplify ] && RES=`echo "x 0 *"  | bin/simplify `
printf "%${W2}s" "$RES"
[ "$RES" -eq 0 ] && echo ' \e[32msuccess\e[0m' || echo ' \e[31mfailure\e[0m'

printf "test 1c: %${W1}s\t" "simplify 'x 1 * 0 +'"
[ -f bin/simplify ] && RES=`echo "x 1 * 0 +"  | bin/simplify 2`
printf "%${W2}s" "$RES"
[ "$RES" = 'x' ] && echo ' \e[32msuccess\e[0m' || echo ' \e[31mfailure\e[0m'

printf "test 1d: %${W1}s\t" "simplify 'x 0 * @sin @cos'"
[ -f bin/simplify ] && RES=`echo "x 0 * @sin @cos"  | bin/simplify 4 `
printf "%${W2}s" "$RES"
[ "$RES" -eq 1 ] && echo ' \e[32msuccess\e[0m' || echo ' \e[31mfailure\e[0m'

printf "test 1e: %${W1}s\t" "derivative '-1 a * t * @exp'"
[ -f bin/derivative ] && RES=`echo "-1 a * t * @exp"  | bin/derivative t | bin/simplify 4`
printf "%${W2}s" "$RES"
[ "$RES" = '-1 a * t * @exp -1 a * *' ] && echo ' \e[32msuccess\e[0m' || echo ' \e[31mfailure\e[0m'

printf "test 1f: %${W1}s\t" "to_rpn '@exp(-1*a*t)'"
[ -f bin/to_rpn ] && RES=`echo '@exp(-1*a*t)' | bin/to_rpn`
printf "%${W2}s" "$RES"
[ "$RES" = '-1 a * t * @exp' ] && echo ' \e[32msuccess\e[0m' || echo ' \e[31mfailure\e[0m'

echo "(2) compare to numerical solutions"
printf "test 2a: %${W1}s\t" "derivative of '-1 a * t 3 @pow *'"
[ -f bin/derivative ] && D1=`echo "-1 a * t 3 @pow *"  | bin/derivative t | bin/simplify 4 | tests/eval.sh t=2 a=0.1`
echo "$D1"
printf "test 2a: %${W1}s\t" "finite diff. '-1 a * t 3 @pow *'"
[ -f tests/numerical.sh ] && D2=`echo "-1 a * t 3 @pow *" | tests/numerical.sh t 2 0.0001 | tests/eval.sh a=0.1`
echo "$D2"
RDIFF=`echo "${D1} ${D2} - d * v 100 * ${D1} ${D2} + 2 / d * v / p" | sed -E -e 's/-([0-9.]+)/_\1/g' | dc`
printf "test 2a: %${W1}s\t" "relative error $RDIFF %" 
[ "$RDIFF" -eq 0 ] && echo ' \e[32msuccess\e[0m' || echo ' \e[31mfailure\e[0m'

