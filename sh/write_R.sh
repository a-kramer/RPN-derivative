# print row-names as one comma separated string
Names () {
	num=$(( `wc -l < "$1"` ))
	awk -F '	' -v n=$((num)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$1"
}


# R vector of strings
#
# The values of the strings must be given as lines in a named file:
#
# name <- c(...)
#
# where ... comes from the first column of the file, delimited by tabs.
#
# @param name (string) name of the R-vector
# @param file (file-name) the file with the contents
# Usage: RCharVector name file
RCharVector () {
	name=${1}
	file=${2}
	n=$((`wc -l < "$file"`))
	[ -z "$name" ] && echo "[RCharVector] Error: you must provide a name for the result vector: $name" 1>&2
	[ -e "$file" ] || echo "[RCharVector] Error: file does not exist: '$file'" 1>&2
	[ "$n" -gt 0 ] || echo "[RCharVector] Error: file must contain something: $file has $n lines" 1>&2
	awk -F '	' -v n=$((n)) -v outName="${name}" 'BEGIN {printf("\t%s <- c(",outName)}; {printf("\"%s\"%s",$1,((NR<n)?", ":""))}; END {print ")"}' "$file"
}

# RJacobian writes the jacobian function, generally
#
# The Jacobian values need to have been calculated, and stored
# column-wise in individual files named by a uniform prefix, such that
# ${prefix}${j}.txt exists.
#
# Jacobian = df/dx (both f and x are vectors)
#
# f and x can have element names, these will inform the result-matrix
# names (rownames and colnames).
#
# @param name (string) the functions internal variable to store the result
# @param JAC_COLUMN_ (string) file name prefix, e.g. /dev/shm/Jac_Column_
# @param row_vars (file) this should contain the names of the rows of the
#        jacobian (the function-names of which we take the derivative) (f)
# @param col_vars (file) this contains the names of the independent variables (x)
# @param n number of rows if you want to override the number of lines in the row_vars file
# @param m number of columns if you want to override the number of lines in the col_vars file
# Usage:
#  RJacobian name JAC_COLUMN_ row_vars col_vars n m
# @fn
RJacobian () {
	outName=${1:-"jac_"}
	jac_column_=${2:-"$TMP/Jac_Column_"}
	rows=${3:-"$VAR"}
	cols=${4:-"$PAR"}
	lfun=$((`wc -l < "$rows"`))
	lvar=$((`wc -l < "$cols"`))
	nfiles=$((`ls -1 ${jac_column_}* | wc -l`))
	[ "$lvar" -eq "$nfiles" ] || echo "Warning: There are $lvar independent variables but $nfiles prefixed-files when printing the jacobian '$outName' using the prefix '${jac_column_}'." 1>&2
	n=${5:-$lfun}
	m=${6:-$lvar}
	printf "\t%s <- matrix(NA,%i,%i)\n" "${outName}" $((n)) $((m))
	for j in `seq 1 $((m))`; do
		echo "# column $j"
		awk -F '	' -v name="$outName" -v j=$((j)) '{print "\t" name "[" NR "," j "] <- " $0 }' "${jac_column_}${j}.txt"
	done
	RCharVector "rownames($outName)" "$rows"
	RCharVector "colnames($outName)" "$cols"
	echo "\treturn(${outName})"
}

write_in_R () {
# write a gsl ode model file:
cat<<EOF
# require("deSolve")

# ode vector field: y'=f(t,y;p)
${MODEL}_vf <- function(t, state, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2 }' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
awk '{print "\t" $1 " <- state[" NR "]"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\t" $1 " <- " $2}' "$EXP"
printf "\tf_<-vector(mode='numeric',len=%i)\n" $((NV))
awk -F '	' '{print "\tf_[" NR "] <- " $0 }' "$ODE"
RCharVector "names(f_)" "$VAR"
echo "## for some weird reason deSolve wants this to be a list:"
echo "\treturn(list(f_))"
echo "}"

cat<<EOF
# ode Jacobian df(t,y;p)/dy
${MODEL}_jac<-function(t, state, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2}' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
awk '{print "\t" $1 " <- state[" NR "]"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\t" $1 " <- " $2 }' "$EXP"
RJacobian "jac_"  "$TMP/Jac_Column_" "$VAR" "$VAR"
echo "}"

cat<<EOF
# ode parameter Jacobian df(t,y;p)/dp
${MODEL}_jacp<-function(t, state, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2}' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
awk '{print "\t" $1 " <- state[" NR "]"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\t" $1 "<-" $2 }' "$EXP"
RJacobian "jacp_"  "$TMP/Jacp_Column_" "$VAR" "$PAR"
echo "}"


cat<<EOF
# ode Functions F(t,y;p)
${MODEL}_func<-function(t, state, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2 }' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
awk '{print "\t" $1 " <- state[" NR "]"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\t" $1 " <- " $2 }' "$EXP"
printf "\tfunc_ <- vector(mode='numeric',len=%i)\n" $((NF))
[ -f "$FUN" ] && awk -F '	' '{print "\tfunc_[" NR "] <- " $2 " # " $1 }' "$FUN"
RCharVector "names(func_)" "$FUN"
echo "\treturn(func_)"
echo "}"


cat<<EOF
# output function Jacobian dF(t,y;p)/dp
${MODEL}_funcJac<-function(t, state, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2}' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
awk '{print "\t" $1 " <- state[" NR "]"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\t" $1 "<-" $2 }' "$EXP"
RJacobian "fjac_" "$TMP/funcJac_Column_" "$FUN" "$VAR"
echo "}"

cat<<EOF
# output function parameter Jacobian dF(t,y;p)/dp
${MODEL}_funcJacp<-function(t, state, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2}' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
awk '{print "\t" $1 " <- state[" NR "]"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\t" $1 "<-" $2 }' "$EXP"
RJacobian "fjacp_" "$TMP/funcJacp_Column_" "$FUN" "$PAR"
echo "}"

cat<<EOF
# ode default parameters; can depend on constants, and time  of initialization
${MODEL}_default<-function(t=0.0)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2 }' "$CON"
printf "\tparameters <- vector(mode='numeric',len=%i)\n" $((NP))
awk '{print "\tparameters[" NR "] <- " $2 }' "$PAR"
RCharVector "names(parameters)" "$PAR"
printf "\treturn(parameters);\n}\n"

cat<<EOF
# ode initial values
${MODEL}_init<-function(t=0.0, parameters=NA)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 "<-" $2 }' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
printf "\t# the initial value may depend on the parameters. \n"
printf "\tstate<-vector(mode='numeric',len=%i)\n" $((NV))
awk '{print "\tstate[" NR "] <- " $2 }' "$VAR"
RCharVector "names(state)" "$VAR"
printf "\treturn(state)\n}\n"

