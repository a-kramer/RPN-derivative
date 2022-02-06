#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <string.h>
#include "symbol.h"
#include "ll.h"

#define NARGS(ll) ((ll)?(((struct symbol *)((ll)->value))->nargs):0)
#define IS_NUMBER(ll) (((struct symbol *)((ll)->value))->type == symbol_number)

struct ll* derivative(struct ll *pn, const char x);
void rpn_print(struct ll *rpn);

void help(char *name){
	assert(name);
	printf("[%s]\tUsage: %s 'x' < rpn.txt\n",__func__,name);
	printf("\t%s will attempt to calculate the symbolic derivative\n\tof rpn with respect to the symbolic variable 'x'\n",name);
	printf("\texample: $ echo 'x y *' | %s x\n",name);
	printf("\t         y\n");	
}

/* calculate the number of terms 
 * necessary to evaluate the first
 * symbol.
 */
int depth(struct ll *pn){
	int n=0;
	int d=0;
	if (pn){
		n=NARGS(pn);
		while (n){
			pn=pn->next;
			n--;
			d++;
			n+=NARGS(pn);			
		}		
	}
	return d;
}

void rpn_free(struct ll *rpn){
	struct symbol *s;
	while (rpn){
		s=ll_pop(&rpn);
		free(s);
	}
}

void rpn_print(struct ll *rpn){
	struct symbol *s;
	while (rpn){
		s=rpn->value;
		symbol_print(s);
		rpn=rpn->next;
	}
}

struct ll* rpn_reverse_copy(struct ll *a){
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

struct ll* rpn_copy(struct ll *a){
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

struct ll* function_derivative(enum func f, struct ll *a, char x){
	struct ll *res=NULL;
	struct ll *a_rev=NULL;
	switch(f){
	case f_exp:
		a_rev=rpn_reverse_copy(a);
		ll_cat(&res,a_rev);
		ll_append(&res,symbol_alloc("exp"));
		ll_cat(&res,derivative(a,x));
		ll_append(&res,symbol_alloc("*"));
		break;
	default:
		printf("unhandled case");
	}
	return res;
}


struct ll* basic_op_derivative(const char op, struct ll *a, struct ll *b, const char x){
	struct ll *res=NULL;
	struct ll *a_rev=NULL;
	struct ll *b_rev=NULL;
	struct ll *bb=NULL;
	char op0[2]={op,'\0'};
	switch (op){
	case '+':
		ll_cat(&res,derivative(a,x));
		ll_cat(&res,derivative(b,x));
		ll_append(&res,symbol_alloc(op0));
		break;
	case '-':
		ll_cat(&res,derivative(a,x));
		ll_cat(&res,derivative(b,x));
		ll_append(&res,symbol_alloc(op0));
		break;
	case '*':
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
		/*
		printf("a: ");
		rpn_print(a_rev);
		putchar('\n');
		printf("b: ");
		rpn_print(b_rev);
		putchar('\n');
		printf("bb: ");
		rpn_print(bb);
		putchar('\n');
		*/
		ll_cat(&res,derivative(a,x));
		ll_cat(&res,b_rev);
		ll_append(&res,symbol_alloc("*"));
		ll_cat(&res,a_rev);
		ll_cat(&res,derivative(b,x));
		ll_append(&res,symbol_alloc("*"));
		ll_append(&res,symbol_alloc("-"));
		ll_cat(&res,bb);
		ll_append(&res,symbol_alloc("*"));
		ll_append(&res,symbol_alloc("/"));
		break;		
	}
	return res;
}

struct ll* derivative(struct ll *pn, const char x){
	struct symbol *s=pn?pn->value:NULL;
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
			break;
    case symbol_var:
			if (x==s->name){
				ll_append(&res,symbol_alloc("1"));
			}else{
				ll_append(&res,symbol_alloc("0"));
			}
			break;
		case symbol_operator:
			assert(p->next);
			p=p->next;
			b=p;
			d=depth(b);
			for (i=0;i<d;i++){
				assert(p->next);
				p=p->next;
			}
			a=p->next;
			p->next=NULL;
			ll_cat(&res,basic_op_derivative(s->name,a,b,x));
			break;
		case symbol_function:
			assert(p->next);
			p=p->next;
			a=p;
			d=depth(a);
			for (i=0;i<d;i++){
				assert(p->next);
				p=p->next;
			}
			b=p->next;
			p->next=NULL;
			ll_cat(&res,function_derivative(s->type,a,x));
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
			if (m && !feof(stdin)){
				s=strchr(rpn,'\n');
				if (s) s[0]='\0';
				p=strtok(rpn,delim);
				while (p){
					ll_push(&pn,symbol_alloc(p));
					p=strtok(NULL,delim);
				}
				if (pn) res=derivative(pn,x[0]);
				rpn_print(res);
				putchar('\n');
				rpn_free(res);
			}
		} while (!feof(stdin));
	} else {
		help(argv[0]);
	}
	return EXIT_SUCCESS;
}
