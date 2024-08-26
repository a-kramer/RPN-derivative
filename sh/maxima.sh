# this defines the maxima backend
Derivative () {
	if [ $# -gt 0 ]; then
		awk -v X="$1" "BEGIN {print \"display2d:false\$\n linel:1000\$\n\"}; {print \"diff(\" \$0 \",\"X\",1);\n\"};" | perl -p "${dir:-.}/maxima.sed" | maxima --very-quiet | tail -n+2 | perl -p "${dir:-.}/maxima-to-${PL:-C}.sed"
	else
		echo "«$@» [missing mandatory argument (variable name)]"
	fi
}
