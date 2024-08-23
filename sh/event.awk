BEGIN {printf("\tcase %s:\n",e)};
$1 == e && $2 == "var" {print "\t\ty_[var_" $3 "] = " $4 "; /* state variable transformation */"};
$1 == e && $2 == "par" {print "\t\tp_[par_" $3 "] = " $4 "; /* parameter transformation */"};
END {print "\tbreak;"};
