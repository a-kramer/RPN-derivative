#!/bin/sh
D=../bin/derivative
S=../bin/simplify
RPN=../bin/to_rpn
IFX=../bin/to_infix

MODEL=${1:-"DemoModel"}

while read sv; do
	echo "sv: $sv" 1>&2
	$RPN < ReactionFlux.txt | $D "$sv" | $S 5 | $IFX > Flux_${sv}.txt
done < Variables.txt

NF=`wc -l < ReactionFlux.txt`
NV=`wc -l < Variables.txt`


for j in `seq 1 $NV`; do
	cp ODE.txt Jac_${j}.txt
	sv=`sed -n "${j}p" Variables.txt`
	for i in `seq 1 $NF`; do
		flux_sv=`sed -n -e "${i}p" Flux_${sv}.txt`
		echo "d(flux)/d($sv) = $flux_sv" 1>&2
		sed -i.rm -e "s/ReactionFlux$((i-1))/${flux_sv}/g" Jac_${j}.txt
	done
done

# write a gsl ode model file:

cat<<EOF
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

awk '{print "\tdouble " $0 "=p_[" NR-1 "];"}' ParNames.txt
awk '{print "\tdouble " $0 "=y_[" NR-1 "];"}' Variables.txt
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

awk '{print "\tdouble " $0 "=p_[" NR-1 "];"}' ParNames.txt
awk '{print "\tdouble " $0 "=y_[" NR-1 "];"}' Variables.txt
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

awk '{print "\tdouble " $0 "=p_[" NR-1 "];"}' ParNames.txt
awk '{print "\tdouble " $0 "=y_[" NR-1 "];"}' Variables.txt
awk '{print "\tdouble " $1 "=" $2 ";"}' ExpressionFormula.txt
awk '{print "\tfunc_[" (NR-1) "] = " $0 ";"}' Function.txt
echo "\treturn GSL_SUCCESS;"
echo "}"


