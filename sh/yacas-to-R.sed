#!/bin/perl -p
s/(Exp|Sin|Cos|Tan|Abs)/\l\1/g;
s/\bLn\(/log(/g;
s/;$//g;
s/UNDERSCORE/_/g;
