# print some help if something is not right
{
if [ -f "$VAR" -a -f "$PAR" -a -f "$ODE" ]; then
	echo "Operating on these files:"
	echo "CON «$CON»"
	echo "PAR «$PAR»"
	echo "VAR «$VAR»"
	echo "EXP «$EXP»"
	echo "FUN «$FUN»"
	echo "ODE «$ODE»"
else
	echo "Usage: $0 [ModelName|ModelName.zip|ModelName.tar.gz] [N] [TMP]"
	echo "      or"
	echo "       $0 [-C|-R] [-n N] [-t TMP] [--do-not-clean] MODEL.{zip,tar.gz,vf}"
	echo "OPTIONS"
	echo "======="
	echo " -C    writes C output, for GSL solvers"
	echo " -R    writes R output for deSolve solvers"
	echo " -n N  performs math simplification N times"
	echo "       (very simple math simplification)"
	echo " -t T  sets the location of the temporary directory,"
	echo "       default is either '/dev/shm/ode_gen' "
	echo "       or '/tmp/ode_gen', if shm does not exist (e.g. BSD) "
	echo " --do-not-clean|--no-clean|--inspect"
	echo "       leaves all temporary files in the temporary directory"
	echo "       for debugging/inspection"
	echo;
	echo "The MODEL argument can either be the Model's name, "
	echo "a VFGEN file, or a model archive;"
	echo "see the INPUT FILES section."
	echo "Archives can be a zip file (with those text files)"
	echo "or a tar.gz archive."
	echo;
	echo "INPUT FILES"
	echo "==========="
	echo "Providing a plain MODEL name, rather than an archive file,"
	echo "assumes that the text files listed below can be"
	echo "found by the find utility in"
	echo "`pwd` (current dir)."
	echo "An archive (zip|tar.gz) must contain at leat these files:"
	echo "[State]Variables.txt   the names of all state variables, one per line, "
	echo "                       with initial value, and a unit of measurement, separated by a tab"
	echo "      Parameters.txt   parameter names, one per line"

	echo "                       expressions, state variables, parameters, and constants"
	echo "             ODE.txt   mathematical formulae of how the ODE's"
	echo "                       right hand side is calculated using "
	echo "                       expressions, state variables,"
	echo "                       parameters, and constants"
	echo;
	echo " ======= mandatory ========="
	echo "  Parameters «$PAR»"
	echo "  State Variables «$VAR»"
	echo "  ODE «$ODE»"
	echo " ==========================="
	echo;
	echo "Some files are optional:"
	echo "       Constants.txt   names and values of constants,"
	echo "                       one name value pair per line, "
	echo "                       separated by a tab"
	echo "     Expressions.txt   a file with expression names and formulae"
	echo "                       (right hand side) comprising "
	echo "                       constants, parameters, and state variables,"
	echo "                       separated by tabs (\t)"
	echo "       Functions.txt   a file with named expressions (one per line)"
	echo "                       that define (observable) model outputs, "
	echo "                       name and value sepearated by a tab."
	echo;
	echo "Some temporary files will be created in TMP (as specified)."
	echo "All derivatives will be simplified N times. "
	echo "Simplication means: «x+0=x» or «x*1=x» (and similar)."
	echo "The code struggles a bit with unary minuses"
	echo "(0-x will not become -x)."
	echo "The default model name is 'DemoModel'."
	exit 1
fi
} 1>&2