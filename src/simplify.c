#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <string.h>
#include "rpn.h"
//#include "symbol.h"
//#include "ll.h"

#define NARGS(ll) ((ll)?(((struct symbol *)((ll)->value))->nargs):0)
#define SYM_VALUE(s) ((double) ((struct symbol *)(s))->value)
#define IS_NUMBER(ll) (((struct symbol *)((ll)->value))->type == symbol_number)
#define _n putchar('\n')

struct ll* simplify(struct ll *stack);

void help(char *name){
	assert(name);
	printf("[%s]\tUsage: %s < rpn.txt\n",__func__,name);
	printf("\t%s will attempt to simplify a symbolic expression\n\tin reverse polish notation \n",name);
	printf("\texample: $ echo 'x 0 *' | %s\n",name);
	printf("\t         0\n");
}

/* prints up tp depth(c)+1 items */
void pn_print(struct ll *c){
	int n=depth(c)+1;
	while (c && (n--)>0){
		symbol_print(c->value);
		putchar(' ');
		c=c->next;
	}
	_n;
}

struct ll* term_copy(struct ll* a){
	int n=depth(a)+1;
	struct ll *b=NULL;
	size_t z=sizeof(struct symbol);
	while (a && (n--)>0){
		ll_push(&b,memcpy(malloc(z),a->value,z));
		a=a->next;
	}
	return b;
}

/* this function determines where the first operand to an operator
 * ends. It assumes that operators come first (it is a reverse polish
 * notation expression, but the linked list stores it as read from the
 * back, so reversed reverse polish notation: `a b +` is stored as `'+'
 * -> 'b' -> 'a'`. The input (in normal notation) `a b +` will return a
 * pointer to a.
 */
struct ll* /* a pointer to the second operand */
operand1(struct ll *pn) /* polish notation, kind of */
{
	assert(pn);
	struct symbol *s=pn->value;
	assert(s && s->type==symbol_operator);
	pn=pn->next;
	int d=depth(pn)+1;
	while (pn && d-->0){
		pn=pn->next;
	}
	return pn;
}

/* this function tries to find a common factor c of a and b: a=c*x and
	 b=c*y. It returns pointers to c, one pointer for c's location in a
	 and one pointer for c's location in b. c, a and b are all
	 expressions (not necessarily numbers). If c exists in multiple
	 powers, the first match is returned. */
int /* returns 0 if no common factor was found */
common_factor(
	struct ll *a, /* input in polish notation */
	struct ll *b, /* input in polish notation */
	struct ll **ca, /* OUT: pointer to c in a */
	struct ll **cb) /* OUT: pointer to c in b */
{
	int RET=0;
	struct symbol *s;
	struct ll *aa,*ab;
	struct ll *ba,*bb;
	int da=depth(a);
	int db=depth(b);
	/*
	printf("[%s] depth(a)=%i, depth(b)=%i\n",__func__,da,db);
	printf("a: "); pn_print(a);
	printf("b: "); pn_print(b);
	*/
	const size_t symsize=sizeof(struct symbol);
	char ha=ll_hash(a,symsize,da+1);
	char hb=ll_hash(b,symsize,db+1);
	if (a && b && da==db && ha==hb && ll_start_equal(a,b,da+1,symsize)){
		*ca=a;
		*cb=b;
		RET=1;
	} else {
		if (a){
			s=a->value;
			if (s->type==symbol_operator){
				ab=a->next;
				aa=operand1(a);
				switch (s->op){
				case '*':
					RET=common_factor(aa,b,ca,cb) || common_factor(ab,b,ca,cb);
					break;
				case '/':
					RET=common_factor(aa,b,ca,cb);
					break;
				}
			}
		}
		if (b && !RET){
			s=b->value;
			if (s->type==symbol_operator){
				bb=b->next;
				ba=operand1(b);
				switch (s->op){
				case '*':
					RET=common_factor(a,ba,ca,cb) || common_factor(a,bb,ca,cb);
					break;
				case '/':
					RET=common_factor(a,ba,ca,cb);
					break;
				}
			}
		}
	}
	return RET;
}

