#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <string.h>
#include "rpn.h"
//#include "symbol.h"
//#include "ll.h"

#define NARGS(ll) ((ll)?(((struct symbol *)((ll)->value))->nargs):0)
#define IS_NUMBER(ll) (((struct symbol *)((ll)->value))->type == symbol_number)

struct ll* simplify(struct ll *stack);

void help(char *name){
	assert(name);
	printf("[%s]\tUsage: %s < rpn.txt\n",__func__,name);
	printf("\t%s will attempt to simplify a symbolic expression\n\tin reverse polish notation \n",name);
	printf("\texample: $ echo 'x 0 *' | %s\n",name);
	printf("\t         0\n");	
}

struct ll* function_simplify(struct ll *a, struct symbol *func)
{
	//size_t sym_size=sizeof(struct symbol);
	int a0=(depth(a)==0 && is_double(a->value,0.0));
	int a1=(depth(a)==0 && is_double(a->value,1.0));
	
	struct ll* res=NULL;
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
	default:
		fprintf(stderr,"[%s] unknown function «%i»\n",__func__,func->f);		
	}
	if (!res) {
		ll_cat(&res,simplify(a));
		ll_append(&res,func);
	}
	return res;
}

struct ll* basic_op_simplify(struct ll *a, struct ll *b, struct symbol *op)
{
	struct ll* res=NULL;
	size_t sym_size=sizeof(struct symbol);
	int da=depth(a);
	int db=depth(b);
	int a0=(da==0 && is_double(a->value,0.0));
	int a1=(da==0 && is_double(a->value,1.0));
	int b0=(db==0 && is_double(b->value,0.0));
	int b1=(db==0 && is_double(b->value,1.0));
	
	assert(op->type==symbol_operator);
	switch(op->name){
	case '+':
		if (a0){
			ll_free(&a);
			ll_cat(&res,simplify(b));
		} else if (b0){
			ll_free(&b);
			ll_cat(&res,simplify(a));
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
		}
		break;
	}
	if(!res) {
 		ll_cat(&res,simplify(a));
 		ll_cat(&res,simplify(b));
 		ll_append(&res,op);
	}
	return res;
}

struct ll* simplify(struct ll *stack){
	struct symbol *s;
	int i,d;
	struct ll *p,*a,*b;
	struct ll *res=NULL;
	if (stack){
		s=ll_pop(&stack);
		switch(s->type){
		case symbol_operator:
			p=stack;
			b=p;
			d=depth(b);
			for (i=0;i<d;i++){
				assert(p->next);
				p=p->next;
			}
			a=p->next;
			p->next=NULL;
			d=depth(a);
			p=a;
			for (i=0;i<d;i++){
				assert(p->next);
				p=p->next;
			}
			stack=p->next;
			p->next=NULL;
			ll_cat(&res,basic_op_simplify(a,b,s));
			break;
		case symbol_function:
			a=stack;
			d=depth(a);
			p=a;
			for (i=0;i<d;i++){
				assert(p->next);
				p=p->next;
			}
			stack=p->next;
			p->next=NULL;			
			ll_cat(&res,function_simplify(a,s));
			break;
		default:
			ll_append(&res,s);
		}
		ll_cat(&res,simplify(stack));	
	}
	return res;
}

/* open stdin to read an expression in reverse polish notation to simplify it using very simple rules */
int main(int argc, char* argv[]){
	size_t n=20;
	char *rpn=malloc(n);
	char *p, *s;
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
		//printf("[%s] line: %s (%li characters)\n",__func__,rpn,m);
		if (m>0 && !feof(stdin)){
			s=strchr(rpn,'\n');
			if (s) s[0]='\0';
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