## finally, we collect all functions into one generic name,
## in case the model is processed by a script, to avoid "eval(as.name(...))"
cat<<EOF
model<-list(vf=${MODEL}_vf, jac=${MODEL}_jac, jacp=${MODEL}_jacp, func=${MODEL}_func, funcJac=${MODEL}_funcJac, funcJacp=${MODEL}_funcJacp, init=${MODEL}_init, par=${MODEL}_default, name="${MODEL}")
EOF
}


write_Hessian_in_R () {

# Hessian
cat<<EOF
# ODE Hessian d^2 f(t,y;p)[k]/dy[i]dy[j]
${MODEL}_Hessian<-function(t, state, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2}' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
awk '{print "\t" $1 " <- state[" NR "]"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\t" $1 "<-" $2 }' "$EXP"
RCharNames "varNames" "$VAR"
printf "\thessian_<-arrray(NA,dim=c(%i,%i,%i),dimnames=list(varNames,varNames,varNames))\n" $((NV)) $((NV)) $((NV))
for i in `seq $NV`; do
	for j in `seq $i $NV`; do
		echo "# hessian (df/dp_$((i))dp_$((j)))"
		awk -F '	' -v i=$((i)) -v j=$((j)) '{print "\thessian_[" i "," j "," NR "] <- hessian_[" j "," i "," NR "] <- " $0 }' "$TMP/Hessian_$((i))_$((j)).txt"
	done
done
echo "\treturn(hessian_)"
echo "}"

# Parameter Hessian
cat<<EOF
# ODE parameter Hessian d^2 f(t,y;p)[k]/dp[i]dp[j]
${MODEL}_parHessian<-function(t, state, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2}' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
awk '{print "\t" $1 " <- state[" NR "]"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\t" $1 "<-" $2 }' "$EXP"
RCharNames "varNames" "$VAR"
RCharNames "parNames" "$PAR"
printf "\tparHessian_<-arrray(NA,dim=c(%i,%i,%i),dimnames=list(parNames,parNames,varNames))\n" $((NP)) $((NP)) $((NV))
for i in `seq $NP`; do
	for j in `seq $i $NP`; do
		echo "# parameter hessian (df/dp_$((i))dp_$((j)))"
		awk -F '	' -v i=$((i)) -v j=$((j)) '{print "\tparHessian_[" i "," j "," NR "] <- parHessian_[" j "," i "," NR "] <- " $0 }' "$TMP/parHessian_$((i))_$((j)).txt"
	done
done
echo "\treturn(parHessian_)"
echo "}"

# Function Hessian
cat<<EOF
# (output) Function Hessian d^2 F(t,y;p)[k]/dy[i]dy[j]
${MODEL}_funcHessian<-function(t, state, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2}' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
awk '{print "\t" $1 " <- state[" NR "]"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\t" $1 "<-" $2 }' "$EXP"
RCharNames "varNames" "$VAR"
RCharNames "funcNames" "$FUN"
printf "\tfuncHessian_<-arrray(NA,dim=c(%i,%i,%i),dimnames=list(varNames,varNames,funcNames))\n" $((NV)) $((NV)) $((NF))
for i in `seq $NV`; do
	for j in `seq $((i)) $NV`; do
		echo "# func hessian (dF/dp_$((i))dp_$((j)))"
		awk -F '	' -v i=$((i)) -v j=$((j)) '{print "\tfuncHessian_[" i "," j "," NR "] <- funcHessian_[" j "," i "," NR "] <- " $0 }' "$TMP/funcHessian_$((i))_$((j)).txt"
	done
done
echo "\treturn(funcHessian_)"
echo "}"

# Function Parameter Hessian
cat<<EOF
# (output) Function Parameter Hessian d^2 F(t,y;p)[k]/dp[i]dp[j]
${MODEL}_funcParHessian<-function(t, state, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2}' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
awk '{print "\t" $1 " <- state[" NR "]"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\t" $1 "<-" $2 }' "$EXP"
RCharNames "parNames" "$PAR"
RCharNames "funcNames" "$FUN"
printf "\tfuncParHessian_<-arrray(NA,dim=c(%i,%i,%i),dimnames=list(parNames,parNames,funcNames))\n" $((NP)) $((NP)) $((NF))
for i in `seq $NP`; do
	for j in `seq $((i)) $NP`; do
		echo "# func hessian (dF/dp_$((i))dp_$((j)))"
		awk -F '	' -v i=$((i)) -v j=$((j)) '{print "\tfuncParHessian_[" i "," j "," NR "] <- funcParHessian_[" j "," i "," NR "] <- " $0 }' "$TMP/funcParHessian_$((i))_$((j)).txt"
	done
done
echo "\treturn(funcParHessian_)"
echo "}"

echo

cat<<EOF
model<-c(model,hessian=${MODEL}_Hessian,funcHessian=${MODEL}_funcHessian, parHessian=${MODEL}_parHessian, funcParHessian=${MODEL}_funcParHessian)
EOF

}
