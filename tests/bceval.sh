#!/bin/sh

# this script uses bc to evaluate an infix math expression
#
# the main issues are:
# (1) variables must be replaced by values
# (2) scale needs to be set, as necessary
# (3) convter pow function to ^ operator

while read Math; do
 # address (3)
 Math=`echo "$Math" | sed -E -e 's/@pow/^/g'`
 # address (1)
 [ $# -ge 1 ] && for a in $@ ; do Math=`echo "$Math" | sed -e "s/${a%=*}/${a#*=}/g"` ; done
 echo "$Math" | sed -E \
 -e 's/([a-zA-Z]+)/1/g' \
 -e 's/exp/e/g' \
 -e 's/sin/s/g' \
 -e 's/cos/c/g' \
 -e 's/^/scale=10; /g' | bc -l
done
