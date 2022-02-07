#ifndef LL_H
#define LL_H
#include <stdlib.h>
#include <string.h>
typedef struct ll ll_t;
struct ll {
	void *value;
	ll_t *next;
};

void ll_push(struct ll **, void *);
void* ll_pop(struct ll **);
void ll_append(struct ll **, void *);
void* ll_remove(struct ll **);
int ll_length(struct ll *a);
void ll_cat(struct ll **a, struct ll *b);
struct ll* ll_reverse(struct ll *a);
void ll_free(struct ll **a);
int ll_are_equal(struct ll *a, struct ll*b,  size_t value_size);
#endif
