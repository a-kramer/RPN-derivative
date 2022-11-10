
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
printf "\tf_<-vector(len=%i)\n" $((NV))
awk -F '	' '{print "\tf_[" NR "] <- " $0 }' "$ODE"
echo "\treturn(list(f_));"
echo "}"

cat<<EOF
# ode Jacobian df(t,y;p)/dy
${MODEL}_jac<-function(t, state, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2}' "$CON"
awk '{print "\t" $1 " <- parameters[" NR-1 "]"}' "$PAR"
awk '{print "\t" $1 " <- state[" NR-1 "]"}' "$VAR"
[ -f "$EXP" ] && awk -F '	' '{print "\t" $1 " <- " $2 }' "$EXP"
printf "\tjac_ <- matrix(%i,%i)\n" $((NV)) $((NV))
for j in `seq 1 $NV`; do
	echo "# column $j (df/dy_$((j-1)))"
	awk -v n=$((NV)) -v j=$((j)) '{print "\tjac_[" NR "," j "] <- " $0 }' $TMP/Jac_Column_${j}.txt
done
echo "\treturn(jac_);"
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
printf "\tjacp_<-matrix(%i,%i)\n" $((NV)) $((NP))
for j in `seq 1 $NP`; do
	echo "# column $j (df/dp_$((j)))"
	awk -v n=$((NP)) -v j=$((j)) '{print "\tjacp_[" NR "," j "] <- " $0 }' $TMP/Jacp_Column_${j}.txt
done
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
printf "\tfunc_ <- vector(%i)\n" $((NF))
[ -f "$FUN" ] && awk '{print "\tfunc_[" NR "] <- " $1 "#" $2 }' "$FUN"
echo "\treturn(func_);"
echo "}"


cat<<EOF
# ode default parameters; can depend on constants, and time  of initialization
${MODEL}_default<-function(t)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 " <- " $2 }' "$CON"
printf "\tparameters <- vector(%i)\n" $((NP))
awk '{print "\tparameters[" NR "] <- " $2 }' "$PAR"
printf "\treturn(parameters);\n}\n"

cat<<EOF
# ode initial values
${MODEL}_init<-function(t, parameters)
{
EOF
[ -f "$CON" ] && awk '{print "\t" $1 "<-" $2 }' "$CON"
awk '{print "\t" $1 " <- parameters[" NR "]"}' "$PAR"
printf "\t# the initial value may depend on the parameters. \n"
printf "\tstate<-vector(%i)\n" $((NV))
awk '{print "\tstate[" NR "] <- " $2 }' "$VAR"
printf "\treturn(state)\n}\n"
}
