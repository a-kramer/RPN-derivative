#!/bin/sh

## substitute EXPRESSION_FILE MATH_FILE
substitute () {
	NE=$(( `wc -l < "$1"` ))
	if [ -f "$1" -a $NE -gt 0 ]; then
		for j in `seq $NE -1 1`; do
			ExpressionName=`awk -F '\t' -v j=$((j)) 'NR==j {print $1}' "$1"`
			ExpressionFormula=`awk -F '\t' -v j=$((j)) 'NR==j {print $2}' "$1"`
			perl -p -e "s|\b${ExpressionName}\b|(${ExpressionFormula})|g;" "$2"
		done
	else
		cat "$2"
	fi
}

