#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <string.h>
#include <float.h>
#include "rpn.h"

#define OPT_NONE 0
#define OPT_SAFE_FRAC 1

static int options=OPT_NONE;
static double safety_val=DBL_MIN; 

void help(char *name){
	assert(name);
	printf("[%s]\tUsage: %s < rpn.txt\n",__func__,name);
	printf("\t%s will attempt to write an infix expression that evaluates to the same\n\tresult as evaluating the rpn expression directly\n\tThis program reads from stdin\n",name);
	printf("\texample: $ echo 'x 0 *' | %s\n",name);
}

void to_infix(struct ll *pn){
	struct symbol *s;
	struct ll *a, *b;
	if (pn) {
		s=ll_pop(&pn);
		switch (s->type){
		case symbol_operator:
			b=pn;
			a=ll_cut(b,depth(b)+1);
			printf("(");
			to_infix(a);
			printf("%c",s->name);
			if (options&OPT_SAFE_FRAC && s->name=='/'){
				putchar('(');
				printf("%g + ",safety_val);
				to_infix(b);
				putchar(')');
			} else {
				to_infix(b);
			}
			printf(")");
			break;
		case symbol_function:
			if (s->f == f_pow){
				b=pn;
				a=ll_cut(b,depth(b)+1);
				printf("pow(");
				to_infix(a);
				putchar(',');
				to_infix(b);
				putchar(')');
			} else {
				printf("%s(",function_name(s->f));
				to_infix(pn);
				putchar(')');
			}
			break;
		default:
			symbol_print(s);			
		}
	}
}


int main(int argc, char *argv[]){
	size_t n=20;
	char *rpn=malloc(n);
	char *p, *s;
	ssize_t m=0;
	const char delim[]=" ";
	struct ll *r=NULL;
	char *opt;
	size_t l;
	char *val;
	double d;
	int i;
	for (i=1;i<argc;i++){
		opt=argv[i];
		l=strlen(opt);
		val=strchr(opt,'=');
		if (val) {
			val++;
		}
		if (strcmp("-s",opt)==0){
			options|=OPT_SAFE_FRAC;
		} else if (val && memcmp("--safe-frac",opt,l<11?l:11)==0){
			options|=OPT_SAFE_FRAC;
			d=strtod(val,NULL);
			if (d>0) safety_val=d;
		}
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
			while (p){
				ll_push(&r,symbol_alloc(p));
				p=strtok(NULL,delim);
			}
			if (r){
				to_infix(r);
				putchar('\n');
			}
		}
	} while (!feof(stdin));
	return EXIT_SUCCESS;
}
