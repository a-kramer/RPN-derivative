#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "ll.h"

int main(int argc, char *argv[]){
	int a=0,b=1,c=2,d=3;
	int *p;
	int status=EXIT_SUCCESS;
	struct ll *list=NULL, *head=NULL, *tail=NULL;
	ll_push(&list,&a);
	ll_push(&list,&b);

	p=ll_pop(&list);
	printf("[%s] (%i == %i) : %s\n",__func__,*p,b,(*p==b)?"true":"false");
	if (*p!=b) status++;
	
	p=ll_pop(&list);
	printf("[%s] (%i == %i) : %s\n",__func__,*p,a,(*p==a)?"true":"false");
	if (*p!=a) status++;

	ll_append(&list,&c);
	ll_append(&list,&d);

	p=ll_pop(&list);
	printf("[%s] (%i == %i) : %s\n",__func__,*p,c,(*p==c)?"true":"false");
	if (*p!=c) status++;

	p=ll_pop(&list);
	printf("[%s] (%i == %i) : %s\n",__func__,*p,d,(*p==d)?"true":"false");
	if (*p!=d) status++;

	ll_append(&head,&a);
	ll_append(&head,&b);
	ll_append(&tail,&c);
	ll_append(&tail,&d);

	/* cat two sensible lists */
	ll_cat(&head,tail);
	list=head;
	while (list){
		printf("%i ",*((int*) list->value));
		list=list->next;
	}
	printf("\n");

	/* cat with an empty list as tail */
	ll_cat(&head,list);
	list=head;
	while (list){
		printf("%i ",*((int*) list->value));
		list=list->next;
	}
	printf("\n");

	/* cat with an empty list as head */
	ll_cat(&list,head);
	while (list){
		printf("%i ",*((int*) list->value));
		list=list->next;
	}
	printf("\n");

	/* reverse list */
	list=ll_reverse(head);
	printf("[%s] list=ll_reverse(head);\nlist: ",__func__);
	while (list){
		printf("%i ",*((int*) list->value));
		list=list->next;
	}
	printf("\n");
	printf("head: ");
	list=head;
	while (list){
		printf("%i ",*((int*) list->value));
		list=list->next;
	}
	printf("\n");

	return status;
}
