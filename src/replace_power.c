#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#define WORD(c) (((c) >= 'a' && (c) <= 'z') || ((c) >= 'A' && (c) <= 'Z') || ((c) >= '0' && (c) <= '9') || ((c) == '_'))

#ifndef _GNU_SOURCE
void *mempcpy(void *dest, const void *src, size_t len){
  return memcpy (dest, src, len) + len;
}
#endif

const char *pow_str[]={"gsl_pow_","gsl_pow_int","pow",NULL};
enum pow_type {small_integer_power, integer_power, double_power};

int word(char c){
	if (c >= 'a' && c <= 'z') return 1;
	if (c >= 'A' && c <= 'Z') return 1;
	if (c >= '0' && c <= '9') return 1;
	if (c=='_' || c=='.') return 1;
	return 0;
}

int find(const char *s, char c){
	int i;
	for (i=0;i<strlen(s);i++){
		if (s[i]==c) break;
	}
	return i;
}

/* remove whitespace and one layer of parenthese*/
void tighten(char **left, char **right){
	while (**left==' ') (*left)++;
	while (**right==' ') (*right)--;
	if (**left=='(' && **right==')'){
		(*left)++;
		(*right)--;
	}
}

/* does this: (var1 + (var2 / var3))         */
/*            ^boundary            ^start    */
/* either in forward or backward direction   */
char* find_boundary(const char* src, char *start, int direction){
	char *ptr=start;
	if (direction==0) return ptr;
	int n=0; /* parnethesis counter */
	do {
		switch(*ptr){
		case ')': n-=direction; break;
		case '(': n+=direction; break;
		}
		ptr+=direction;
	} while (ptr>=src && (word(*ptr) || n>0));
	return ptr-direction;
}

int count(const char *s, char c){
	const char *p=s;
	int z=0;
	while (*p){
		z+=(c==*p);
		p++;
	}
	return z;
}

/* check that all n characters are numerical digits [0-9] */
int digit(const char *str, size_t n){
	int i;
	for (i=0;i<n;i++){
		if (str[i]<'0' || str[i]>'9') return 0;
	}
	return 1;
}

/* replaces a^b with pow(a,b) */
void replace(char *buffer, const char *src){
	char *ptr;
	char *out;
	char *b_open, *b_close, *e_open, *e_close;
	/* b - base; e - exponent; */
	const char *ps;
	size_t n;
	enum pow_type t=double_power;
	char *hat=strchr(src,'^');
	if (hat){
		ptr = hat-1;
		while (*ptr==' ') ptr--;
		/* find base: */
		b_close= ptr;
		b_open = find_boundary(src,ptr,-1);
		/* copy initial part, if any, to output buffer */
		*(out=(char*) mempcpy(buffer,src,b_open-src))='\0';
		/* find the exponent */
		ptr  = hat+1;
		while (*ptr==' ') ptr++;
		e_open = ptr;
		e_close= find_boundary(src,ptr,+1);
		ptr=e_close+1;
		tighten(&b_open,&b_close);
		tighten(&e_open,&e_close);
		/* add power function to buffer: */
		if (e_open==e_close && digit(e_open,1)){
			t=small_integer_power;
		} else if (digit(e_open,1+(e_close-e_open))) {
			t=integer_power;
		}
		ps=pow_str[t];
		n=strlen(ps);
		switch (t){
		case small_integer_power:
			*(out=(char*) mempcpy(out,ps,n))='\0';
			*(out=(char*) mempcpy(out,e_open,1+(e_close-e_open)))='\0';
			*(out=(char*) mempcpy(out,"(",1))='\0';
			*(out=(char*) mempcpy(out,b_open,1+(b_close-b_open)))='\0';
			*(out=(char*) mempcpy(out,")",1))='\0';
			break;
		default:
			*(out=(char*) mempcpy(out,ps,n))='\0';
			*(out=(char*) mempcpy(out,"(",1))='\0';
			*(out=(char*) mempcpy(out,b_open,1+(b_close-b_open)))='\0';
			*(out=(char*) mempcpy(out,", ",2))='\0';
			*(out=(char*) mempcpy(out,e_open,1+(e_close-e_open)))='\0';
			*(out=(char*) mempcpy(out,")",1))='\0';
		}
		*(out=(char*) mempcpy(out,ptr,strlen(ptr)))='\0';
	}
}

/* replaces a^b with exp(b*log(a)) */
void replaceExpLog(char *buffer, const char *src){
	char *ptr;
	char *out;
	char *b_open, *b_close, *e_open, *e_close;
	/* b - base; e - exponent; */
	char *hat=strchr(src,'^');
	if (hat){
		ptr = hat-1;
		while (*ptr==' ') ptr--;
		/* find base: */
		b_close= ptr;
		b_open = find_boundary(src,ptr,-1);
		/* copy initial part, if any, to output buffer */
		*(out=(char*) mempcpy(buffer,src,b_open-src))='\0';
		/* find the exponent */
		ptr  = hat+1;
		while (*ptr==' ') ptr++;
		e_open = ptr;
		e_close= find_boundary(src,ptr,+1);
		ptr=e_close+1;
		tighten(&b_open,&b_close);
		/* add power function to buffer: */
		*(out=(char*) mempcpy(out,"exp",3))='\0';
		*(out=(char*) mempcpy(out,"(",1))='\0';
		*(out=(char*) mempcpy(out,e_open,1+(e_close-e_open)))='\0';
		*(out=(char*) mempcpy(out,"*log(",5))='\0';
		*(out=(char*) mempcpy(out,b_open,1+(b_close-b_open)))='\0';
		*(out=(char*) mempcpy(out,"))",2))='\0';
		*(out=(char*) mempcpy(out,ptr,strlen(ptr)))='\0';
	}
}

int main(int argc, char *argv[]){
	/*                       "exp(·*log(·))" is smaller than gsl_pow_int(·,·)*/
	const char max_pow_str[]="gsl_pow_int(,)"; /* maximum possible extra content per caret (^) in input */
	size_t max_l=strlen(max_pow_str);
	int j;
	enum fmt {POW,EXP};
	enum fmt f=POW;
	for (j=1;j<argc;j++){
		if (strcmp(argv[j],"-e")==0) f=EXP;
		else if (strcmp(argv[j],"-p")==0) f=POW;
		else fprintf(stderr,"unknown option: %s\n",argv[j]);
	}
	//assert(str);
	int i,c;
	ssize_t m;
	size_t n=128;
	char *str=malloc(n);
	char *buffer,*src;
	while (!feof(stdin) && (m=getline(&str,&n,stdin))>=0){
		c=count(str,'^');
		buffer = malloc(1+strlen(str)+max_l*c);
		src    = malloc(1+strlen(str)+max_l*c);
		strcpy(buffer,str);
		strcpy(src,str);
		for (i=0;i<c;i++){
			switch(f){
			case EXP: replaceExpLog(buffer,src); break;
			case POW: replace(buffer,src); break;
			}
			strcpy(src,buffer);
		}
		char *src=malloc(1+strlen(str)+max_l*c);
		printf("%s",buffer);
		free(buffer);
		free(src);
	}
	return EXIT_SUCCESS;
}
