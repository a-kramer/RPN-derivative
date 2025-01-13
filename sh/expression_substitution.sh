#!/bin/sh

## substitute EXPRESSION_FILE MATH_FILE
substitute () {
	NE=$(( `wc -l < "$1"` ))
	if [ $NE -gt 0 ]; then
		tac "$1" | awk -F '\t' '{print "s|\\b" $1 "\\b|(" $2 ")|g;"}' > "${TMP:-}/substitution_table.sed"
		perl -p "${TMP:-.}/substitution_table.sed" "$2"
	else
		cat "$2"
	fi
}

