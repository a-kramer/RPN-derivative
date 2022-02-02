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
