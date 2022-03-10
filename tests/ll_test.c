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
	int i;
	int a=-218,b=123,c=2,d=3;
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

	/* clear lists */
	head=NULL;
	list=NULL;
	tail=NULL;
	char *s1=malloc(4);
	memcpy(s1,"abc",4);
	char *s2=malloc(6);
	memcpy(s2,"abcde",6);
	ll_push(&head,s1);
	ll_push(&list,s2);
	ll_free(&head);
	ll_free(&list);
	status+=!print_result("ll_free() empties list",!head && !list);
	
	/* make two different lists, test for equality */
	ll_clear(&list);
	ll_clear(&head);
	ll_clear(&tail);
	ll_append(&list,&a);
	ll_append(&list,&b);
	ll_append(&list,&c);
	ll_append(&list,&d);
	char h[4];
	int check=1;
	for (i=0;i<4;i++) {
		h[i]=ll_hash(list,sizeof(int),i+1);
	  printf("h%i: %i\n",i,(int) h[i]);
	}
	for (i=0;i<3;i++) check=check && (h[i]!=h[i+1]);
	status+=!print_result("ll_hash works for [0,1,2,3]",check);
	
	char h2=ll_hash(list,sizeof(int),2);
	tail=ll_cut(list,2);
	status+=!print_result("ll_cut() cuts the list in the expected place",ll_hash(list,sizeof(int),-1)==h2);

	/* ll_rm() */
	ll_clear(&list);
	ll_clear(&head);
	ll_clear(&tail);
	s1=malloc(2);
	strcpy(s1,"A");
	s2=malloc(2);
	strcpy(s2,"B");
	char *s3=malloc(2);
	strcpy(s3,"C");
	char *s4=malloc(2);
	strcpy(s4,"_");

	ll_push(&list,s3);
	ll_push(&list,s2);
	ll_push(&list,s1);
	struct ll *sl=list;
	while (sl) {
		printf("[%s] ",(char*) (sl->value));
		sl=sl->next;
	}
	printf("\n");
	ll_push(ll_rm(&list,list->next,1),s4);
	sl=list;
	while (sl) {
		printf("[%s] ",(char*) (sl->value));
		sl=sl->next;
	}
	printf("\n");
	status+=!print_result("ll_rm() removes a sub-list and can be used to insert",list->next->value==s4);
	ll_free(&list);
	return status;
}
