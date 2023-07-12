#include "symbol.h"
#include <string.h>
#include <stdio.h>

const char *fname[]={"exp","log","sin","cos","pow",""};
const int fnargs[]={1,1,1,1,2,0};

/* This function tries to match the contents of a string against a
 * list of known function names. The global list of function names
 * contains an empty string "", which corresponds to the enum value
 * `f_NA`. So, passing an empty string to this function will have the
 * same effect as passing an unknown function:
 * `match_func("")==match_func("bar")` because `bar` isn't one of the
 * known functions.
 */
static enum func /* symbol.h defines the enum, the last enum entry `f_NA` means that no match was found. */
match_func(const char *s) /* a \0 terminated string, like "exp" or "sin" */
{
	assert(s);
	int i;
	int n=sizeof(fname)/sizeof(char*);
	for (i=0;i<n-1;i++){
		if (strcmp(s,fname[i])==0) break;
	}
	return i;
}

/* This function allocates memory for a new symbol and uses the value of `d` to initialize. */
struct symbol* /* a symbol of type `symbol_number` with value `d` */
symbol_allocd(double d) /* the value of the new symbol */
{
  struct symbol *n=calloc(1,sizeof(struct symbol));
	assert(n);
	n->type=symbol_number;
  n->value=d;
	n->nargs=0;
	return n;
}

struct symbol* symbol_alloc_op(char op)
{
  struct symbol *n=calloc(1,sizeof(struct symbol));
	assert(n);
	if (op=='\0' || !strchr("+-*/",op)){
		fprintf(stderr,"[%s] «%c» is not a known operatopr.\n",__func__,op);
	}
	assert(op!='\0' && strchr("+-*/",op));
	n->type=symbol_operator;
	n->op=op;
	n->nargs=0;
	return n;
}

/* This is the more flexible allocation function and can create all
 * kinds of symbols: numbers, variables, operators and functions. The
 * string `s` is used to initialize the new symbol struct. Conversion
 * to a double precision number is attempted, if that fails, the
 * string is checked against known operator symbols. strings that
 * begin with the symbol @ are interpreted as function
 * names. Otherwise the string is a variable name.
 */
struct symbol* /* a pointer to the allocated memory for the new symbol */
symbol_alloc(char *s) /* a string used to initialize the symbol struct with a type and contents */
{
	assert(s);
	struct symbol *n=calloc(1,sizeof(struct symbol));
	assert(n);
	size_t len=strlen(s);
	char *p;
	char c=s[0];
	size_t z=MAX_NAME_SIZE-1;
	z=(len>z)?z:len;
	p=s;
	double d=strtod(s,&p);
	if (s==p){
		if (len==1 && c && strchr("+-*/",c)){
			n->type=symbol_operator;
			n->op=c;
			n->nargs=2;
		} else if (c=='^') {
			n->type=symbol_function;
			n->f=f_pow;
			n->nargs=2;
		} else if (c=='@') {
			n->type=symbol_function;
			n->f=match_func(s+1);
			n->nargs=fnargs[n->f];
			if (n->f == f_NA) fprintf(stderr,"[%s] unimplemented function: «%s»\n",__func__,s);
		} else if (isalpha(c)){
			n->type=symbol_var;
			*((char*) memcpy(n->name,s,z)+z)='\0';
			n->nargs=0;
		} else {
			fprintf(stderr,"[%s] unexpected case «%s».\n",__func__,s);
			abort();
		}
	} else {
		n->type=symbol_number;
    n->value=d;
		n->nargs=0;
	}
	return n;
}

/* Given a function enumerator, this returns the function's name */
const char* /* pointer to the right entry in a global array of strings */
function_name(enum func f) /* one of the known function enum values */ {
  return fname[f];
}

/* This function prints a representation of the symbol, as appropriate
 * for the type.
 */
void symbol_print(struct symbol *s) /* the symbol to print (number, operator, varibale name, or function) */
{
	switch (s->type){
	case symbol_number:
		printf("%g",s->value);
		break;
	case symbol_var:
		printf("%s",s->name);
		break;
	case symbol_operator:
		printf("%c",s->op);
		break;
	case symbol_function:
		printf("@%s",fname[s->f]);
		break;
	default:
		putchar(' ');
	}
}

/* This function checks whether the symbol is a number (at all). */
int /* truth value (the normal kind) */
is_numeric(struct symbol *s) /* the symbol to check */
{
	return (s && s->type==symbol_number);
}


/* This function checks whether the symbol is a number and equal to
 * the given value within double precision rounding errors
 * `(1e-15)+(1e-15)*|y|`. So, the equality is approximated.
 */
int /* truth value */
is_double(
	struct symbol *s, /* the symbol to check for approximate equality */
	double y) /* the value to compare against */
{
	int z=0; /* false */
	double v;
	if(s && s->type==symbol_number){
		v=s->value - y;
	  z=((v<0?-v:v) < 1e-15 + 1e-15*(y<0?-y:y));
	}
	return z;
}

/* This function compares the symbol to `y` and returns
```
  || case |value|
  ||------|-----|
  ||  s>y |  1  |
  ||  s<y | -1  |
  ||  s=y |  0  |
  ||other | -2  |
```

If the symbol isn't a number an error code is
returned (not -1, 0, 1). */
int /* comparison result */
symbol_cmpd(
	struct symbol *s, /* the symbol to check for approximate equality */
	double y) /* the value to compare against */
{
	int z=-2; /* error code */
	double v;
	if(s && s->type==symbol_number){
		v=s->value;
		z=v>y?1:(v<y?-1:0);
	}
	return z;
}


/* This function tests whether `a` is equal to `b`. It uses
 * `memcmp()`, so the equality must be exact, but it works regardless
 * of the symbol's type. Two non-existent symbols are considered
 * equal, as in: `(NULL==NULL)`, simlarly `is_equal(a,a)` is true.
 */
int /* truth value */
is_equal(
 struct symbol *a, /* left side of the comparison. */
 struct symbol *b) /* right side of the comparison. */
{
	int E=(a==b);
	if (a && b && a!=b){
		E=(memcmp(a,b,sizeof(struct symbol))==0);
	}
	return E;
}
