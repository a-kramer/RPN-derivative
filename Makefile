CC = gcc
CFLAGS = -Wall -Wfatal-errors -O2 -march=native

.PHONY: all test


all: bin/derivative bin/simplify test

bin/derivative: src/derivative.c src/ll.c src/symbol.c
	$(CC) $(CFLAGS) -o $@ $^

bin/simplify: src/simplify.c src/ll.c src/symbol.c
	$(CC) $(CFLAGS) -o $@ $^

tests/ll_test: tests/ll_test.c
	$(CC) $(CFLAGS) -o $@ $^

test: bin/derivative bin/simplify tests/ll_test
	./tests/test.sh
