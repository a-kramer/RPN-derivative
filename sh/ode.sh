#!/bin/sh

MODEL="DemoModel"
N=10
PL="C"
CLEAN="yes"
backend="_rpn" # derivative (this package)"

# find the location of this file, so that we can source neighboring files
{
if [ -f "$0" ]; then
	src="$0"
elif [ "`alias $0`" ]; then
	src=`alias "$0" | awk -F= '{print $2}' | tr -d "'"`
else
	src=`readlink -f "$0"`
fi
[ "$src" ] && dir=`dirname $src` || dir="."
} 2>/dev/null
# ^^^^^^^^^^^ means redirect stderr to null, because alias prints an error message on failure

# find out how the current system's sed matches word boundaries:
GNU_WORD_BOUNDARIES=`echo 'cat' | sed -E 's/\<cat\>/CAT/' 2>/dev/null`
BSD_WORD_BOUNDARIES=`echo 'cat' | sed -E 's/[[:<:]]cat[[:>:]]\>/CAT/' 2>/dev/null`
# the above strings will be empty if an error occurred

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


# a block that creates some output that is not code
{
if [ -f "$MODEL" -a "${BM#*.}" = "zip"  ]; then
	INFO=`zipinfo -1 "$MODEL"`
	echo "$INFO"
	CON=`echo "$INFO" | egrep -i 'Constants?\.t[xs][tv]$'`
	VAR=`echo "$INFO"  | egrep -i '(State)?Variables?\.t[xs][vt]$'`
	PAR=`echo "$INFO"  | egrep -i '(Model)?Parameters?\.t[xs][vt]$'`
	FUN=`echo "$INFO"  | egrep -i '(Output)?Functions?\.t[xs][vt]$'`
	EXP=`echo "$INFO"  | egrep -i 'Expressions?(Formulae?)?\.t[xs][vt]$'`
	ODE=`echo "$INFO"  | egrep -i '.*ode\.t[xs][vt]$'`
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
	echo "tar xzf -C $TMP $MODEL"
	[ "$VAR" -a "$PAR" -a "$ODE" ] && tar xzf "$MODEL" -C "$TMP"
	MODEL=`basename -s .tar.gz "${MODEL}"`
elif [ -f "$MODEL" -a "${BM#*.}" = "vf" ]; then
	echo "Using this vector field file: $MODEL"
	sed -r -n -e 's|^[ ]*<Constant.*Name="([^"]+)".*Value="([^"]+)".*$|\1\t\2|p' "$MODEL" > "$TMP/$CON"
	sed -r -n -e 's|^[ ]*<Parameter.*Name="([^"]+)".*Value="([^"]+)".*$|\1\t\2|p' "$MODEL" > "$TMP/$PAR"
	sed -r -n -e 's|^[ ]*<Expression.*Name="([^"]+)".*Formula="([^"]+)".*$|\1\t\2|p' "$MODEL" > "$TMP/$EXP"
	sed -r -n -e 's|^[ ]*<StateVariable.*Name="([^"]+)".*DefaultInitialCondition="([^"]+)".*$|\1\t\2|p' "$MODEL" > "$TMP/$VAR"
	sed -r -n -e 's|^[ ]*<Function.*Name="([^"]+)".*Formula="([^"]+)".*$|\1\t\2|p' "$MODEL" > "$TMP/$FUN"
	sed -r -n -e 's|^[ ]*<StateVariable.*Formula="([^"]+)".*$|\1|p' "$MODEL" > "$TMP/$ODE"
	# we take the model's name from the file's content
	MODEL=`sed -n -r -e 's|^[ ]*<VectorField.*Name="([^"]+)".*$|\1|p' $MODEL`
	echo "Name of the Model according to vfgen file: $MODEL"
else
	OPTTIONS="-type f"
	[ -z "$CON" ] && CON=`find . $OPTIONS -iregex ".*Constants?\.t[xs][tv]$" -print -quit`
	[ -z "$VAR" ] && VAR=`find . $OPTIONS -iregex ".*\(State\)?Variables?\.t[xs][vt]$" -print -quit`
	[ -z "$PAR" ] && PAR=`find . $OPTIONS -iregex ".*\(Model\)?Parameters?\.t[xs][vt]$" -print -quit`
	[ -z "$FUN" ] && FUN=`find . $OPTIONS -iregex ".*\(Output\)?Functions?\.t[xs][vt]$" -print -quit`
	[ -z "$EXP" ] && EXP=`find . $OPTIONS -iregex ".*Expressions?\(Formulae?\)?\.t[xs][vt]$" -print -quit`
	[ -z "$ODE" ] && ODE=`find . $OPTIONS -iregex ".*ode\.t[xs][vt]$" -print -quit`
	echo "[$0] Using these files:"
	echo "CON «$CON»"
	echo "PAR «$PAR»"
	echo "VAR «$VAR»"
	echo "EXP «$EXP»"
	echo "FUN «$FUN»"
	echo "ODE «$ODE»"
	echo "copying to $TMP"
	for f in "$CON" "$PAR" "$VAR" "$EXP" "$ODE" "$FUN" ; do
		[ "$f" -a -f "$f" ] && cp "$f" "$TMP"
	done
	CON=`basename "$CON"`
	PAR=`basename "$PAR"`
	VAR=`basename "$VAR"`
	EXP=`basename "$EXP"`
	FUN=`basename "$FUN"`
	ODE=`basename "$ODE"`
fi
} 1>&2

