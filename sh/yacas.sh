# yacas is weird about printing things on screen, but passing linesone by one seems to work.
yacas_derivative () {
	while read f ; do
		echo "D($1) $f" | sed -f "${dir:-.}/yacas.sed" | yacas -c -f | sed -f "${dir:-.}/yacas-to-${PL:-C}.sed"
	done
}


