#!/bin/sh

MODEL="DemoModel"
N=10
PL="C"
CLEAN="yes"

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
# the above strings will be zero if an error occurred

# check whether /dev/shm exists
[ -d /dev/shm ] && TMP="/dev/shm/ode_gen" || TMP="/tmp/ode_gen"
# make sure the temp folder exists
[ -d "$TMP" ] || mkdir "$TMP"

# read command line options
while [ $# -gt 0 ]; do
 case $1 in
 -C) PL="C"; shift;;
 -R) PL="R"; shift;;
 [0-9]|[0-9][0-9]) N=$2; shift 2;;
 -n) N=$2; shift 2;;
 -t) TMP="$2"; shift 2;;
 --no-clean|--do-not-clean|--inspect) CLEAN="no"; shift;;
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

# make a copy of ODE.txt, but with all expressions substituted
EXODE="${TMP}/explicit_ode.txt"
## step 1, remove unary plusses and minuses, add @ to functions, see math.sed for patterns
sed -r -f "$dir/math.sed" "$ODE" > "$EXODE"
## step 2 substitute expression names for their values (formulae)
if [ -f "$EXP" ]; then
	for j in `seq $NE -1 1`; do
		ExpressionName=`awk -F '	' -v j=$((j)) 'NR==j {print $1}' "$EXP"`
		ExpressionFormula=`awk -F '	' -v j=$((j)) 'NR==j {print $2}' "$EXP"`
		[ "$GNU_WORD_BOUNDARIES" ] && sed -i.rm -e "s|\<${ExpressionName}\>|(${ExpressionFormula})|g" "$EXODE"
		[ "$BSD_WORD_BOUNDARIES" ] && sed -i.rm -e "s|[[:<:]]${ExpressionName}[[:>:]]|(${ExpressionFormula})|g" "$EXODE"
	done
fi

# `derivative` will ignore options beyond the first, so $sv may have more than just a name in it
# just don't quote it like this: "$sv"
for j in `seq 1 $NV`; do
	sv=`awk -v j=$((j)) 'NR==j {print $1}' "$VAR"`
	to_rpn < "$EXODE" | derivative $sv | simplify $N | to_infix > "${TMP}/Jac_Column_${j}.txt" 2> "$TMP/error.log"
done

for j in `seq 1 $NP`; do
	par=`awk -v j=$((j)) 'NR==j {print $1}' "$PAR"`
	to_rpn < "$EXODE" | derivative $par | simplify $N | to_infix > "${TMP}/Jacp_Column_${j}.txt" 2> "$TMP/error.log"
done


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
