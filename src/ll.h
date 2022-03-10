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
struct ll* ll_cut(struct ll *a,	int k);
struct ll* ll_copy(	struct ll *a,	size_t z);
struct ll* ll_reverse(struct ll *a);
void ll_free(struct ll **a);
void ll_clear(struct ll **a);
int ll_are_equal(struct ll *a, struct ll*b,  size_t value_size);
int ll_start_equal(struct ll *a, struct ll *b, int n, size_t value_size);
struct ll** ll_rm(struct ll **ac, struct ll *c, int n);
char ll_hash(struct ll *a, size_t vsize, int n);
#endif
