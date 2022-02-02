#ifndef LL_H
#define LL_H
#include <stdlib.h>
typedef struct ll ll_t;
struct ll {
	void *value;
	ll_t *next;
};
void ll_push(struct ll **, void *);
void* ll_pop(struct ll **);
void ll_append(struct ll **, void *);
void* ll_remove(struct ll **);
void ll_cat(struct ll **a, struct ll *b);
#endif
