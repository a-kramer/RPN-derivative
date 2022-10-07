#!/bin/sh

set -u

MODEL=${1:-"DemoModel"}
N=${2:-6}
TMP=${3:-/dev/shm/ode_gen}

# make sure the temp folder exists
[ -d "${TMP}" ] || mkdir "${TMP}"

# print some help if something is not right
if [ -f "Variables.txt" -a -f "Parameters.txt" -a -f "ReactionFlux.txt" -a -f "ODE.txt" ]; then
	echo "[$0] Using the files in this folder:" 1>&2
	ls *.txt 1>&2
else
(
	echo "Usage: $0 [ModelName] [N] [TMP]"
	echo;
	echo "This assumes that `pwd` contains the four mandatory files:"
	echo "     Variables.txt   the names of all state variables, one per line, "
	echo "                     with initial value, and a unit of measurement, separated by a tab"
	echo "    Parameters.txt   parameter names, one per line"
	echo "  ReactionFlux.txt   mathematical formulae of how each flux is calculated using "
	echo "                     expressions, state variables, parameters, and constants"
	echo "           ODE.txt   mathematical formulae of how the ODE's right hand side is calculated using "
	echo "                     fluxes, expressions, state variables, parameters, and constants"
	echo "                     ReactionFluxes can be used by automatic names 'ReactionFlux[0-9]+', starting with 'ReactionFlux0'"
	echo "                     e.g.: ReactionFlux0-ReactionFlux1+ReactionFlux13"
	echo;
	echo "Some files are optional:"
	echo "     Constants.txt   names and values of constants, one name value pair per line, "
	echo "                     separated by a tab"
	echo "    Expression.txt   a file with expression names and formulae (right hand side) comprising "
	echo "                     constants, parameters, and state variables, separated by either '=' or tab"
	echo "      Function.txt   a file with named expressions (one per line) that define (observable) model outputs, "
	echo "                     name and value sepearated by a tab."
	echo;
	echo "Some temporary files will be created in ${TMP}, this location can be changed by setting the third command line argument."
	echo "All derivatives will be simplified N times. (simplication means: «x+0=x» or «x*1=x», and similar things)"
	echo "The default model name is 'DemoModel'."
) 1>&2
fi

if [ -z `which derivative` ]; then
	echo "[warning] the 'derivative' program is not installed."
	echo "	if you prefer to use a compiled but not installed copy,"
	echo "	then you can use an alias (named 'derivative'):"
	echo "		alias derivative='./bin/derivative'"
fi

while read sv value unit rest; do
	echo "sv: $sv (with initial value: $value $unit)" 1>&2
	to_rpn < ReactionFlux.txt | derivative "$sv" | simplify $N | to_infix > "${TMP}/dFlux_d${sv}.txt"
	[ -f Function.txt ] && to_rpn < Function.txt | derivative "$sv" | simplify $N | to_infix > "${TMP}/dFunction_d${sv}.txt"
done < Variables.txt

while read par value rest; do
	echo "parameter: $par (with default value: $value)" 1>&2
	[ -f Function.txt ] && to_rpn < Function.txt | derivative "$par" | simplify $N | to_infix > "${TMP}/dFunction_d${par}.tx"
done < Parameters.txt

NF=`wc -l < ReactionFlux.txt`
NV=`wc -l < Variables.txt`
NP=`wc -l < Parameters.txt`
if [ -f Expression.txt ] ; then
	NE=`wc -l < Expression.txt`
else
	NE=0
fi

# make a copy of ODE.txt, but with all Fluxes substituted
EXODE="${TMP}/explicit_ode.txt"
sed -r -e 's/(exp|sin|cos|tan)/@\1/g' -e 's/^-/0 - /g' ODE.txt > "$EXODE"
for j in `seq $NF -1 1`; do
	flux=`sed -n -e "${j}p" ReactionFlux.txt`
	sed -i.rm -e "s|ReactionFlux$((j-1))|(${flux})|g" "$EXODE"
done

