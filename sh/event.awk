BEGIN {printf("\tcase %s:\n",e)};
$1 == e && $2 == "var" {print "\t\ty_[_" $3 "] = " $4 "; /* state variable transformation */"};
$1 == e && $2 == "par" {print "\t\tp_[_" $3 "] = " $4 "; /* parameter transformation */"};
END {print "\tbreak;"};
