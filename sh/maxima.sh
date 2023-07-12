# this defines the maxima backend
maxima_derivative () {
	if [ $# -gt 0 ]; then
		awk -v X="$1" "BEGIN {print \"display2d:false\$\"}; {print \"diff(\" \$0 \",\"X\",1);\"};" | maxima --very-quiet | sed -E -e '1d' -f ${dir:-.}/maxima-to-${PL:-C}.sed
	else
		echo "«$@» [missing mandatory argument (variable name)]"
	fi
}
