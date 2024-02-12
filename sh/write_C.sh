write_in_C () {
# write a gsl ode model file:
cat<<EOF
#include <stdlib.h>
#include <math.h>
#include <gsl/gsl_errno.h>
#include <gsl/gsl_odeiv2.h>
#include <gsl/gsl_math.h>

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
awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk -F '	' '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
awk -F '	' '{print "\tf_[" NR-1 "] = " $0 ";"}' "$ODE"
echo "\treturn GSL_SUCCESS;"
echo "}"

#
# Jacobian of the ODE
#
cat<<EOF
/* ode Jacobian df(t,y;p)/dy */
int ${MODEL}_jac(double t, const double y_[], double *jac_, double *dfdt_, void *par)
{
	double *p_=par;
	if (!y_ || !jac_) return $((NV))*$((NV));
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk -F '	' '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
for j in `seq 1 $NV`; do
	echo "/* column $j (df/dy_$((j-1))) */"
	awk -v n=$((NV)) -v j=$((j)) '{print "\tjac_[" (NR-1)*n + (j-1) "] = " $0 "; /* [" NR-1 ", " j-1 "] */"}' $TMP/Jac_Column_${j}.txt
done
echo "\treturn GSL_SUCCESS;"
echo "}"

#
# parameter Jacobian of the ODE
#
cat<<EOF
/* ode parameter Jacobian df(t,y;p)/dp */
int ${MODEL}_jacp(double t, const double y_[], double *jacp_, double *dfdt_, void *par)
{
	double *p_=par;
	if (!y_ || !jacp_) return $((NV))*$((NP));
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk -F '	' '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
for j in `seq 1 $NP`; do
	echo "/* column $j (df/dp_$((j-1))) */"
	awk -v n=$((NP)) -v j=$((j)) '{print "\tjacp_[" (NR-1)*n + (j-1) "] = " $0 "; /* [" NR-1 ", " j-1 "] */"}' $TMP/Jacp_Column_${j}.txt
done
echo "\treturn GSL_SUCCESS;"
echo "}"

#
# functions (model output)
#
cat<<EOF
/* ode Functions F(t,y;p) */
int ${MODEL}_func(double t, const double y_[], double *func_, void *par)
{
	double *p_=par;
	if (!y_ || !func_) return $((NF));
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk -F '	' '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
[ -f "$FUN" ] && awk -F '	' '{print "\tfunc_[" (NR-1) "] = " $2 "; /* " $1 " */"}' "$FUN"
echo "\treturn GSL_SUCCESS;"
echo "}"

#
# function Jacobian
#
cat<<EOF
/* Function Jacobian dF(t,y;p)/dy */
int ${MODEL}_funcJac(double t, const double y_[], double *funcJac_, void *par)
{
	double *p_=par;
	if (!y_ || !funcJac_) return $((NF*NV));
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk -F '	' '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
for j in `seq 1 $NV`; do
	echo "/* column $j (dF/dy_$((j-1))) */"
	awk -v n=$((NV)) -v j=$((j)) '{print "\tfuncJac_[" (NR-1)*n + (j-1) "] = " $0 "; /* [" NR-1 ", " j-1 "] */"}' "$TMP/funcJac_Column_${j}.txt"
done
echo "\treturn GSL_SUCCESS;"
echo "}"

#
# function parameter Jacobian
#
cat<<EOF
/* Function parameter Jacobian dF(t,y;p)/dp */
int ${MODEL}_funcJacp(double t, const double y_[], double *funcJacp_, void *par)
{
	double *p_=par;
	if (!y_ || !funcJacp_) return $((NF*NP));
EOF

[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk -F '	' '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
for j in `seq 1 $NV`; do
	echo "/* column $j (dF/dp_$((j-1))) */"
	awk -v n=$((NP)) -v j=$((j)) '{print "\tfuncJacp_[" (NR-1)*n + (j-1) "] = " $0 "; /* [" NR-1 ", " j-1 "] */"}' "$TMP/funcJacp_Column_${j}.txt"
done
echo "\treturn GSL_SUCCESS;"
echo "}"

#
# default parameters
#
cat<<EOF
/* ode default parameters */
int ${MODEL}_default(double t, void *par)
{
	double *p_=par;
	if (!p_) return $((NP));
EOF
[ -f "$CON" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tp_[" NR-1 "] = " $2 ";"}' "$PAR"
printf "\treturn GSL_SUCCESS;\n}\n"


#
# initial values
#
cat<<EOF
/* ode initial values */
int ${MODEL}_init(double t, double *y_, void *par)
{
	double *p_=par;
	if (!y_) return ${NV};
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
printf "\t/* the initial value of y may depend on the parameters. */\n"
awk -F '	' '{print "\ty_[" NR-1 "] = " $2 ";"}' "$VAR"
printf "\treturn GSL_SUCCESS;\n}\n"
}


write_Hessian_in_C () {
#
# parameter Hessian of the output functions
#
cat<<EOF
/* Function parameter Hessian d²F(t,y;p)[k]/dp[i]dp[j] */
int ${MODEL}_funcParHessian(double t, const double y_[], double *funcParHessian_, void *par)
{
	double *p_=par;
	if (!y_ || !funcParHessian_) return $((NP*NP*NF));
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk -F '	' '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
for i in `seq $NP`; do
	for j in `seq $((i)) $NP` ; do
		echo "/* subset d^2 F(t,y;p)/dp[$((i-1))]dp[$((j-1))], F: (R,R^$NV;R^$NP) -> R^$NF */"
		awk -v n=$((NP)) -v j=$((j)) -v i=$((i)) '{print "\tfuncParHessian_[" (NR-1)*n*n + (i-1)*n + (j-1) "] = funcParHessian_[" (NR-1)*n*n + (j-1)*n + (i-1) "] = " $0 "; /* [" i-1 ", " j-1 ", " NR-1 "] and [" j-1 ", " i-1 ", " NR-1 "] */"}' "$TMP/funcParHessian_$((i))_$((j)).txt"
	done
done
echo "\treturn GSL_SUCCESS;"
echo "}"

#
# Hessian of the output functions
#
cat<<EOF
/* Function Hessian d²F(t,y;p)[k]/dy[i]dy[j] */
int ${MODEL}_funcHessian(double t, const double y_[], double *funcHessian_, void *par)
{
	double *p_=par;
	if (!y_ || !funcHessian_) return $((NV*NV*NF));
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk -F '	' '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
for i in `seq $NV`; do
	for j in `seq $((i)) $NV` ; do
		echo "/* subset d^2 F(t,y;p)/dy[$((i-1))]dy[$((j-1))], F: (R,R^$NV;R^$NP) -> R^$NF */"
		awk -v n=$((NV)) -v j=$((j)) -v i=$((i)) '{print "\tfuncHessian_[" (NR-1)*n*n + (i-1)*n + (j-1) "] = funcHessian_[" (NR-1)*n*n + (j-1)*n + (i-1) "] = " $0 "; /* [" i-1 ", " j-1 ", " NR-1 "] and [" j-1 ", " i-1 ", " NR-1 "] */"}' "$TMP/funcHessian_$((i))_$((j)).txt"
	done
done
echo "\treturn GSL_SUCCESS;"
echo "}"

#
# Hessian of the ODE
#
cat<<EOF
/* Hessian d²f(t,y;p)[k]/dy[i]dy[j] */
int ${MODEL}_Hessian(double t, const double y_[], double *Hessian_, void *par)
{
	double *p_=par;
	if (!y_ || !Hessian_) return $((NV*NV*NV));
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk -F '	' '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
for i in `seq $NV`; do
	for j in `seq $((i)) $NV` ; do
		echo "/* subset d^2 f(t,y;p)/dy[$((i-1))]dy[$((j-1))], f: (R,R^$NV;R^$NP) -> R^$NV */"
		awk -v n=$((NV)) -v j=$((j)) -v i=$((i)) '{print "\tHessian_[" (NR-1)*n*n + (i-1)*n + (j-1) "] = Hessian_[" (NR-1)*n*n + (j-1)*n + (i-1) "] = " $0 "; /* [" i-1 ", " j-1 ", " NR-1 "] and [" j-1 ", " i-1 ", " NR-1 "] */"}' "$TMP/Hessian_$((i))_$((j)).txt"
	done
done
echo "\treturn GSL_SUCCESS;"
echo "}"

#
# parameter Hessian of the ODE
#
cat<<EOF
/* Parameter Hessian d²f(t,y;p)[k]/dp[i]dp[j] */
int ${MODEL}_parHessian(double t, const double y_[], double *parHessian_, void *par)
{
	double *p_=par;
	if (!y_ || !parHessian_) return $((NP*NP*NV));
EOF
[ -f "$CON" ] && awk '{print "\tdouble " $1 "=" $2 ";"}' "$CON"
awk -F '	' '{print "\tdouble " $1 "=p_[" NR-1 "];"}' "$PAR"
awk -F '	' '{print "\tdouble " $1 "=y_[" NR-1 "];"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\tdouble " $1 "=" $2 ";"}' "$EXP"
for i in `seq $NP`; do
	for j in `seq $((i)) $NP` ; do
		echo "/* subset d^2 f(t,y;p)/dp[$((i-1))]dp[$((j-1))], f: (R,R^$NV;R^$NP) -> R^$NV */"
		awk -v n=$((NP)) -v j=$((j)) -v i=$((i)) '{print "\tHessian_[" (NR-1)*n*n + (i-1)*n + (j-1) "] = Hessian_[" (NR-1)*n*n + (j-1)*n + (i-1) "] = " $0 "; /* [" i-1 ", " j-1 ", " NR-1 "] and [" j-1 ", " i-1 ", " NR-1 "] */"}' "$TMP/parHessian_$((i))_$((j)).txt"
	done
done
echo "\treturn GSL_SUCCESS;"
echo "}"
}
