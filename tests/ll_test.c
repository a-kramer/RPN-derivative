#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include "../src/ll.h"

int print_result(const char *test, int result){
	printf("test: %50s\t",test);
	if (result){
		puts("\e[32msuccess\e[0m");
	} else {
		puts("\e[31mfailure\e[0m");
	}
	return result;
}

int main(int argc, char *argv[]){
	int a=0,b=1,c=2,d=3;
	char s[5]="abcd";
	int *p;
	int status=EXIT_SUCCESS;
	struct ll *list=NULL, *head=NULL, *tail=NULL;
	ll_push(&list,&a);
	ll_push(&list,&b);

	p=ll_pop(&list);
	
  status+=!print_result("ll_push and ll_pop",*p==b);
	
	p=ll_pop(&list);
	status+=!print_result("second ll_pop retrieves te next value",*p==a);

	ll_append(&list,&c);
	ll_append(&list,&d);

	p=ll_pop(&list);
	status+=!print_result("ll_append() appends value",*p==c);

	p=ll_pop(&list);
	status+=!print_result("a subsequent ll_pop gets the right value",*p==d);

	ll_append(&head,&s[0]);
	ll_append(&head,&s[1]);
	ll_append(&tail,&s[2]);
	ll_append(&tail,&s[3]);

	/* cat two sensible lists */
	ll_cat(&head,tail);
	list=head;
	a=0;
	b=0;
	while (list){
		a+=(s[b++] == *((char*) list->value));
		list=list->next;
	}
	status+=!print_result("ll_cat() concatenates two lists",a==4);

	/* cat with an empty list as tail */
	a=ll_length(head);
	ll_cat(&head,NULL);
	status+=!print_result("ll_cat(a,NULL) does nothing",ll_length(head)==a);

	/* cat with an empty list as head */
	list=NULL;
	ll_cat(&list,head);
	status+=!print_result("a=NULL, ll_cat(&a,b) makes a==b",ll_length(list)==ll_length(head));

	/* reverse list */
	list=ll_reverse(head);
	a=0;
	b=4;
	while (list){
		a+=(s[--b] == *((char*) list->value));
		list=list->next;
	}
	status+=!print_result("ll_reverse() reverses a list",a==4);
	return status;
}