if [ -f Expression.txt ]; then
	for j in `seq $NE -1 1`; do
		expr=`sed -n -e "${j}p" Expression.txt`
		sed -i.rm -e "s|ReactionFlux$((j-1))|(${expr})|g" "$EXODE"
	done
fi

for j in `seq 1 $NV`; do
	sv=`sed -n -e "${j}p" Variables.txt`
	for i in `seq 1 $NV`; do
		to_rpn < "$EXODE" | derivative $sv | simplify $N | to_infix > "${TMP}/Jac_Column_${j}.txt"
	done
done

for j in `seq 1 $NP`; do
	par=`sed -n -e "${j}p" Parameters.txt`
	for i in `seq 1 $NV`; do
		to_rpn < "$EXODE" | derivative $par | simplify $N | to_infix > "${TMP}/Jacp_Column_${j}.txt"
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
 * evaluation errors can be indicated by negative return values.
 * GSL_SUCCESS (0) is returned when no error occurred.
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
awk '{print "\tdouble " $1 "=" $2 ";"}' Expression.txt
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
[ -f Constant.txt ] && awk '{print "\tdouble " $1 "=" $2 ";"}' Constant.txt
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' Parameters.txt
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' Variables.txt
[ -f Expression.txt ] && awk '{print "\tdouble " $1 "=" $2 ";"}' Expression.txt
for j in `seq 1 $NV`; do
	echo "/* column $j (df/dy_$((j-1))) */"
	awk -v n=$NV -v j=$j '{print "\tjac_[" (NR-1)*n + (j-1) "] = " $0 ";"}' $TMP/Jac_Column_${j}.txt
done
echo "\treturn GSL_SUCCESS;"
echo "}"

cat<<EOF
/* ode parameter Jacobian df(t,y;p)/dp */
int ${MODEL}_jacp(double t, const double y_[], double *jacp_, double *dfdt_, void *par)
{
	double *p_=par;
	if (!y_ || !jacp_) return ${NV}*${NP};
EOF
[ -f Constant.txt ] && awk '{print "\tdouble " $1 "=" $2 ";"}' Constant.txt
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' Parameters.txt
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' Variables.txt
[ -f Expression.txt ] && awk '{print "\tdouble " $1 "=" $2 ";"}' Expression.txt
for j in `seq 1 $NV`; do
	echo "/* column $j (df/dp_$((j-1))) */"
	awk -v n=$NP -v j=$j '{print "\tjac_[" (NR-1)*n + (j-1) "] = " $0 ";"}' $TMP/Jacp_Column_${j}.txt
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

[ -f Constant.txt ] && awk '{print "\tdouble " $1 "=" $2 ";"}' Constant.txt
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' Parameters.txt
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' Variables.txt
[ -f Expression.txt ] && awk '{print "\tdouble " $1 "=" $2 ";"}' Expression.txt
[ -f Function.txt ] && awk '{print "\tfunc_[" (NR-1) "] = " $0 ";"}' Function.txt
echo "\treturn GSL_SUCCESS;"
echo "}"


cat<<EOF
/* ode default parameters */
int ${MODEL}_default(double t, void *par)
{
	double *p_=par;
	if (!p_) return `wc -l < Parameters.txt`;
EOF
[ -f Constant.txt ] && awk '{print "\tdouble " $1 "=" $2 ";"}' Constant.txt
awk '{print "\tp_[" NR-1 "] = " $2 ";"}' Parameters.txt
printf "\treturn GSL_SUCCESS;\n}\n"

cat<<EOF
/* ode initial values */
int ${MODEL}_init(double t, double *y_, void *par)
{
	double *p_=par;
	if (!y_) return ${NV};
EOF
[ -f Constant.txt ] && awk '{print "\tdouble " $1 "=" $2 ";"}' Constant.txt
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' Parameters.txt
printf "\t/* the initial value of y may depend on the parameters. */\n"
awk '{print "\ty_[" NR-1 "] = " $2 ";"}' Variables.txt
printf "\treturn GSL_SUCCESS;\n}\n"

#if [ -d $TMP ]; then
#	rm $TMP/*.rm
#	rm $TMP/d*_d*.txt
#	rm $TMP/Jac*_Column_*.txt
#fi
