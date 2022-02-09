CC = tcc
CFLAGS = -Wall -Wfatal-errors -O2 -march=native

.PHONY: all test clean


all: bin/derivative bin/simplify tests/ll_test


bin/derivative: src/derivative.c src/ll.c src/symbol.c src/rpn.c
	$(CC) $(CFLAGS) -o $@ $^

bin/simplify: src/simplify.c src/ll.c src/symbol.c src/rpn.c
	$(CC) $(CFLAGS) -o $@ $^

tests/ll_test: tests/ll_test.c src/ll.c
	$(CC) $(CFLAGS) -o $@ $^

test: bin/derivative bin/simplify tests/ll_test
	./tests/test.sh

clean:
	rm bin/derivative bin/simplify tests/ll_test
