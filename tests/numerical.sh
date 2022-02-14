#!/bin/sh

# here we read an expression from stdin and evaluate it using finite
# differences (f(x+h)-f(x-h))/(2*h)

# name of the variable
var=${1:-x}
val=${2:-0}
h=${3:-0.001}

while read rpn; do
	#echo "${rpn}"
	x_plus_h=`dc -e "${val} ${h} + p"`
	x_minus_h=`dc -e "${val} ${h} - p"`
	#echo "${x_plus_h}, ${x_minus_h}"
	fx_plus_h=`echo "${rpn}" | sed -e "s/${var}/${x_plus_h}/g"`
	fx_minus_h=`echo "${rpn}" | sed -e "s/${var}/${x_minus_h}/g"`
	#echo "${fx_plus_h}, ${fx_minus_h}"
	echo "${fx_plus_h} ${fx_minus_h} - 2 $h * /"	
done
