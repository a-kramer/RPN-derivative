#include "ll.h"
#include <assert.h>

void ll_append(struct ll **L, void *e){
	struct ll **a=L;
	struct ll *n=malloc(sizeof(struct ll));
	n->next=NULL;
	n->value=e;
	while (*a){
		a=&((*a)->next);
	}
	*a=n;
}

void* ll_remove(struct ll **L){
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


void ll_push(struct ll **L, void *e){
	struct ll *n=malloc(sizeof(struct ll));
	n->next=*L;
	n->value=e;
	*L=n;
}

void* ll_pop(struct ll **L){
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

void ll_cat(struct ll **a, struct ll *b){
	struct ll **c=a;
	while (*c){
		c=&((*c)->next);
	}
	*c=b;
}

struct ll* ll_reverse(struct ll *a){
	struct ll *c=NULL;
	void *v;
	while (a){
		v=ll_pop(&a);
		ll_push(&c,v);
	}
	return c;
}


void ll_free(struct ll **a){
	struct ll *t;
	while(*a){
		t=*a;
		*a=(*a)->next;
		free(t);
	}
}

int ll_are_equal(struct ll *a, struct ll *b,  size_t value_size)
{
	int E=(a==b);
	while (a && b){
		E=E && (memcmp(a->value,b->value,value_size)==0);
		a=a->next;
		b=b->next;
	}
	return (E && a==b);
}
