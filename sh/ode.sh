#!/bin/sh

## this script uses perl instead of sed now in a few places where word boundaries are needed.
## But, it's perl in noob mode where we only use the -p option to emulate sed.

echo "$@" 1>&2

MODEL="DemoModel"
N=10
PL="C"
CLEAN="yes"
backend="_rpn" # derivative (this package)"
HESS=""

if [ -f "$0" ]; then               # relative or absolute path
	path="$0"
else                               # ln link
	path="`which \"$0\"`"
fi

src="`readlink -f \"$path\"`"
#echo "full path: $src" 1>&2
[ -f "$src" ] && dir="`dirname \"$src\"`" || exit -1

#printf "Location of all scripts: «$dir»" 1>&2
# find out how the current system's sed matches word boundaries:
#GNU_WORD_BOUNDARIES=`echo 'cat' | sed -E 's/\<cat\>/CAT/' 2>/dev/null`
#BSD_WORD_BOUNDARIES=`echo 'cat' | sed -E 's/[[:<:]]cat[[:>:]]\>/CAT/' 2>/dev/null`
# the above strings will be empty if an error occurred. This is not needed anymore, as we use perl and \b

# check whether /dev/shm exists
[ -d /dev/shm ] && TMP="/dev/shm/ode_gen" || TMP="/tmp/ode_gen"
# make sure the temp folder exists
[ -d "$TMP" ] || mkdir "$TMP"

short_help() {
	echo "$0 [-R|-C] [-N [0-9]+] ModelFile.vf > Model_src.[R|c]"
	printf "\n"
	echo "OPTIONS with default values"
	echo "==========================="
	printf "\n"
	width=35
	printf "%${width}s  " "--help|-h"
	printf "print this help.\n"
	printf "%${width}s  " "--c-source|-C"
	printf "write C source code (default is $PL).\n"
	printf "%${width}s  " "--r-source|-R"
	printf "write R source code (default is $PL).\n"
	printf "%${width}s  " "--simplify|-N $N"
	printf "simplify derivative results $N times\n"
	printf "%${width}s  " "--temp|-t $TMP"
	printf "where to write intermediate files (an empty directory).\n"
	printf "%${width}s  " "--no-clean|--inspect"
	printf "keep intermediate files to check for errors.\n"
	printf "%${width}s  " "--maxima|-M"
	printf "use maxima to calculate derivatives\n\t\t\t\t\t(default is $backend).\n"
	printf "%${width}s  " "--yacas|-Y"
	printf "use yacas to calculate derivatives\n\t\t\t\t\t(default is $backend).\n"

	echo "EXAMPLE"
	echo "======="
	printf "\n"
	echo "	mkdir .tmp"
	echo "	$0 -t ./.tmp --inspect -R myModel.vf > myModel.R"
	echo "	ls .tmp"
	exit
}

# read command line options
while [ $# -gt 0 ]; do
	case $1 in
		--help|-h) short_help;;
		--c-source|-C) PL="C"; shift;;
		--r-source|-R) PL="R"; shift;;
		--hessian|-H) HESS="yes"; shift;;
		[0-9]|[0-9][0-9]) N=$2; shift 2;;
		--simplify|-n|-N) N=$2; shift 2;;
		-t|--temp) TMP="$2"; shift 2;;
		--no-clean|--do-not-clean|--inspect) CLEAN="no"; shift;;
		--maxima|-M) backend="maxima"; shift;;
		--yacas|-Y) backend="yacas"; shift;;
		*) MODEL="$1"; shift;;
	esac
done

BM=`basename "${MODEL}"`

#Default Names
CON="Constants.txt"
PAR="Parameters.txt"
EXP="Expressions.txt"
VAR="StateVariables.txt"
FUN="OutputFunctions.txt"
ODE="ODE.txt"
EVT="Transformations.txt"

