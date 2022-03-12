#!/bin/sh
D=../bin/derivative
S=../bin/simplify
RPN=../bin/to_rpn
IFX=../bin/to_infix

while read sv; do
	echo "sv: $sv"
	$RPN < ReactionFlux.txt | $D "$sv" | $S 5 | $IFX > Flux_${sv}.txt
done < Variables.txt

NF=`wc -l < ReactionFlux.txt` 
NV=`wc -l < Variables.txt`


for j in `seq 1 $NV`; do
	cp ODE.txt Jac_${j}.txt			
	sv=`sed -n "${j}p" Variables.txt`
	for i in `seq 1 $NF`; do
		flux_sv=`sed -n -e "${i}p" Flux_${sv}.txt`
		echo "d(flux)/d($sv) = $flux_sv"
		sed -i -e "s/ReactionFlux$((i-1))/${flux_sv}/g" Jac_${j}.txt
	done
done	
