s/([a-zA-Z0-9_])([-+])([0-9])/\1 \2 \3/g
s/(exp|log|sin|cos|tan|pow)/@\1/g
s/^([ ]*[-][ ]*([a-zA-Z_(]))/-1*\2/g
s/^([ ]*[+][ ]*([a-zA-Z_(]))/\2/g
s/\([ ]*([-][ ]*([a-zA-Z_(]))/(-1*\2/g
s/\([ ]*([+][ ]*([a-zA-Z_(]))/(\2/g
s/\<([0-9]*[.][0-9]+[eE]?[+-]?[0-9]*)\>\^([0-9]*[.][0-9]+[eE]?[+-]?[0-9]*)/@pow(\1,\2)/g
s/\<([a-zA-Z0-9_]+)\^\(([^()]+)\)/@pow(\1,\2)/g
s/([0-9]*[.][0-9]+[eE]?[+-]?[0-9]*)\^(\<[a-zA-Z0-9_]+\>)/@pow(\1,\2)/g
s/(\<[a-zA-Z0-9_]+\>)\^([0-9]*[.][0-9]+[eE]?[+-]?[0-9]*)/@pow(\1,\2)/g
s/(\<[a-zA-Z0-9_]+\>)\^(\<[a-zA-Z0-9_]+\>)/@pow(\1,\2)/g
s/\(([^()]+)\)\^(\<[a-zA-Z0-9_]+\>)/@pow(\1,\2)/g
s/\(([^()]+)\)\^\(([^()]+)\)/@pow(\1,\2)/g
