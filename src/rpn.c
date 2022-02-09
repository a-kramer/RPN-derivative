#include "rpn.h"

/* calculate the number of terms necessary to evaluate the first
 * symbol. if the list ends prematurely (not enough operands), a
 * negative depth is returned.
 */
int depth(struct ll *pn){
	int n=0;
	int d=0;
	if (pn){
		n=NARGS(pn);
		while (n){
			if (pn) pn=pn->next;
			else return -1;
			n--;
			d++;
			n+=NARGS(pn);			
		}		
	}
	return d;
}

/* This function prints the symbol elements in the linked list to stdout */
void rpn_print(struct ll *r) /* pointer to first element */
{
	struct symbol *s;
	while (r){
		s=r->value;
		symbol_print(s);
		r=r->next;
	}
}

/* This creates a copy of the linked list, but in reverse order. The
 * symbol values stored in the linked list are also copied `memcpy()`.
 */
struct ll* /* reversed list */
rpn_reverse_copy(struct ll *a) /* list to copy */
{
	struct ll *b=NULL;
	struct symbol *s;
	struct symbol *r;
	while (a){
		s=a->value;
		r=malloc(sizeof(struct symbol));
		memcpy(r,s,sizeof(struct symbol));
		ll_push(&b,r);
		a=a->next;
	}
	return b;
}

/* This creates a copy of the linked list, also copying the symbol
 * values stored in the linked list.
 */
struct ll* /* duplicate of `a`*/
rpn_copy(struct ll *a) /* list to copy */
{
	struct ll *b=NULL;
	struct symbol *s;
	struct symbol *r;
	while (a){
		s=a->value;
		r=malloc(sizeof(struct symbol));
		memcpy(r,s,sizeof(struct symbol));
		ll_append(&b,r);
		a=a->next;
	}
	return b;
}

/* checks if list of expression can be evaluated with no unused
 * operands 
 */
int /* truth value */
balanced(struct ll *pn) /* list of expressions, starting with a function or operator (Polish notation) */
{
	int d=depth(pn);
	int l=ll_length(pn);
  return (d==l-1);
}
