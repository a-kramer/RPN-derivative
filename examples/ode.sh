#!/bin/sh
D=../bin/derivative
S=../bin/simplify
RPN=../bin/to_rpn
IFX=../bin/to_infix

MODEL=${1:-"DemoModel"}

while read sv value unit rest; do
	echo "sv: $sv (with initial value: $value $unit)" 1>&2
	$RPN < ReactionFlux.txt | $D "$sv" | $S 5 | $IFX > Flux_${sv}.txt
	$RPN < Function.txt | $D "$sv" | $S 5 | $IFX > dF_d${sv}.txt
done < Variables.txt


while read par value rest; do
	echo "parameter: $par (with default value: $value)" 1>&2
	$RPN < Function.txt | $D "$par" | $S 5 | $IFX > dF_d${par}.txt
done < Parameters.txt

NF=`wc -l < ReactionFlux.txt`
NV=`wc -l < Variables.txt`
NP=`wc -l < Parameters.txt`

for j in `seq 1 $NV`; do
	cp ODE.txt Jac_${j}.txt
	sv=`awk -v n=$j 'NR == n {print $1}' Variables.txt`
	for i in `seq 1 $NF`; do
		flux_sv=`sed -n -e "${i}p" Flux_${sv}.txt`
		echo "d(flux)/d($sv) = $flux_sv" 1>&2
		sed -i.rm -e "s/ReactionFlux$((i-1))/${flux_sv}/g" Jac_${j}.txt
	done
done

# write a gsl ode model file:

cat<<EOF
#include <stdlib.h>
#include <math.h>
#include <gsl/gsl_errno.h>
#include <gsl/gsl_odeiv2.h>
/* The error code indicates how to pre-allocate memory
 * for output values such as \`f_\`. The _vf function returns
 * the number of state variables, if any of the args are \`NULL\`.
 * GSL_SUCCESS is returned when no error occurred.
 */

/* ode vector field: y'=f(t,y;p), the Activation expression is currently unused */
int ${MODEL}_vf(double t, const double y_[], double f_[], void *par)
{
	double *p_=par;
	if (!y_ || !f_) return ${NV};
EOF
awk '{print "\tdouble " $1 "=" $2 ";"}' Constant.txt
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' Parameters.txt
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' Variables.txt
awk '{print "\tdouble " $1 "=" $2 ";"}' ExpressionFormula.txt
awk '{print "\tdouble ReactionFlux" NR-1 "=" $0 ";"}' ReactionFlux.txt
awk '{print "\tf_[" NR-1 "] = " $0 ";"}' ODE.txt
echo "\treturn GSL_SUCCESS;"
echo "}"

cat<<EOF
/* ode Jacobian df(t,y;p)/dy */
int ${MODEL}_jac(double t, const double y_[], double *jac_, double *dfdt_, void *par)
{
	double *p_=par;
	if (!y_ || !jac_) return ${NV}*${NV};
EOF
awk '{print "\tdouble " $1 "=" $2 ";"}' Constant.txt
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' Parameters.txt
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' Variables.txt
awk '{print "\tdouble " $1 "=" $2 ";"}' ExpressionFormula.txt
for j in `seq 1 $NV`; do
	echo "/* column $j (df/dy_$((j-1))) */"
	awk -v n=$NV -v j=$j '{print "\tjac_[" (NR-1)*n + (j-1) "] = " $0 ";"}' Jac_${j}.txt
done
echo "\treturn GSL_SUCCESS;"
echo "}"



cat<<EOF
/* ode Functions F(t,y;p) */
int ${MODEL}_func(double t, const double y_[], double *func_, void *par)
{
	double *p_=par;
	if (!y_ || !func_) return `wc -l < Function.txt`;
EOF
awk '{print "\tdouble " $1 "=" $2 ";"}' Constant.txt
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' Parameters.txt
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' Variables.txt
awk '{print "\tdouble " $1 "=" $2 ";"}' ExpressionFormula.txt
awk '{print "\tfunc_[" (NR-1) "] = " $0 ";"}' Function.txt
echo "\treturn GSL_SUCCESS;"
echo "}"


cat<<EOF
/* ode default parameters */
int ${MODEL}_default(double t, void *par)
{
	double *p_=par;
	if (!p_) return `wc -l < Parameters.txt`;
EOF
awk '{print "\tdouble " $1 "=" $2 ";"}' Constant.txt
awk '{print "\tp_[" NR-1 "] = " $2 ";"}' Parameters.txt
printf "\treturn GSL_SUCCESS;\n}\n"

cat<<EOF
/* ode initial values */
int ${MODEL}_init(double t, double *y_, void *par)
{
	double *p_=par;
	if (!y_) return ${NV};
EOF
awk '{print "\tdouble " $1 "=" $2 ";"}' Constant.txt
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' Parameters.txt
printf "\t/* the initial value of y may depend on the parameters. */\n"
awk '{print "\ty_[" NR-1 "] = " $2 ";"}' Variables.txt
printf "\treturn GSL_SUCCESS;\n}\n"
