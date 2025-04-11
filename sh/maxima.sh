# this defines the maxima backend
Derivative () {
	if [ $# -gt 0 ]; then
	    awk -F "[\t]" -v X="$1" -f "${dir:-.}/maxima-derivative.awk" | maxima --very-quiet | tail -n+2 | replace_powers | perl -p "${dir:-.}/maxima-to-${PL:-C}.sed"
	else
		echo "«$@» [missing mandatory argument (variable name)]"
	fi
}
