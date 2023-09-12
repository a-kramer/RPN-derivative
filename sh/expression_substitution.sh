#!/bin/bash

## substitute EXPRESSION_FILE MATH_FILE OUT_FILE
substitute () {
	NE=$((`wc -l < "$2"`))
	[ "$dir" ] && sed -r -f "${dir}/math.sed" "$2" > "$3"
	if [ -f "$1" ]; then
		for j in `seq $NE -1 1`; do
			ExpressionName=`awk -F '	' -v j=$((j)) 'NR==j {print $1}' "$1"`
			ExpressionFormula=`awk -F '	' -v j=$((j)) 'NR==j {print $2}' "$1"`
			[ "$GNU_WORD_BOUNDARIES" ] && sed -i.rm -e "s|\<${ExpressionName}\>|(${ExpressionFormula})|g" "$3"
			[ "$BSD_WORD_BOUNDARIES" ] && sed -i.rm -e "s|[[:<:]]${ExpressionName}[[:>:]]|(${ExpressionFormula})|g" "$3"
		done
	fi
	[ "$dir" ] && sed -i.rm -r -f "${dir}/math.sed" "$3"
}

