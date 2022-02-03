#ifndef SYMBOL_H
#define SYMBOL_H
#include <stdlib.h>
#include <assert.h>
#include <ctype.h>

enum symbol_type {symbol_number, symbol_var, symbol_operator, symbol_function};
enum func {f_exp, f_log, f_sin, f_cos};


struct symbol {
	enum symbol_type type;
	union{
		char name;
		double value;
		enum func f;
	};
	int nargs;
};

struct symbol* symbol_alloc(char *s);
void symbol_print(struct symbol *s);
int is_double(struct symbol *s, double y);
int is_equal(struct symbol *a, struct symbol *b);
#endif
