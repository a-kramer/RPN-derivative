write_in_C () {
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

/* ode vector field: y'=f(t,y;p) */
int ${MODEL}_vf(double t, const double y_[], double f_[], void *par)
{
	double *p_=par;
	if (!y_ || !f_) return $((NV));
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
	if (!y_ || !jac_) return $((NV))*$((NV));
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
for j in `seq 1 $NV`; do
	echo "/* column $j (df/dy_$((j-1))) */"
	awk -v n=$((NV)) -v j=$((j)) '{print "\tjac_[" (NR-1)*n + (j-1) "] = " $0 "; /* [" NR-1 ", " j-1 "] */"}' $TMP/Jac_Column_${j}.txt
done
echo "\treturn GSL_SUCCESS;"
echo "}"

cat<<EOF
/* ode parameter Jacobian df(t,y;p)/dp */
int ${MODEL}_jacp(double t, const double y_[], double *jacp_, double *dfdt_, void *par)
{
	double *p_=par;
	if (!y_ || !jacp_) return $((NV))*$((NP));
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
for j in `seq 1 $NP`; do
	echo "/* column $j (df/dp_$((j-1))) */"
	awk -v n=$((NP)) -v j=$((j)) '{print "\tjacp_[" (NR-1)*n + (j-1) "] = " $0 "; /* [" NR-1 ", " j-1 "] */"}' $TMP/Jacp_Column_${j}.txt
done
echo "\treturn GSL_SUCCESS;"
echo "}"


cat<<EOF
/* ode Functions F(t,y;p) */
int ${MODEL}_func(double t, const double y_[], double *func_, void *par)
{
	double *p_=par;
	if (!y_ || !func_) return $((NF));
EOF

[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
[ -f "$FUN" ] && awk -F '	' '{print "\tfunc_[" (NR-1) "] = " $2 "; /* " $1 " */"}' "$FUN"
echo "\treturn GSL_SUCCESS;"
echo "}"


cat<<EOF
/* ode default parameters */
int ${MODEL}_default(double t, void *par)
{
	double *p_=par;
	if (!p_) return $((NP));
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
}