# a block that creates some output that is not code
{
if [ -f "$MODEL" -a "${BM#*.}" = "zip"  ]; then
	INFO=`zipinfo -1 "$MODEL"`
	echo "$INFO"
	CON=`echo "$INFO" | egrep -i 'Constants?\.t[xs][tv]$'`
	VAR=`echo "$INFO" | egrep -i '(State)?Variables?\.t[xs][vt]$'`
	PAR=`echo "$INFO" | egrep -i '(Model)?Parameters?\.t[xs][vt]$'`
	FUN=`echo "$INFO" | egrep -i '(Output)?Functions?\.t[xs][vt]$'`
	EXP=`echo "$INFO" | egrep -i 'Expressions?(Formulae?)?\.t[xs][vt]$'`
	ODE=`echo "$INFO" | egrep -i '.*ode\.t[xs][vt]$'`
	EVT=`echo "$INFO" | egrep -i 'Transformations?\.t[xs][vt]$'`
	echo "unzip -u -q -d $TMP $MODEL *.t[xs][tv]"
	[ "$VAR" -a "$PAR" -a "$ODE" ] && unzip -u -q -d "$TMP" "$MODEL" "*.t[xs][tv]"
	MODEL=`basename -s .zip "${MODEL}"`
elif [ -f "$MODEL" -a "${BM#*.}" = "tar.gz" ]; then
	INFO=`tar tf "$MODEL"`
	echo "$INFO"
	CON=`echo "$INFO" | egrep -i 'Constants?\.t[xs][tv]$'`
	VAR=`echo "$INFO" | egrep -i '(State)?Variables?\.t[xs][vt]$'`
	PAR=`echo "$INFO" | egrep -i '(Model)?Parameters?\.t[xs][vt]$'`
	FUN=`echo "$INFO" | egrep -i '(Output)?Functions?\.t[xs][vt]$'`
	EXP=`echo "$INFO" | egrep -i 'Expressions?(Formulae?)?\.t[xs][vt]$'`
	ODE=`echo "$INFO" | egrep -i '.*ode\.t[xs][vt]$'`
	EVT=`echo "$INFO" | egrep -i 'Transformations?\.t[xs][vt]$'`
	echo "tar xzf -C $TMP $MODEL"
	[ "$VAR" -a "$PAR" -a "$ODE" ] && tar xzf "$MODEL" -C "$TMP"
	MODEL=`basename -s .tar.gz "${MODEL}"`
elif [ -f "$MODEL" -a "${BM#*.}" = "vf" ]; then
	echo "Using this vector field file: $MODEL"
	## here sed is ok, as we don't need word boundaries
	sed -r -n -e 's|^[ ]*<Constant.*Name="([^"]+)".*Value="([^"]+)".*$|\1\t\2|p' "$MODEL" > "$TMP/$CON"
	sed -r -n -e 's|^[ ]*<Parameter.*Name="([^"]+)".*Value="([^"]+)".*$|\1\t\2|p' "$MODEL" > "$TMP/$PAR"
	sed -r -n -e 's|^[ ]*<Expression.*Name="([^"]+)".*Formula="([^"]+)".*$|\1\t\2|p' "$MODEL" > "$TMP/$EXP"
	sed -r -n -e 's|^[ ]*<StateVariable.*Name="([^"]+)".*DefaultInitialCondition="([^"]+)".*$|\1\t\2|p' "$MODEL" > "$TMP/$VAR"
	sed -r -n -e 's|^[ ]*<Function.*Name="([^"]+)".*Formula="([^"]+)".*$|\1\t\2|p' "$MODEL" > "$TMP/$FUN"
	sed -r -n -e 's|^[ ]*<StateVariable.*Name="([^"]+)".*Formula="([^"]+)".*$|\1\t\2|p' "$MODEL" > "$TMP/$ODE"
	sed -r -n -e 's|^[ ]*<Function.*Description="Transformation".*Formula="([^"]+)".*$|\1|p' "$MODEL" > "$TMP/$EVT"
	tr '="<>' ' ' < "$MODEL" | perl -p -e 's|/[ ]*$||g' | awk 'BEGIN {OFS="\t"}; $1 ~ /Transformation/ {Name=$3}; $1 ~ /Assign/ {print Name, $5, $3, $7}' > "$TMP/$EVT"
	# we take the model's name from the file's content
	MODEL=`sed -n -r -e 's|^[ ]*<VectorField.*Name="([^"]+)".*$|\1|p' $MODEL`
	echo "Name of the Model according to vfgen file: $MODEL"
elif [ -f "$MODEL" -a "${BM#*.}" = "ode" ]; then
	egrep '^number' "$MODEL" | tr '=' '\t' | sed 's/^number //' > "$TMP/$CON"
	egrep '^par' "$MODEL" | tr '=' '\t' | sed 's/^par //' > "$TMP/$PAR"
	egrep '^init' "$MODEL" | tr '=' '\t' | sed 's/^init //' > "$TMP/$VAR"
	egrep '^!' "$MODEL" | tr '=' '\t' | tr -d '!' > "$TMP/$EXP"
	egrep "'" "$MODEL" | sed "s/'=/\t/" > "$TMP/$ODE"
	egrep '^aux' "$MODEL" | tr '=' '\t' | sed 's/^aux[ ]*//' > "$TMP/$FUN"
	MODEL=`basename -s .ode "${MODEL}"`
else
	OPTTIONS="-type f"
	[ -z "$CON" ] && CON=`find . $OPTIONS -iregex ".*Constants?\.t[xs][tv]$" -print -quit`
	[ -z "$VAR" ] && VAR=`find . $OPTIONS -iregex ".*\(State\)?Variables?\.t[xs][vt]$" -print -quit`
	[ -z "$PAR" ] && PAR=`find . $OPTIONS -iregex ".*\(Model\)?Parameters?\.t[xs][vt]$" -print -quit`
	[ -z "$FUN" ] && FUN=`find . $OPTIONS -iregex ".*\(Output\)?Functions?\.t[xs][vt]$" -print -quit`
	[ -z "$EXP" ] && EXP=`find . $OPTIONS -iregex ".*Expressions?\(Formulae?\)?\.t[xs][vt]$" -print -quit`
	[ -z "$ODE" ] && ODE=`find . $OPTIONS -iregex ".*ode\.t[xs][vt]$" -print -quit`
	[ -z "$EVT" ] && EVT=`find . $OPTIONS -iregex ".*Transformations?\.t[xs][vt]$" -print -quit`
	echo "[$0] Using these files:"
	echo "CON «$CON»"
	echo "PAR «$PAR»"
	echo "VAR «$VAR»"
	echo "EXP «$EXP»"
	echo "FUN «$FUN»"
	echo "ODE «$ODE»"
	echo "EVT «$EVT»"
	echo "copying to $TMP"
	for f in "$CON" "$PAR" "$VAR" "$EXP" "$ODE" "$FUN" "$EVT" ; do
		[ "$f" -a -f "$f" ] && cp "$f" "$TMP"
	done
	CON=`basename "$CON"`
	PAR=`basename "$PAR"`
	VAR=`basename "$VAR"`
	EXP=`basename "$EXP"`
	FUN=`basename "$FUN"`
	ODE=`basename "$ODE"`
	EVT=`basename "$EVT"`
fi
} 1>&2

