#!/bin/sh

alias D=bin/derivative
alias SY=bin/simplify
alias RPN=bin/to_rpn
alias IFX=bin/to_infix

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

[ -f bin/simplify ] && RES=`echo "x 0 *"  | SY `
test_num_eq "simplify 'x 0 *'" "$RES" 0

[ -f bin/simplify ] && RES=`echo "x 1 * 0 +"  | SY 2`
test_string_eq "simplify 'x 1 * 0 +'" "$RES" 'x'

[ -f bin/simplify ] && RES=`echo "x 0 * @sin @cos"  | SY 4 `
test_num_eq "simplify 'x 0 * @sin @cos'"  "$RES" 1

[ -f bin/derivative ] && RES=`echo "-1 a * t * @exp"  | D t | SY 4`
test_string_eq "derivative of '-1 a * t * @exp'" "$RES" '-1 a * t * @exp -1 a * *'

[ -f bin/derivative ] && RES=`echo "x y *" | D y `
test_string_eq "derivative of 'x y *' w.r.t y" "$RES" '0 y * x 1 * +'

[ -f bin/derivative ] && RES=`printf "x y *" | D y `
test_string_eq 'missing newline byte is fine' "$RES" '0 y * x 1 * +'

[ -f bin/to_rpn ] && RES=`printf "x" | RPN `
test_string_eq 'input can be without operators' "$RES" 'x'

[ -f bin/to_rpn ] && RES=`echo 'a+b' | RPN`
test_string_eq "rpn of 'a+b'" "$RES" 'a b +'

[ -f bin/to_rpn ] && RES=`echo '@exp(-1*a*t)' | RPN`
test_string_eq "rpn of '@exp(-1*a*t)'" "$RES" '-1 a * t * @exp'

[ -f bin/to_rpn ] && RES=`echo ' a ' | RPN`
test_string_eq "rpn of ' a '" "$RES" 'a'

[ -f bin/to_infix ] && RES=`echo 'a b +' | IFX`
test_string_eq "'a b +' as infix" "$RES" '(a+b)'

[ -f bin/to_infix ] && RES=`echo 'a b + a b - /' | IFX`
test_string_eq "'a b + a b - /' as infix" "$RES" '((a+b)/(a-b))'

[ -f bin/to_infix ] && RES=`echo 'a b - 2 @pow' | IFX`
test_string_eq "'a b - 2 @pow' as infix" "$RES" 'pow((a-b),2)'


cat<<EOF

(2) compare to numerical solutions via 'dc'
    `which dc`
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


OCTAVE="`which octave-cli`"
if [ "$OCTAVE" ]; then
cat<<EOF

(3a) compare to numerical solutions via 'octave'
     `which octave`
     math functions are allowed
     conversion to infix notation required
EOF

 F="@exp(-0.5*@pow(x-m,2)/(s*s))"
 F_OCTAVE=`echo "$F" | sed -E -e 's/@//g' -e 's/pow\(([^,]+),([^\)]+)\)/(\1)^(\2)/g'`
 DF=`echo "$F" | RPN | D x | SY 6 | IFX`
 FIN_DIFF=`echo "m=1; s=0.8; f=@(x) $F_OCTAVE; x0=2; h=sqrt(abs(f(x0))*1e-14); assert((h/x0)<1e-2 && (h/x0)>1e-15); printf('%g',(f(x0+h)-f(x0-h))/(2*h));" | octave-cli`
 DF_OCTAVE=`echo "$DF" | sed -E -e 's/@//g' -e 's/pow\(([^,]+),([^\)]+)\)/(\1)^(\2)/g'`
 EXACT=`echo "m=1; s=0.8; df=@(x) $DF_OCTAVE; x0=2; printf('%g',df(x0));" | octave-cli`
 printf "%${W1}s  %${W2}s  %${W2}s\n" "TEST" "DERIVATIVE" "FINITE DIFFERENCES"
 test_float_eq "$F | x=2" "$EXACT" "$FIN_DIFF"
fi

RSCRIPT=`which Rscript`
if [ "$RSCRIPT" ]; then
cat<<EOF

(3b) compare to numerical solutions via 'R'
     `which Rscript`
     math functions are allowed
     conversion to infix notation required
EOF

 F="@exp(-0.5*@pow(x-m,2)/(s*s))"
 F_R=`echo "$F" | sed -E -e 's/@//g' -e 's/pow\(([^,]+),([^\)]+)\)/(\1)^(\2)/g'`
 DF=`echo "$F" | RPN | D x | SY 6 | IFX`
 FIN_DIFF=`Rscript -e "m<-1; s<-0.8; f<-function(x) {return($F_R)}; x0<-2; h<-sqrt(abs(f(x0))*1e-14); stopifnot((h/x0)<1e-2 && (h/x0)>1e-15); cat(sprintf('%g',(f(x0+h)-f(x0-h))/(2*h)))"`
 DF_R=`echo "$DF" | sed -E -e 's/@//g' -e 's/pow\(([^,]+),([^\)]+)\)/(\1)^(\2)/g'`
 EXACT=`Rscript -e "m<-1; s<-0.8; df<- function(x) {return($DF_R)}; x0<-2; cat(sprintf('%g',df(x0)))"`
 printf "%${W1}s  %${W2}s  %${W2}s\n" "TEST" "DERIVATIVE" "FINITE DIFFERENCES"
 test_float_eq "$F | x=2" "$EXACT" "$FIN_DIFF"
fi

