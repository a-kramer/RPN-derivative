# this defines the maxima backend

# does the derivative of the first argument
# with respect to the second argument
# derivative "x*y" "x" -> "y"
maxima_derivative () {
	while read f ; do
		echo "display2d:false\$ diff($f,$1,1);" | maxima --very-quiet | sed -E -e '1d' -f $dir/maxima-to-$PL.sed
	done
}