# now all files should exist in the temp directory, so we set new paths:

[ "$CON" ] && CON="$TMP/$CON"
[ "$PAR" ] && PAR="$TMP/$PAR"
[ "$EXP" ] && EXP="$TMP/$EXP"
[ "$VAR" ] && VAR="$TMP/$VAR"
[ "$FUN" ] && FUN="$TMP/$FUN"
[ "$ODE" ] && ODE="$TMP/$ODE"
[ "$EVT" ] && EVT="$TMP/$EVT"

## We don't need this for R, as R will already understand ascii math
## as it is in most cases.

. $dir/help.sh

NV=$(( `wc -l < "$VAR"` ))
NP=$(( `wc -l < "$PAR"` ))
[ -f "$EXP" ] && NE=$((`wc -l < "$EXP"`)) || NE=0
[ -f "$FUN" ] && NF=$((`wc -l < "$FUN"`)) || NF=0

{
echo "$NV state variables, $NP parameters, $NE expressions, $NF functions"
echo "y-jacobian df[i]/dy[j] has size $((NV*NV)) ($NV×$NV)"
echo "p-jacobian df[i]/dp[j] has size $((NV*NP)) ($NV×$NP)"
} 1>&2

. $dir/expression_substitution.sh

# make a copy of ODE.txt and FUN, but with all expressions substituted
EXODE="${TMP}/explicit_ode.txt"
#substitute EXPRESSION_FILE MATH_FILE OUTPUT_FILE


