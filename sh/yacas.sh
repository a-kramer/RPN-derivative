# yacas is weird about printing things on screen, but passing linesone by one seems to work.
Derivative () {
	# yacas does not allow _ in symbol names, nor other special characters, like ~
	arg=`echo $1 | sed 's/_/UNDERSCORE/g'`
	while read f ; do
		echo "Simplify(D($arg) $f)" | sed -E -f "${dir:-.}/yacas.sed" | yacas -c -f | sed -E -f "${dir:-.}/yacas-to-${PL:-C}.sed"
	done
}


