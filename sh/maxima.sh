# this defines the maxima backend
maxima_derivative () {
	if [ $# -gt 0 ]; then
		awk -v X="$1" "BEGIN {print \"display2d:false\$\n linel:1000\$\n\"}; {print \"diff(\" \$0 \",\"X\",1);\n\"};" | sed -E -f "${dir:-.}/maxima.sed" | maxima --very-quiet | sed -E -e '1d' -f ${dir:-.}/maxima-to-${PL:-C}.sed
	else
		echo "«$@» [missing mandatory argument (variable name)]"
	fi
}