[ -f "$EXP" ] && substitute "$EXP" "$ODE" > "$EXODE" || cp "$ODE" "$EXODE"
EXFUN="${TMP}/explicit_func.txt"
[ -f "$EXP" ] && substitute "$EXP" "$FUN" > "$EXFUN" || cp "$FUN" "$EXFUN"

# look up name of varianble i
# var i file
var () {
	i="$1"
	file="$2"
	awk -F '[\t=]' -v i=$((i)) 'NR==i {print $1}' "$file"
}

# source the backend specific `Derivative()` function
. "$dir/${backend}.sh"
# Jacobian MATH_FILE INDEP_VARIABLES_FILE OUT_PREFIX
Jacobian () {
	NVAR=$((`wc -l < "$2"`))
	for j in `seq $NVAR`; do
		v=`var $j "$2"`
		Derivative $v < "$1" > "${TMP}/${3}_${j}.txt" 2> "$TMP/error.log"
	done
}

# Hessian MATH_FILE INDEP_VARIABLES_FILE OUT_PREFIX
Hessian () {
	NVAR=$((`wc -l < "$2"`))
	for i in `seq $NVAR` ; do
		vi=`var $i "$2"`
		firstDerivative="$TMP/${3}_$((i))"
		Derivative $vi < "$1" > "${firstDerivative}.txt" 2> "$TMP/error.log"
		for j in `seq $i $NVAR` ; do
			vj=`var $j "$2"`
			Derivative $vj < "$firstDerivative.txt" > "${firstDerivative}_$((j)).txt" 2> "$TMP/error.log"
			[ $((j)) -gt $((i)) ] && ln -s "$TMP/${3}_$((i))_$((j)).txt" "$TMP/${3}_$((j))_$((i)).txt"
		done
	done
}

Jacobian "$EXODE" "$VAR" "Jac_Column"
Jacobian "$EXODE" "$PAR" "Jacp_Column"

# Hessians?
if [ "$HESS" ]; then
	Hessian "$EXODE" "$PAR" "parHessian"
	Hessian "$EXODE" "$VAR" "Hessian"
	Hessian "$EXFUN" "$PAR" "funcParHessian"
	Hessian "$EXFUN" "$VAR" "funcHessian"
fi

# Output Function Jacobians
if [ -f "$EXFUN" ]; then
    Jacobian "$EXFUN" "$VAR" "funcJac_Column"
    Jacobian "$EXFUN" "$PAR" "funcJacp_Column"
fi


# In the next two lines, we source (`.`) the sh-code for writing output
# in the specified programming language, and then run the appropriate
# function
. "$dir/write_${PL}.sh"
write_in_$PL
[ "$HESS" ] && write_Hessian_in_$PL

# (optional) cleaning procedure
{
if [ "$CLEAN" = "yes" -a -d "$TMP" ]; then
	rm $TMP/*
else
	echo "The temporary files are in ${TMP}:"
	ls "$TMP"
fi
} 1>&2
