BEGIN {
    print "display2d:false$\n linel:1000$\n"
};
{
    gsub(/[=<>]+/,"*0.0*");
    gsub(/@/,"");
    print "diff(" $2 "," X ",1);\n"
};
