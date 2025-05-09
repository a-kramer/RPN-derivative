#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <string.h>
#include <float.h>
#include "rpn.h"

#define OPT_NONE 0
#define OPT_SAFE_FRAC 1
#define OPT_LATEX 2

static int options=OPT_NONE;
static double safety_val=DBL_MIN;

void help(char *name){
	assert(name);
	printf("[%s]\tUsage: %s < rpn.txt\n",__func__,name);
	printf("\
\t%s will attempt to write an infix expression that evaluates to the same\n\
\tresult as evaluating the rpn expression directly\n\
\tThis program reads from stdin\n",name);
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
			printf("%c",s->op);
			if (options&OPT_SAFE_FRAC && s->op=='/'){
				printf("(%g + fabs(",safety_val);
				to_infix(b);
				printf("))");
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

void to_latex(struct ll *pn, int paren){
	struct symbol *s;
	struct symbol *next;
	struct ll *a, *b;
	int p;
	if (pn) {
		s=ll_pop(&pn);
		if (paren) printf("(");
		switch (s->type){
		case symbol_operator:
			b=pn;
			a=ll_cut(b,depth(b)+1);
			if (s->op=='/'){
				printf("\\frac{");
				to_latex(a,0);
				printf("}{");
				to_latex(b,0);
				printf("}");
			} else if (s->op=='*'){
				next=a->value;
				p=next->type==symbol_operator && strchr("+-",next->op)!=NULL;
				to_latex(a,p);
				printf(" ");
				next=b->value;
				p=next->type==symbol_operator && strchr("+-",next->op)!=NULL;
				to_latex(b,p);
			} else {
				to_latex(a,0);
				printf(" %c ",s->op);
				to_latex(b,0);
			}
			break;
		case symbol_function:
			if (s->f == f_pow){
				b=pn;
				a=ll_cut(b,depth(b)+1);
				next=a->value;
				p=next->type==symbol_operator || next->type==symbol_function ;
				printf("{");
				to_latex(a,p);
				printf("}^{");
				to_latex(b,0);
				printf("}");
			} else {
				printf("\\%s\\left(",function_name(s->f));
				to_latex(pn,0);
				printf("\\right)");
			}
			break;
		default:
			latex_symbol(s);
		}
		if (paren) printf(")");
	}
}


int main(int argc, char *argv[]){
	size_t n=20;
	char *rpn=malloc(n);
	char *p;
	ssize_t m=0;
	const char delim[]=" ";
	struct ll *r=NULL;
	char *opt;
	size_t l;
	char *val;
	double d=0;
	int i;
	/* parse options */
	for (i=1;i<argc;i++){
		opt=argv[i];
		l=strlen(opt);
		val=strchr(opt,'=');
		if (val) {
			val++;
		}
		if (l>0 && memcmp("-s",opt,l<2?l:2)==0){
			options|=OPT_SAFE_FRAC;
			d=strtod(opt+2,NULL);
		} else if (val && memcmp("--safe-frac",opt,l<11?l:11)==0){
			options|=OPT_SAFE_FRAC;
			d=strtod(val,NULL);
		} else if (l>0 && memcmp("--latex",opt,l<7?l:7)==0){
			options|=OPT_LATEX;
		}
		if (d>0) safety_val=d;
	}
	/* read from stdin */
	while ((m=getline(&rpn,&n,stdin))>0){
		if (rpn[m-1]=='\n') rpn[m-1]='\0';
		p=strtok(rpn,delim);
		/* init */
		r=NULL;
		while (p){
			ll_push(&r,symbol_alloc(p));
			p=strtok(NULL,delim);
		}
		if (r && (options & OPT_LATEX)) {
			to_latex(r,0);
		} else if (r) {
			to_infix(r);
		}
		putchar('\n');
	}
	return EXIT_SUCCESS;
}
