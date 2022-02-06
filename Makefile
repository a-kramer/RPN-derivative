CC = tcc
CFLAGS = -Wall -Wfatal-errors -O2 -march=native

.PHONY: all


all: derivative simplify

derivative: derivative.c ll.c symbol.c
	$(CC) $(CFLAGS) -o $@ $^

simplify: simplify.c ll.c symbol.c
	$(CC) $(CFLAGS) -o $@ $^
