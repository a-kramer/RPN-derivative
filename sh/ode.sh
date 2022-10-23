#!/bin/sh

MODEL=${1:-"DemoModel"}
N=${2:-6}
TMP=${3:-/dev/shm/ode_gen}

# make sure the temp folder exists
[ -d "${TMP}" ] || (mkdir "${TMP}" || TMP='.')

OPTTIONS="-type f"

CON=`find . $OPTIONS -regex ".*[Cc]onstants?\.t[xs][tv]$" -print -quit`
VAR=`find . $OPTIONS -regex ".*\([Ss]tate\)?[Vv]ariables?\.t[xs][vt]$" -print -quit`
PAR=`find . $OPTIONS -regex ".*\([Mm]odel\)?[Pp]arameters?\.t[xs][vt]$" -print -quit`
FUN=`find . $OPTIONS -regex ".*\([Oo]utput\)?[Ff]unctions?\.t[xs][vt]$" -print -quit`
EXP=`find . $OPTIONS -regex ".*[Ee]xpressions?\([Ff]ormulae?\)?\.t[xs][vt]$" -print -quit`
ODE=`find . $OPTIONS -iregex ".*ode\.t[xs][vt]$" -print -quit`

# print some help if something is not right
(
if [ -f "$VAR" -a -f "$PAR" -a -f "$ODE" ]; then
	echo "[$0] Using these files:"
	echo "CON «$CON»"
	echo "PAR «$PAR»"
	echo "VAR «$VAR»"
	echo "EXP «$EXP»"
	echo "FUN «$FUN»"
	echo "ODE «$ODE»"
else
	echo "Usage: $0 [ModelName] [N] [TMP]"
	echo;
	echo "This assumes that `pwd` contains the four mandatory files:"
	echo "     Variables.txt   the names of all state variables, one per line, "
	echo "                     with initial value, and a unit of measurement, separated by a tab"
	echo "    Parameters.txt   parameter names, one per line"

	echo "                     expressions, state variables, parameters, and constants"
	echo "           ODE.txt   mathematical formulae of how the ODE's right hand side is calculated using "
	echo "                     fluxes, expressions, state variables, parameters, and constants"
	echo;
	echo "Some files are optional:"
	echo "     Constants.txt   names and values of constants, one name value pair per line, "
	echo "                     separated by a tab"
	echo "   Expressions.txt   a file with expression names and formulae (right hand side) comprising "
	echo "                     constants, parameters, and state variables, separated by either '=' or tab"
	echo "     Functions.txt   a file with named expressions (one per line) that define (observable) model outputs, "
	echo "                     name and value sepearated by a tab."
	echo;
	echo "Some temporary files will be created in ${TMP}, this location can be changed by setting the third command line argument."
	echo "All derivatives will be simplified N times. (simplication means: «x+0=x» or «x*1=x», and similar things)"
	echo "The default model name is 'DemoModel'."
	exit 1	
fi

if [ -z `which derivative` ]; then
	echo "[warning] the 'derivative' program is not installed."
	echo "	if you prefer to use a compiled but not installed copy,"
	echo "	then you can use an alias (named 'derivative'):"
	echo "		alias derivative='./bin/derivative'"
fi
) 1>&2

NV=`wc -l < "$VAR"`
NP=`wc -l < "$PAR"`
[ -f "$EXP" ] && NE=`wc -l < "$EXP"` || NE=0
[ -f "$FUN" ] && NF=`wc -l < "$FUN"` || NF=0

(
echo "$NV state variables, $NP parameters, $NE expressions, $NF functions"
echo "y-jacobian df[i]/dy[j] has size $((NV*NV)) ($NV×$NV)"
echo "p-jacobian df[i]/dp[j] has size $((NV*NP)) ($NV×$NP)"
) 1>&2

# make a copy of ODE.txt, but with all expressions substituted
EXODE="${TMP}/explicit_ode.txt"
## step 1, remove unary plusses and minuses
sed -r -e 's/(exp|sin|cos|tan)/@\1/g' \
       -e 's/^([ ]*[-][ ]*([a-zA-Z_(]))/-1*\2/g' \
       -e 's/^([ ]*[+][ ]*([a-zA-Z_(]))/\2/g' \
       -e 's|\([ ]*([-][ ]*([a-zA-Z_(]))|(-1*\2|g' \
       -e 's|\([ ]*([+][ ]*([a-zA-Z_(]))|(\2|g' "$ODE" > "$EXODE"
## step 2 substitute expression names for their values (formulae)
if [ -f "$EXP" ]; then
	for j in `seq $NE -1 1`; do
		ExpressionName=`awk -F '	' -v j=$j 'NR==j {print $1}' "$EXP"`
		ExpressionFormula=`awk -F '	' -v j=$j 'NR==j {print $2}' "$EXP"`
		sed -i.rm -e "s|${ExpressionName}|(${ExpressionFormula})|g" "$EXODE"
	done
fi

for j in `seq 1 $NV`; do
	sv=`sed -n -e "${j}p" "$VAR"`
	to_rpn < "$EXODE" | derivative $sv | simplify $N | to_infix > "${TMP}/Jac_Column_${j}.txt"
done

for j in `seq 1 $NP`; do
	par=`sed -n -e "${j}p" "$PAR"`
	to_rpn < "$EXODE" | derivative $par | simplify $N | to_infix > "${TMP}/Jacp_Column_${j}.txt"
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
awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
awk -F '	' '{print "\tf_[" NR-1 "] = " $0 ";"}' "$ODE"
echo "\treturn GSL_SUCCESS;"
echo "}"

cat<<EOF
/* ode Jacobian df(t,y;p)/dy */
int ${MODEL}_jac(double t, const double y_[], double *jac_, double *dfdt_, void *par)
{
	double *p_=par;
	if (!y_ || !jac_) return ${NV}*${NV};
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
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
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
for j in `seq 1 $NP`; do
	echo "/* column $j (df/dp_$((j-1))) */"
	awk -v n=$NP -v j=$j '{print "\tjacp_[" (NR-1)*n + (j-1) "] = " $0 ";"}' $TMP/Jacp_Column_${j}.txt
done
echo "\treturn GSL_SUCCESS;"
echo "}"


cat<<EOF
/* ode Functions F(t,y;p) */
int ${MODEL}_func(double t, const double y_[], double *func_, void *par)
{
	double *p_=par;
	if (!y_ || !func_) return `wc -l < "$FUN"`;
EOF

[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
[ -f "$FUN" ] && awk '{print "\tfunc_[" (NR-1) "] = " $0 ";"}' "$FUN"
echo "\treturn GSL_SUCCESS;"
echo "}"


cat<<EOF
/* ode default parameters */
int ${MODEL}_default(double t, void *par)
{
	double *p_=par;
	if (!p_) return `wc -l < "$PAR"`;
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk '{print "\tp_[" NR-1 "] = " $2 ";"}' "$PAR"
printf "\treturn GSL_SUCCESS;\n}\n"

cat<<EOF
/* ode initial values */
int ${MODEL}_init(double t, double *y_, void *par)
{
	double *p_=par;
	if (!y_) return ${NV};
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
printf "\t/* the initial value of y may depend on the parameters. */\n"
awk '{print "\ty_[" NR-1 "] = " $2 ";"}' "$VAR"
printf "\treturn GSL_SUCCESS;\n}\n"

## cleaning procedure
#if [ -d $TMP ]; then
#	rm $TMP/*.rm
#	rm $TMP/d*_d*.txt
#	rm $TMP/Jac*_Column_*.txt
#fi
