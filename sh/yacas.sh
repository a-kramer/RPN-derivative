# yacas is weird about printing things on screen, but passing linesone by one seems to work.
yacas_derivative () {
	arg=${1/_/UNDERSCORE}
	while read f ; do
		echo "Simplify(D($arg) $f)" | sed -E -f "${dir:-.}/yacas.sed" | yacas -c -f | sed -E -f "${dir:-.}/yacas-to-${PL:-C}.sed"
	done
}


