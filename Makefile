CC = cc
CFLAGS = -Wall -Wfatal-errors -O2 -march=native
PREFIX = /usr/local/bin
MANPREFIX = /usr/local/man/man1

.PHONY: all test clean install manpages


all: bin/derivative bin/simplify bin/to_rpn tests/ll_test bin/to_infix

bin/to_infix: src/rpn_to_infix.c src/ll.c src/symbol.c src/rpn.c
	$(CC) $(CFLAGS) -o $@ $^

bin/to_rpn: src/to_rpn.c src/ll.c src/symbol.c src/rpn.c
	$(CC) $(CFLAGS) -o $@ $^

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

install: bin/derivative bin/simplify bin/to_rpn bin/to_infix man/*.1
	install bin/* $(PREFIX) && \
  ([ -d $(MANPREFIX) ] && echo "man pages: $(MANPREFIX)" ||  mkdir $(MANPREFIX)) && \
  install man/*.1 $(MANPREFIX)  && gzip -f $(MANPREFIX)/*.1
