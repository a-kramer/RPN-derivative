#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <string.h>
#include "rpn.h"
//#include "symbol.h"
//#include "ll.h"

struct ll* derivative(struct ll *pn, const char x);

void help(char *name){
	assert(name);
	printf("[%s]\tUsage: %s 'x' < rpn.txt\n",__func__,name);
	printf("\t%s will attempt to calculate the symbolic derivative\n\tof rpn with respect to the symbolic variable 'x'\n",name);
	printf("\texample: $ echo 'x y *' | %s x\n",name);
	printf("\t         y\n");	
}

struct ll* function_derivative(struct symbol *fun, struct ll *a, char x){
	struct ll *res=NULL;
	struct ll *a_rev=NULL;
	assert(fun->type==symbol_function);
	switch(fun->f){
	case f_exp:
		a_rev=rpn_reverse_copy(a);
		ll_cat(&res,a_rev);
		ll_append(&res,fun);
		ll_cat(&res,derivative(a,x));
		ll_append(&res,symbol_alloc("*"));
		break;
	case f_log:
		a_rev=rpn_reverse_copy(a);
		ll_append(&res,symbol_allocd(1.0));
		ll_cat(&res,a_rev);
		ll_append(&res,symbol_alloc("/"));
		ll_cat(&res,derivative(a,x));
		ll_append(&res,symbol_alloc("*"));
		free(fun);
		break;
	case f_sin:
		a_rev=rpn_reverse_copy(a);
		ll_cat(&res,a_rev);
		ll_append(&res,symbol_alloc("cos"));
		ll_cat(&res,derivative(a,x));
		ll_append(&res,symbol_alloc("*"));
		free(fun);
		break;
	case f_cos:
		a_rev=rpn_reverse_copy(a);
		ll_cat(&res,a_rev);
		ll_append(&res,symbol_alloc("sin"));
		ll_append(&res,symbol_allocd(-1.0));
		ll_append(&res,symbol_alloc("*"));		
		ll_cat(&res,derivative(a,x));
		ll_append(&res,symbol_alloc("*"));
		free(fun);
		break;
	default:
		printf("unhandled case");
	}
	return res;
}

struct ll* basic_op_derivative(struct symbol *op, struct ll *a, struct ll *b, const char x){
	struct ll *res=NULL;
	struct ll *a_rev=NULL;
	struct ll *b_rev=NULL;
	struct ll *bb=NULL;
	assert(op->type==symbol_operator);
	switch (op->name){
	case '+':
		ll_cat(&res,derivative(a,x));
		ll_cat(&res,derivative(b,x));
		ll_append(&res,op);
		break;
	case '-':
		ll_cat(&res,derivative(a,x));
		ll_cat(&res,derivative(b,x));
		ll_append(&res,op);
		break;
	case '*':
		free(op);
		a_rev=rpn_reverse_copy(a);
		b_rev=rpn_reverse_copy(b);
		ll_cat(&res,derivative(a,x));
		ll_cat(&res,b_rev);
		ll_append(&res,symbol_alloc("*"));
		ll_cat(&res,a_rev);
		ll_cat(&res,derivative(b,x));
		ll_append(&res,symbol_alloc("*"));
		ll_append(&res,symbol_alloc("+"));
		break;
	case '/':
		a_rev=rpn_reverse_copy(a);
		b_rev=rpn_reverse_copy(b);
		bb=rpn_copy(b_rev);
		ll_cat(&bb,rpn_copy(b_rev));
		ll_cat(&res,derivative(a,x));
		ll_cat(&res,b_rev);
		ll_append(&res,symbol_alloc("*"));
		ll_cat(&res,a_rev);
		ll_cat(&res,derivative(b,x));
		ll_append(&res,symbol_alloc("*"));
		ll_append(&res,symbol_alloc("-"));
		ll_cat(&res,bb);
		ll_append(&res,symbol_alloc("*"));
		ll_append(&res,op);
		break;		
	}
	return res;
}

struct ll* derivative(struct ll *pn, const char x){
	struct symbol *s=ll_pop(&pn);
	enum symbol_type t;
	struct ll *a=NULL, *b=NULL;
	struct ll *p=pn;
	struct ll *res=NULL;
	int i,d;
	if (s){
		t=s->type;
		switch (t){
		case symbol_number:
			ll_append(&res,symbol_alloc("0"));
			free(s);
			break;
    case symbol_var:
			if (x==s->name){
				ll_append(&res,symbol_alloc("1"));
			}else{
				ll_append(&res,symbol_alloc("0"));
			}
			free(s);
			break;
		case symbol_operator:
			b=p;
			d=depth(b);
			for (i=0;i<d;i++){
				assert(p->next);
				p=p->next;
			}
			a=p->next;
			p->next=NULL;
			p=a;
			d=depth(a);
			for (i=0;i<d;i++){
				assert(p->next);
				p=p->next;
			}
			p->next=NULL;
			ll_cat(&res,basic_op_derivative(s,a,b,x));
			break;
		case symbol_function:
			a=p;
			d=depth(a);
			for (i=0;i<d;i++){
				assert(p->next);
				p=p->next;
			}
			b=p->next;
			p->next=NULL;
			ll_cat(&res,function_derivative(s,a,x));
			break;
		}
	}
	return res;
}

/* open stdin and perform a derivative wrt to argv[1] */
int main(int argc, char* argv[]){
	size_t n=20;
	char *rpn=malloc(n);
	char *p, *s;
	size_t m=0;
	char *x;

	const char delim[]=" ";
	struct ll *pn=NULL; /* polish notation expression */
	struct ll *res=NULL;
	if (argc>1){
		x=argv[1];
		assert(isalpha(x[0]));
		do{
			m=getline(&rpn,&n,stdin);
			//fprintf(stderr,"[%s] line: %s (%li characters)\n",__func__,rpn,m);
			if (m>0 && !feof(stdin)){
				s=strchr(rpn,'\n');
				if (s) s[0]='\0';
				p=strtok(rpn,delim);
				pn=NULL;
				while (p){
					ll_push(&pn,symbol_alloc(p));
					p=strtok(NULL,delim);
				}
				if (pn && balanced(pn)) res=derivative(pn,x[0]);
				rpn_print(res);
				putchar('\n');
				ll_free(&res);
			}
		} while (!feof(stdin));
	} else {
		help(argv[0]);
	}
	return EXIT_SUCCESS;
}
