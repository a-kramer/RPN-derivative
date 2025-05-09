#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "rpn.h"

int priority(char op){
	int p;
	switch (op){
	case '=':
	case '<':
	case '>': p=0; break; 
	case '+': p=1; break;
	case '-': p=1; break;
	case '*': p=2; break;
	case '/': p=2; break;
	case '^': p=3; break;
	case '@': p=3; break;
	default: p=0;
	}
	return p;
}

void print_stack(struct ll *stack){
	char *p;
	printf("[%s] strings: ",__func__);
	while (stack){
		p=stack->value;
		printf("%s ",p);
		stack=stack->next;
	}
	putchar('\n');
}

int word_length(char *s){
	char *p=s;
	int k=0;
	if (p){
		while (*p!='\0' && (isalnum(*p) || strchr("~%@_",*p)!=NULL)){
			p++;
			k++;
		}
	}
	return k;
}

struct ll* infix_to_rpn(char *infix)
{
	struct ll *rpn=NULL;
	struct ll *stack=NULL;
	char *s,*p,t;
	double d;
	int k;
	s=infix;
	while ((*s)!='\0'){
		p=s;
		d=strtod(s,&p);
		if (s!=p){
			ll_append(&rpn,symbol_allocd(d));
			s=p;
		} else if (*s == '('){
			ll_push(&stack,memcpy(calloc(2,sizeof(char)),s,1));
			s++;
		} else if (*s == ')'){
			while (stack && *(p=ll_pop(&stack))!='('){
				ll_append(&rpn,symbol_alloc(p));
				free(p);
			}
			s++;
		} else if (*s == '@'){
			while (stack && (t=*((char*) stack->value))!='(' && priority(t)>=priority(*s)){
				p=ll_pop(&stack);
				ll_append(&rpn,symbol_alloc(p));
				free(p);
			}
			k=word_length(s);
			ll_push(&stack,memcpy(calloc(k+1,sizeof(char)),s,k));
			s+=k;
		} else if (s && *s!='\0' && strchr("^+-*/<>=",*s)){
			while (stack && (t=*((char*) stack->value))!='(' && priority(t)>=priority(*s)){
				p=ll_pop(&stack);
				ll_append(&rpn,symbol_alloc(p));
				free(p);
			}
			ll_push(&stack,memcpy(calloc(2,sizeof(char)),s,1));
			s++;
		} else if (s && *s==','){
			while (stack && (t=*((char*) stack->value))!='(' && priority(t)>=priority(*s)){
				p=ll_pop(&stack);
				ll_append(&rpn,symbol_alloc(p));
				free(p);
			}
			s++;
		} else if (s && isalpha(*s)) {
			k=word_length(s);
			p=memcpy(calloc(k+1,sizeof(char)),s,k);
			assert(p);
			ll_append(&rpn,symbol_alloc(p));
			free(p);
			s+=k;
		} else {
			s++;
		}
	}
	while (stack){
		p=ll_pop(&stack);
		ll_append(&rpn,symbol_alloc(p));
		free(p);
	}
	return rpn;
}

int main(int argc, char *argv[])
{
	size_t n=20;
	char *infix=malloc(n);
	long m=0;
	struct ll* rpn;
	while ((m=getline(&infix,&n,stdin))>0) {
		if (infix[m-1]=='\n') infix[m-1]='\0';
		rpn=infix_to_rpn(infix);
		rpn_print(rpn);
		putchar('\n');
	}
	return EXIT_SUCCESS;
}
