#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <string.h>
#include "rpn.h"

void help(char *name){
	assert(name);
	printf("[%s]\tUsage: %s < rpn.txt\n",__func__,name);
	printf("\t%s will attempt to write a function\n\tthat performs the instructions passed via stdin\n",name);
	printf("\texample: $ echo 'x 0 *' | %s\n",name);
}

void print_push(struct symbol *s)
{
	switch (s->type){
	case symbol_number:
		printf("\tstack[n++]=%g;\n",s->value);
		break;
	case symbol_var:
		printf("\tstack[n++]=%c;\n",s->name);
		break;
	default:
		printf("/* symbol is neither number nor variable */\n");
		printf("/* "); symbol_print(s); printf("*/\n");
	}
}

void print_op(const char op)
{
	printf("\tstack[n-2] = stack[n-2] %c stack[n-1];\n",op);
	printf("\tn--;\n");
}

void print_function(struct symbol *s)
{
	assert(s->type == symbol_function);
	switch(s->f){
	case f_pow:
		printf("\tstack[n-2] = pow(stack[n-1],stack[n-2]);\n");
		printf("\tn--;\n");
		break;
  default:
		printf("\tstack[n-1] = %s(stack[n-1]);\n",function_name(s->f));
	}
}

/* writes only part of the body of a function that calculates the rpn */
int /* the minimum size of the stack needed for calculations*/
write_code(struct ll *rpn)
{
	struct symbol *s;
	int k=0;
	while (rpn) {
		s=ll_pop(&rpn);
		switch (s->type){
		case symbol_number:
		case symbol_var:
			print_push(s);
			k++;
			break;
		case symbol_operator:
			print_op(s->name);
			break;
		case symbol_function:
			print_function(s);
			break;
		default:
			break;
		}	
	}
	return k;
}

void copy_variables(struct ll **vars, struct ll *rpn )
{
	struct symbol *s;
	size_t z=sizeof(struct symbol);
	while (rpn){
		s=rpn->value;
		if (s->type == symbol_var){
			ll_push(vars,memcpy(malloc(z),s,z));
		}
		rpn=rpn->next;
	}
}

void print_vars(struct ll *vars)
{
	printf("\tdouble ");
	while	(vars){
		symbol_print(vars->value);
		if (vars->next)
			printf(", ");
		else
			printf(";\n");
		vars=vars->next;
	}
}

int main(int argc, char *argv[]){
	size_t n=20;
	char *rpn=malloc(n);
	char *p, *s;
	ssize_t m=0;
	int N,stack_size=0;
	int i=0;
	struct ll *vars=NULL;
	const char delim[]=" ";
	struct ll *r=NULL;

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
				ll_append(&r,symbol_alloc(p));
				p=strtok(NULL,delim);
			}
			if (r){
				copy_variables(&vars,r);
				printf("\t/* "); rpn_print(r); printf(" */\n");
				printf("\tn=0;\n");
				N=write_code(r);
				printf("\t%s[%i]=stack[0];\n","jac",i++);
				stack_size=N>stack_size?N:stack_size;
			}
		}
	} while (!feof(stdin));
	print_vars(vars);
	return EXIT_SUCCESS;
}
