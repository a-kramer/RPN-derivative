#!/bin/perl -p
s/(Exp|Sin|Cos|Tan)/\l\1/g;
s/\bAbs\(/fabs(/g;
s/\bLn\(/log(/g;
s/;$//g;
s/UNDERSCORE/_/g;