# now all files should exist in the temp directory, so we set new paths:
[ "$CON" ] && CON="$TMP/$CON"
[ "$PAR" ] && PAR="$TMP/$PAR"
[ "$EXP" ] && EXP="$TMP/$EXP"
[ "$VAR" ] && VAR="$TMP/$VAR"
[ "$FUN" ] && FUN="$TMP/$FUN"
[ "$ODE" ] && ODE="$TMP/$ODE"

. $dir/help.sh

NV=`wc -l < "$VAR"`
NP=`wc -l < "$PAR"`
[ -f "$EXP" ] && NE=`wc -l < "$EXP"` || NE=0
[ -f "$FUN" ] && NF=`wc -l < "$FUN"` || NF=0

{
echo "$NV state variables, $NP parameters, $NE expressions, $NF functions"
echo "y-jacobian df[i]/dy[j] has size $((NV*NV)) ($NV×$NV)"
echo "p-jacobian df[i]/dp[j] has size $((NV*NP)) ($NV×$NP)"
} 1>&2

. $dir/expression_substitution.sh

# make a copy of ODE.txt and FUN, but with all expressions substituted
EXODE="${TMP}/explicit_ode.txt"
substitute "$EXP" "$ODE" "$EXODE"
EXFUN="${TMP}/explicit_func.txt"
substitute "$EXP" "$FUN" "$EXFUN"

## Jacobian MATH_FILE INDEP_VARIABLES_FILE OUT_PREFIX
Jacobian () {
	NVAR=$((`wc -l < "$2"`))
	for j in `seq 1 $NVAR`; do
		v=`awk -F '	' -v j=$((j)) 'NR==j {print $1}' "$2"`
		Derivative $v < "$1" > "${TMP}/${3}${j}.txt"
	done
}

> "${TMP}/Jac_Column_${j}.txt" 2> "$TMP/error.log"
## do the derivatives
. "$dir/${backend}.sh"
Jacobian "$EXODE" "$VAR" "Jac_Column_"
Jacobian "$EXODE" "$PAR" "Jacp_Column_"
Jacobian "$EXFUN" "$VAR" "funcJac_Column_"
Jacobian "$EXFUN" "$PAR" "funcJacp_Column_"


## In the next two lines, we read the code for writing output in the specified programming language, and then run the appropriate function
. "$dir/write_${PL}.sh"
write_in_$PL

## (optional) cleaning procedure
{
if [ "$CLEAN" = "yes" -a -d "$TMP" ]; then
	rm $TMP/*
else
	echo "The temporary files are in ${TMP}:"
	ls "$TMP"
fi
} 1>&2
