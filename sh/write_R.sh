# print row-names as one comma separated string
Names () {
	num=$(( `wc -l < "$1"` ))
	awk -F '	' -v n=$((num)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$1"
}

write_in_R () {
# write a gsl ode model file:
cat<<EOF
require("deSolve")

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
echo -n "\tnames(f_) <- c("
awk -F '	' -v n=$((NV)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$VAR"
echo ")"
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
printf "\tjac_ <- matrix(NA,%i,%i)\n" $((NV)) $((NV))
for j in `seq 1 $NV`; do
	echo "# column $j (df/dy_$((j-1)))"
	awk -F '	' -v n=$((NV)) -v j=$((j)) '{print "\tjac_[" NR "," j "] <- " $0 }' $TMP/Jac_Column_${j}.txt
done
echo -n "\trownames(jac_) <- c("
awk -F '	' -v n=$((NV)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$VAR"
echo ")"
echo -n "\tcolnames(jac_) <- c("
awk -F '	' -v n=$((NV)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$VAR"
echo ")"

echo "\treturn(jac_)"
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
printf "\tjacp_<-matrix(NA,%i,%i)\n" $((NV)) $((NP))
for j in `seq 1 $NP`; do
	echo "# column $j (df/dp_$((j)))"
	awk -F '	' -v n=$((NP)) -v j=$((j)) '{print "\tjacp_[" NR "," j "] <- " $0 }' $TMP/Jacp_Column_${j}.txt
done
echo -n "\trownames(jacp_) <- c("
awk -F '	' -v n=$((NV)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$VAR"
echo ")"
echo -n "\tcolnames(jacp_) <- c("
awk -F '	' -v n=$((NP)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$PAR"
echo ")"

echo "\treturn(jacp_)"
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
echo -n "\tnames(func_) <- c("
awk -F '	' -v n=$((NF)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$FUN"
echo ")"

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
printf "\tjac_<-matrix(NA,%i,%i)\n" $((NF)) $((NV))
for j in `seq 1 $NV`; do
	echo "# column $j (dF/dp_$((j)))"
	awk -F '	' -v j=$((j)) '{print "\tjac_[" NR "," j "] <- " $0 }' $TMP/funcJac_Column_${j}.txt
done
echo -n "\trownames(jac_) <- c("
awk -F '	' -v n=$((NF)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$FUN"
echo ")"
echo -n "\tcolnames(jac_) <- c("
awk -F '	' -v n=$((NP)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$VAR"
echo ")"
echo "\treturn(jac_)"
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
printf "\tjacp_<-matrix(NA,%i,%i)\n" $((NF)) $((NP))
for j in `seq 1 $NP`; do
	echo "# column $j (dF/dp_$((j)))"
	awk -F '	' -v j=$((j)) '{print "\tjacp_[" NR "," j "] <- " $0 }' $TMP/funcJacp_Column_${j}.txt
done
echo -n "\trownames(jacp_) <- c("
awk -F '	' -v n=$((NF)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$FUN"
echo ")"
echo -n "\tcolnames(jacp_) <- c("
awk -F '	' -v n=$((NP)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$PAR"
echo ")"
echo "\treturn(jacp_)"
echo "}"

cat<<EOF
# ode default parameters; can depend on constants, and time  of initialization
${MODEL}_default<-function(t=0.0)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2 }' "$CON"
printf "\tparameters <- vector(mode='numeric',len=%i)\n" $((NP))
awk '{print "\tparameters[" NR "] <- " $2 }' "$PAR"
echo -n "\tnames(parameters) <- c("
awk -F '	' -v n=$((NP)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$PAR"
echo ")"
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
echo -n "\tnames(state) <- c("
awk -F '	' -v n=$((NV)) '{printf("\"%s\"%s",$1,((NR<n)?", ":""))}' "$VAR"
echo ")"
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
printf "\tvarNames <- c("
Names "$VAR"
printf ")\n"
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
printf "\tvarNames <- c("
Names "$VAR"
printf ")\n"
printf "\tparNames <- c("
Names "$PAR"
printf ")\n"
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
printf "\tvarNames <- c("
Names "$VAR"
printf ")\n"
printf "\tfuncNames <- c("
Names "$FUN"
printf ")\n"
printf "\tfuncHessian_<-arrray(NA,dim=c(%i,%i,%i),dimnames=list(varNames,varNames,funcNames))\n" $((NV)) $((NV)) $((NF))
for i in `seq $NV`; do
	for j in `seq $i $NV`; do
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
printf "\tparNames <- c("
Names "$PAR"
printf ")\n"
printf "\tfuncNames <- c("
Names "$FUN"
printf ")\n"
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
