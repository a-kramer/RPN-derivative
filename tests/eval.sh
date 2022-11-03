#!/bin/sh

# this script uses dc to evaluate an rpn but first we translate the
# math expression into something that dc will understand.
#
# the main issues are:
# (1) dc wants negative numbers like this: _1 rather
#     than this -1
# (2) dc needs a print instruction (p) to display
#     the result
# (3) dc wants only numbers in the expression, obviously

while read rpn; do
 # address (1)
 rpn=`echo "$rpn" | sed -E -e 's/@pow/^/g' -e 's/-([.0-9])/_\1/g' `
 # address (3)
 [ $# -ge 1 ] && for a in $@ ; do rpn=`echo "$rpn" | sed -e "s/${a%=*}/${a#*=}/g"` ; done
 #echo "$rpn" | sed -E -e 's/([a-zA-Z]+)/1/g' -e 's/^/12 k /g' -e 's/$/ p/'
 echo "$rpn" | sed -E -e 's/([a-zA-Z]+)/1/g' -e 's/^/10 k /g' -e 's/$/ p/' | dc
done
