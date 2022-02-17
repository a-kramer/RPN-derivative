#!/bin/sh

echo "linked lists"
echo "============"
[ -f ./tests/ll_test ] && ./tests/ll_test
W1=35
W2=25

cat<<EOF

binaries
========

(1) compare to known solutions

EOF
# test_summary "test name" "test result" "expected result"
test_string_eq(){
# test
	printf "%${W1}s  " "$1"
# result
	printf "%${W2}s  " "$2"
# expected result
	printf "%${W2}s  " "$3"
# success or failure
	[ "$2" = "$3" ] && echo ' \e[32msuccess\e[0m' || echo ' \e[31mfailure\e[0m'
}

# test_summary "test name" "test result" "expected result"
test_num_eq(){
# test
	printf "%${W1}s  " "$1"
# result
	printf "%${W2}s  " "$2"
#expected result
	printf "%${W2}s  " "$3"
# success or failure
	[ "$2" -eq "$3" ] && echo ' \e[32msuccess\e[0m' || echo ' \e[31mfailure\e[0m'
}

# test_summary "test name" "d1" "d2"
test_float_eq(){
# test
	printf "%${W1}s  " "$1"
# result
	printf "%${W2}s  " "$2"
#expected result
	printf "%${W2}s  " "$3"
# success or failure
	RDIFF=`echo "6 k ${2} ${3} - d * v 100 * ${2} ${3} + 2 / d * v / p" | sed -E -e 's/-([0-9.]+)/_\1/g' | dc`
	RDIFFp=`printf "%3.0f" "${RDIFF}"`
	[ "$RDIFFp" -le 1 ] && echo " \e[32m${RDIFFp}% error\e[0m" || echo " \e[31m${RDIFFp}% error\e[0m"

}


printf "%${W1}s  %${W2}s  %${W2}s\n" "TEST" "RESULT" "EXPECTED RESULT"

[ -f bin/derivative ] && RES=`echo "x y *" | bin/derivative y `
test_string_eq "derivative of 'x y *' w.r.t y" "$RES" '0 y * x 1 * +'

[ -f bin/simplify ] && RES=`echo "x 0 *"  | bin/simplify `
test_num_eq "simplify 'x 0 *'" "$RES" 0

[ -f bin/simplify ] && RES=`echo "x 1 * 0 +"  | bin/simplify 2`
test_string_eq "simplify 'x 1 * 0 +'" "$RES" 'x'

[ -f bin/simplify ] && RES=`echo "x 0 * @sin @cos"  | bin/simplify 4 `
test_num_eq "simplify 'x 0 * @sin @cos'"  "$RES" 1

[ -f bin/derivative ] && RES=`echo "-1 a * t * @exp"  | bin/derivative t | bin/simplify 4`
test_string_eq "derivative '-1 a * t * @exp'" "$RES" '-1 a * t * @exp -1 a * *'

[ -f bin/to_rpn ] && RES=`echo '@exp(-1*a*t)' | bin/to_rpn`
test_string_eq "to_rpn '@exp(-1*a*t)'" "$RES" '-1 a * t * @exp'

cat<<EOF 

(2) compare to numerical solutions via 'dc'
    `whch dc`
    math functions cannot be used
    only operators: * + - / ^

EOF

printf "%${W1}s  %${W2}s  %${W2}s\n" "TEST" "DERIVATIVE" "FINITE DIFFERENCES"

FUNC="-1 a * t 3 @pow *"
t=3
[ -f bin/derivative ] && D1=`echo "$FUNC"  | bin/derivative t | bin/simplify 4 | tests/eval.sh t=$t a=0.1`
[ -f tests/numerical.sh ] && D2=`echo "$FUNC" | tests/numerical.sh t $t 0.0001 | tests/eval.sh a=0.1`
test_float_eq "'$FUNC' at t=$t" "$D1" "$D2" 

FUNC="t t * a t t * + /"
t=3
[ -f bin/derivative ] && D1=`echo "$FUNC"  | bin/derivative t | bin/simplify 4 | tests/eval.sh t=$t a=1`
[ -f tests/numerical.sh ] && D2=`echo "$FUNC" | tests/numerical.sh t $t 0.001 | tests/eval.sh a=1`
test_float_eq "'$FUNC' at t=$t" "$D1" "$D2" 

FUNC="1 t + t t * 2 / + t 3 @pow 6 / + t 4 @pow 24 / +"
t=0.1
[ -f bin/derivative ] && D1=`echo "$FUNC"  | bin/derivative t | bin/simplify 4 | tests/eval.sh t=$t`
[ -f tests/numerical.sh ] && D2=`echo "$FUNC" | tests/numerical.sh t $t 0.001 | tests/eval.sh`
test_float_eq "taylor(@exp,t,4) at t=0.1" "$D1" "$D2" 

