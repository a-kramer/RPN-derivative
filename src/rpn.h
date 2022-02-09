#ifndef RPN_H
#define RPN_H
#include <stdlib.h>
#include <stdio.h>
#include "symbol.h"
#include "ll.h"

#define NARGS(ll) ((ll)?(((struct symbol *)((ll)->value))->nargs):0)
int depth(struct ll *);
void rpn_print(struct ll *r);
struct ll* rpn_reverse_copy(struct ll *a);
struct ll* rpn_copy(struct ll *a);
int balanced(struct ll *pn);
#endif