/* base^p */
struct ll* simplify_pow(struct symbol *func, struct ll *base, struct ll *p)
{
	struct ll* res=NULL;
	if (depth(p)==0 && is_double(p->value,1.0)){
		ll_free(&p);
		ll_cat(&res,simplify(base));
		free(func);
	} else if (depth(p)==0 && is_double(p->value,0.0)){
		ll_free(&p);
		ll_free(&base);
		ll_append(&res,symbol_allocd(1.0));
		free(func);
	} else if (depth(base)==0 && is_double(base->value,1.0)){
		ll_free(&p);
		ll_free(&base);
		ll_append(&res,symbol_allocd(1.0));
		free(func);
	} else {
		ll_cat(&res,simplify(base));
		ll_cat(&res,simplify(p));
		ll_append(&res,func);
	}
	return res;
}


struct ll* function_simplify(struct ll *a, struct symbol *func)
{
	//size_t sym_size=sizeof(struct symbol);
	int a0=(depth(a)==0 && is_double(a->value,0.0));
	int a1=(depth(a)==0 && is_double(a->value,1.0));
	struct ll *base=NULL;
	struct ll *res=NULL;
	assert(func->type==symbol_function);
	switch (func->f){
	case f_exp:
		if(a0){
			ll_free(&a);
			free(func);
			ll_append(&res,symbol_allocd(1.0));
		}
		break;
	case f_log:
		if (a1){
			ll_free(&a);
			free(func);
			ll_append(&res,symbol_allocd(0.0));
		}
		break;
	case f_sin:
		if(a0){
			ll_free(&a);
			free(func);
			ll_append(&res,symbol_allocd(0.0));
		}
		break;
	case f_cos:
		if(a0){
			ll_free(&a);
			free(func);
			ll_append(&res,symbol_allocd(1.0));
		}
		break;
	case f_pow:
		/* base^p*/
		base=ll_cut(a,depth(a)+1);
		ll_cat(&res,simplify_pow(func,base,a));
		break;
	default:
		fprintf(stderr,"[%s] unknown function «%i»\n",__func__,func->f);
	}
	if (!res) {
		ll_cat(&res,simplify(a));
		ll_append(&res,func);
	}
	return res;
}


