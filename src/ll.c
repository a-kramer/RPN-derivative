#include "ll.h"
#include <assert.h>

/* appends an element `e` to the end of linked list `a` This will
 * allocate some more heap memory for the list.  On exit, *a will be
 * pointing to what it was before, or the new element, if the list was
 * initially empty.
 */
void ll_append(
	struct ll **a, /* `a` is the first element, `*a` may be `NULL` */
	void *e) /* new element */
{
	struct ll *c=*a;
	struct ll *n=malloc(sizeof(struct ll));
	n->next=NULL;
	n->value=e;
	if (c) {
		while (c->next){
			c=c->next;
		}
		c->next=n;
	} else {
		*a=n;
	}
}

/* This function removes the last element from the list and returns
 * the pointer to its value (the pointer that was originally used to
 * store the element).
 */
void* /* pointer to the stored element */
ll_remove(struct ll **L) /* `L` is the first element of the list (or *L is NULL). */
{
	struct ll **a=L;
	void *r=NULL;
	while (*a && (*a)->next){
		a=&((*a)->next);
	}
	r=(*a)->value;
	free(*a);
	*a=NULL;
	return r;
}

/* The value `e` is placed first into the linked list, pushing the
 * other elements one position further. Once done *L will point to the
 * new first element.
 */
void ll_push
(struct ll **L, /* `L` is the first element,  */
 void *e) /* new element */
{
	struct ll *n=malloc(sizeof(struct ll));
	n->next=*L;
	n->value=e;
	*L=n;
}

/* Removes the first element from the linked list, all other elements
 * move one position to the front.
 */
void* /* the contents formerly stored in first position */
ll_pop(struct ll **L) /* linked list (address of pointer to first element) */
{
	void *r=NULL;
	struct ll *a;
	if (*L){
		r=(*L)->value;
		a=*L;
		(*L)=(*L)->next;
		free(a);
	}
	return r;
}

/* given a list `a` and a length `k`, `ll_cut` will sever the list's connection after `k` elements and divide the list in two, `a` will continue pointing to the first `k` elements. (no allocations) */
struct ll* /* the remainder of the list (tail) */
ll_cut(
	struct ll *a, /* list to cut */
	int k) /* steps taken from before cutting. */
{
	struct ll *p=a;
	struct ll *b=NULL;
	while (p && --k>0){
		p=p->next;
	}
	if (p) {
		b=p->next;
		p->next=NULL;
	}
	return b;
}

/* concatenates two lists, by appending `b` to the end of `a` */
void ll_cat
(struct ll **a, /* `*a` will point to `b` if it was NULL before, new head of the list */
 struct ll *b) /* `b` will remain a valid pointer after this functionis called */
{
	assert(a);
	struct ll *c=*a;
	if (c){
		while (c->next){
			c=c->next;
		}
		c->next=b;
	} else {
		*a=b;
	}
}

/* This will reverse the order of elements within the list, no
 * allocations will be done (just pointer re-wiring). 
 */
struct ll* /* returns the new first element (previously last element) */
ll_reverse(struct ll *a) /* upon return, `a` will still point to the same element, now last in the list. */
{
	struct ll *c=NULL;
	void *v;
	while (a){
		v=ll_pop(&a);
		ll_push(&c,v);
	}
	return c;
}

/* This copies linked list `a`, including the stored values, via
 * `memcpy()`. The elements must not contain pointers to more
 * allocated memory, this is not a deep/nested copy.
 */
struct ll* /* a new list, with heap allocated memory */
ll_copy(
	struct ll *a, /* list to copy */
	size_t z) /* size of the elements as reported by `sizeof()` */
{
	assert(z);
	struct ll *b=NULL;
	struct ll **p=&b;
	while(a){
		*p=malloc(sizeof(struct ll));
		(*p)->value=malloc(z);
		memcpy((*p)->value,a->value,z);
		p=&((*p)->next);
		a=a->next;
	}
	return(b);
}

