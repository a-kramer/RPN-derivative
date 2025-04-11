# yacas is weird about printing things on screen, but passing lines one by one seems to work.
Derivative () {
	# yacas does not allow _ in symbol names, nor other special characters, like ~
	arg=`echo $1 | sed 's/_/UNDERSCORE/g'`
	while read name f ; do
		echo "Simplify(D($arg) $f)" | perl -p "${dir:-.}/yacas.sed" | yacas -c -f | replace_powers | perl -p "${dir:-.}/yacas-to-${PL:-C}.sed"
	done
}


