#!/bin/sh

## substitute EXPRESSION_FILE MATH_FILE
substitute () {
    NE=$(( `wc -l < "$1"` ))
    if [ $NE -gt 0 ]; then
	awk -F '\t' '{print "s|\\b" $1 "\\b|(" $2 ")|g;"}' "$1" > "${TMP:-}/substitution_table.sed"
	perl -p "${TMP:-.}/substitution_table.sed" "$2"
    else
	cat "$2"
    fi
}