/* This function assumes that all stored values can be freed using
 * `free(a->value)` (i.e. the value entry cannot have pointers in it,
 * that were used to allocate more memory, as with say an array of
 * pointers, or a struct with pointers). It will remove all elements
 * from the list and free the contents. To make it harder to access
 * the freed elements `*a` will be set to NULL.
 */
void ll_free(struct ll **a) /* the linked list to clear. */
{
	struct ll *t;
	while(*a){
		t=*a;
		*a=(*a)->next;
		free(t->value);
		free(t);
	}
}

/* In contrast to `ll_free()`, this function just destroys the linked
 * list, without freeing the values.
 */
void ll_clear(struct ll **a) /* the linked list to clear. */
{
	struct ll *t;
	while(*a){
		t=*a;
		*a=(*a)->next;
		free(t);
	}
}

/* This function will check whether two lists `a` and `b` have
 * identical values (using memcmp on each pair of elements). Both
 * pointers will be used to traverse the lists and should be both NULL
 * at the end. if the lists are of different lengths, then the
 * pointers will not be both NULL and the final check (a==b)
 * fails. Two empty lists _are_ equal. This works only if the elements
 * of the list are of the same size, as memcmp is used. This will fail
 * if the elements contain pointers to heap memory themselves, as
 * those will be outside of what memcmp compares.
 */
int /* returns an integer truth value */
ll_are_equal
(struct ll *a, /* first list */
 struct ll *b, /* second list */
 size_t value_size) /* sizeof(a->value) */
{
	int E=1;
	while (a && b){
		E=E && (memcmp(a->value,b->value,value_size)==0);
		a=a->next;
		b=b->next;
	}
	return (E && a==b);
}

/* This function will check whether two lists `a` and `b` have
 * identical values in thefirst n places (using memcmp on each pair of
 * elements). Similar to `ll_are_equal()`.
 */
int /* returns an integer truth value */
ll_start_equal
(struct ll *a, /* first list */
 struct ll *b, /* second list */
 int n, /* equality up to n elements */
 size_t value_size) /* sizeof(a->value) */
{
	int E=1;
	while (a && b && n-- > 0){
		E=E && (memcmp(a->value,b->value,value_size)==0);
		a=a->next;
		b=b->next;
	}
	return (E);
}


/* removes and frees sub-list c of size n from list ac, returns an
 * address to the pointer that used to point to c (e.g. a 'next'
 * pointer's address).
 */
struct ll** /* either ac or the address of a next pointer, where c used to be */
ll_rm(
	struct ll **ac, /* address of the HEAD pointer of a linked list */
	struct ll *c, /* pointer to a sub-list */
	int n) /* size of sub-list (elements) */
{
	struct ll **tmp=ac;
	struct ll *cf;
	while (*tmp && (*tmp)!=c){
		tmp=&((*tmp)->next);
	}
	while (c && n--){
		free(c->value);
		cf=c;
		c=c->next;
		free(cf);
	}
	*tmp=c;
	return tmp;
}

/* traverses the list once to find the length */
int /* the length of linked list `a` */
ll_length(struct ll *a) /* linked list, `NULL` is ok */
{
	int k=0;
	while (a){
		k++;
		a=a->next;
	}
	return k;
}

/* `ll_hash()` tries to calculate a char sized hash for `n` elements
 * in linked list `a` (or, if `n<0` for all elements). The elements
 * need to be flat (no pointers to other heap memory). The xor
 * operator is used for hash calculations. This may be useful to
 * compare lists (hash collisions could happen). This works only if
 * the values are of homogenious size (which is of course not generally
 * the case withlinked lists, use ll_are_equal in such cases).
 */
char /* calculated hash (`^`)*/
ll_hash(
	struct ll *a, /* linked list */
	size_t vsize, /* byte size of values `sizeof(a->value)`*/
	int n) /* number of elements in `a` to hash */
{
	char h=0;
	char *v;
	int i;
	while (a && (n--) != 0){
		v=a->value;
		h=v[0];
		for (i=1;i<vsize;i++) h^=v[i];
		a=a->next;
	}
	return h;
}
