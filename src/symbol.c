#include "symbol.h"
#include <string.h>
#include <stdio.h>

const char *fname[]={"exp","log","sin","cos","NA"};

static enum func match_func(const char *s){
	assert(s);
	int i;
	int n=sizeof(fname)/sizeof(char*);
	for (i=0;i<n;i++){
		if (strcmp(s,fname[i])==0) break;
	}
	//printf("[%s] function: %i (%s)\n",__func__,i,fname[i]);
	return i;
}

struct symbol* symbol_allocd(double d){
	struct symbol *n=malloc(sizeof(struct symbol));
	assert(n);
	n->type=symbol_number;
  n->value=d;
	n->nargs=0;
	return n;
}


struct symbol* symbol_alloc(char *s){
	assert(s);
	struct symbol *n=malloc(sizeof(struct symbol));
	assert(n);
	size_t len=strlen(s);
	char *p;
	char c=s[0];
	p=s;
	double d=strtod(s,&p);
	/* fprintf(stderr,"length(%s)=«%li»\n",s,len); */
	if (s==p){
    if (len==1 && strchr("+-*/^",c)){
			n->type=symbol_operator;
			n->name=c;
			n->nargs=2;			
		} else if (len==1 && isalpha(c)){
			n->type=symbol_var;
			n->name=c;
			n->nargs=0;
		} else {
			n->type=symbol_function;
			n->f=match_func(s);
			n->nargs=1;
		}
	} else {
		n->type=symbol_number;
    n->value=d;
		n->nargs=0;
	}
	return n;
}

void symbol_print(struct symbol *s){
	switch (s->type){
	case symbol_number:
		printf("%g ",s->value);
		break;
	case symbol_var:
		printf("%c ",s->name);
		break;
	case symbol_operator:
		printf("%c ",s->name);
		break;
	case symbol_function:
		printf("%s ",fname[s->f]);
		break;
	}
}

int is_double(struct symbol *s, double y){
	int z=0; /* false */
	double v;
	if(s && s->type==symbol_number){
		v=s->value - y;
	  z=((v<0?-v:v) < 1e-15);
	}
	return z;
}

int is_equal(struct symbol *a, struct symbol *b){
	int E=(a==b);
	if (a && b){
		E=(memcmp(a,b,sizeof(struct symbol))==0);
	}
	return E;
}