struct ll* basic_op_simplify(struct ll *a, struct ll *b, struct symbol *s)
{
	struct ll* res=NULL;
	size_t sym_size=sizeof(struct symbol);
	int da=depth(a);
	int db=depth(b);
	int a0=(da==0 && is_double(a->value,0.0));
	int a1=(da==0 && is_double(a->value,1.0));
	int b0=(db==0 && is_double(b->value,0.0));
	int b1=(db==0 && is_double(b->value,1.0));
	struct ll *c=NULL, *ca=NULL, *cb=NULL;
	assert(s->type==symbol_operator);
	switch(s->op){
	case '+':
		if (a0){
			ll_free(&a);
			ll_cat(&res,simplify(b));
		} else if (b0){
			ll_free(&b);
			ll_cat(&res,simplify(a));
		} else if (common_factor(a,b,&ca,&cb)){
			c=term_copy(ca);
			ll_cat(&res,c);
			ll_push(ll_rm(&a,ca,depth(ca)+1),symbol_allocd(1.0));
			ll_push(ll_rm(&b,cb,depth(cb)+1),symbol_allocd(1.0));
			ll_cat(&res,simplify(a));
			ll_cat(&res,simplify(b));
			ll_append(&res,symbol_alloc("+"));
			ll_append(&res,symbol_alloc("*"));
		} else if (is_numeric(a->value) && is_numeric(b->value)){
			ll_append(&res,symbol_allocd(SYM_VALUE(a->value)+SYM_VALUE(b->value)));
			ll_free(&a);
			ll_free(&b);
		}
		break;
	case '-':
		if (b0){
			ll_free(&b);
			ll_cat(&res,simplify(a));
		} else if (ll_are_equal(a,b,sym_size)){
			ll_free(&a);
			ll_free(&b);
			ll_append(&res,symbol_allocd(0.0));
		} else if (common_factor(a,b,&ca,&cb)){
			c=term_copy(ca);
			ll_cat(&res,c);
			ll_push(ll_rm(&a,ca,depth(ca)+1),symbol_allocd(1.0));
			ll_push(ll_rm(&b,cb,depth(cb)+1),symbol_allocd(1.0));
			ll_cat(&res,simplify(a));
			ll_cat(&res,simplify(b));
			ll_append(&res,symbol_alloc("-"));
			ll_append(&res,symbol_alloc("*"));
		} else if (is_numeric(a->value) && is_numeric(b->value)){
			ll_append(&res,symbol_allocd(SYM_VALUE(a->value)-SYM_VALUE(b->value)));
			ll_free(&a);
			ll_free(&b);
		}
		break;
	case '*':
		if (a0 || b0){
			ll_free(&a);
			ll_free(&b);
			ll_append(&res,symbol_allocd(0.0));
		} else if (a1){
			ll_free(&a);
			ll_cat(&res,simplify(b));
		} else if (b1){
			ll_free(&b);
			ll_cat(&res,simplify(a));
		}
		break;
	case '/':
		if (ll_are_equal(a,b,sym_size)){
			ll_free(&a);
			ll_free(&b);
			ll_append(&res,symbol_allocd(1.0));
		} else if (a0 && !b0){
			ll_free(&a);
			ll_free(&b);
			ll_append(&res,symbol_allocd(0.0));
		} else if (common_factor(a,b,&ca,&cb)){
			ll_push(ll_rm(&a,ca,depth(ca)+1),symbol_allocd(1.0));
			ll_push(ll_rm(&b,cb,depth(cb)+1),symbol_allocd(1.0));
		} else if (b1) {
			ll_free(&b);
			ll_cat(&res,simplify(a));
		}
		break;
	}
	if(!res) {
 		ll_cat(&res,simplify(a));
 		ll_cat(&res,simplify(b));
 		ll_append(&res,s);
	}
	return res;
}

struct ll* simplify(struct ll *stack){
	struct symbol *s;
	struct ll *a,*b;
	struct ll *res=NULL;
	/* printf("[%s] stack: ",__func__); */
	/* rpn_print(stack); */
	/* putchar('\n'); */
	/* fflush(stdout); */
	if (stack){
		s=ll_pop(&stack);
		switch(s->type){
		case symbol_operator:
			b=stack;
			a=ll_cut(b,depth(b)+1);
			stack=ll_cut(a,depth(a)+1);
			ll_cat(&res,basic_op_simplify(a,b,s));
			break;
		case symbol_function:
			ll_cat(&res,function_simplify(stack,s));
			break;
		default:
			ll_append(&res,s);
		}
	}
	return res;
}

/* open stdin to read an expression in reverse polish notation to simplify it using very simple rules */
int main(int argc, char* argv[]){
	size_t n=20;
	char *rpn=malloc(n);
	char *p;
	ssize_t m=0;
	int i,N=1;
	const char delim[]=" ";
	struct ll *r=NULL;
	struct ll *res=NULL;
	if (argc==2){
		N=strtol(argv[1],NULL,10);
	}
	do{
		m=getline(&rpn,&n,stdin);
		if (m>0 && !feof(stdin)){
			rpn[m-1]='\0';
			p=strtok(rpn,delim);
			/* init */
			r=NULL;
			res=NULL;
			while (p){
				ll_push(&r,symbol_alloc(p));
				p=strtok(NULL,delim);
			}
			if (r && balanced(r)){
				for (i=0; i<N; i++){
					res=simplify(r);
					if (i<N-1) r=ll_reverse(res);
				}
			}
			rpn_print(res);
			printf("\n");
			ll_free(&res);
		}
	} while (!feof(stdin));
	return EXIT_SUCCESS;
}
