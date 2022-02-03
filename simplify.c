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
	printf("[%s]\tUsage: %s < rpn.txt\n",__func__,name);
	printf("\t%s will attempt to simplify a symbolic expression\n\tin reverse polish notation \n",name);
	printf("\texample: $ echo 'x 0 *' | %s\n",name);
	printf("\t         0\n");	
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

struct ll* function_simplify(struct symbol *a, struct symbol *func)
{
	struct ll* res=NULL;
	assert(func->type==symbol_function);
	switch (func->f){
	case f_exp:
		if(is_double(a,0.0)){
			free(a);
			free(func);
			ll_append(&res,symbol_alloc("1"));
		}
		break;
	case f_log:
		if (is_double(a,1.0)){
			free(a);
			free(func);
			ll_append(&res,symbol_alloc("0.0"));
		}
		break;
  case f_sin:
		if(is_double(a,0.0)){
			free(a);
			free(func);
			ll_append(&res,symbol_alloc("0"));
		}
		break;
  case f_cos:
		if(is_double(a,0.0)){
			free(a);
			free(func);
			ll_append(&res,symbol_alloc("1"));
		}
		break;
	}
	if (!res) {
		ll_append(&res,a);
		ll_append(&res,func);
	}
	return res;
}

struct ll* basic_op_simplify(struct symbol *a, struct symbol *b, struct symbol *op){
	struct ll* res=NULL;
	assert(op->type==symbol_operator);
	switch(op->name){
  case '+':
		if (is_double(a,0.0)){
			free(a);
			free(op);
			ll_append(&res,b);
		} else if (is_double(b,0.0)){
			free(b);
			free(op);
			ll_append(&res,a);
		}
		break;
	case '-':
		if (is_double(b,0.0)){
			ll_append(&res,a);
			free(b);
			free(op);
		} else if (is_double(a,0.0)){
			free(a);
			free(op);
			(b->value)*=-1.0;
			ll_append(&res,b);
		} else if (is_equal(a,b)){
			free(a);
			free(b);
			free(op);
			ll_append(&res,symbol_alloc("0"));
		}
		break;
	case '*':
		if (is_double(a,0.0) || is_double(b,0.0)){
			free(a);
			free(b);
			free(op);
			ll_append(&res,symbol_alloc("0"));
		}
		break;
  case '/':
		if (is_equal(a,b)){
			free(a);
			free(b);
			free(op);
			ll_append(&res,symbol_alloc("1"));
		} else if (is_double(a,0.0) && !is_double(b,0.0)){
			free(a);
			free(b);
			free(op);
			ll_append(&res,symbol_alloc("0"));
		}
		break;
	}
	if(!res) {
 		ll_append(&res,a);
 		ll_append(&res,b);
 		ll_append(&res,op);
	}
	return res;
}

struct ll* simplify(struct ll *r){
	struct symbol *s,*a,*b;
	struct ll *stack;
	struct ll *res=NULL;
	while (r){
		s=ll_pop(&r);
	  switch(s->type){
		case symbol_number:
			ll_push(&stack,s);
			break;
		case symbol_var:
			ll_push(&stack,s);
			break;
		case symbol_operator:
			b=ll_pop(&stack);
			a=ll_pop(&stack);
			ll_cat(&res,basic_op_simplify(a,b,s));
      break;
		case symbol_function:
			a=ll_pop(&stack);
			ll_cat(&res,function_simplify(a,s));
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
	ssize_t m=0;
	char *x;
	const char delim[]=" ";
	struct ll *r=NULL;
	struct ll *res=NULL;
	if (argc==1){
		do{
			m=getline(&rpn,&n,stdin);
			if (m && !feof(stdin)){
				s=strchr(rpn,'\n');
				if (s) s[0]='\0';
				p=strtok(rpn,delim);
				while (p){
					ll_append(&r,symbol_alloc(p));
					p=strtok(NULL,delim);
				}
				if (r) res=simplify(r);
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
