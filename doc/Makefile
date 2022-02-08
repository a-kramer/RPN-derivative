AUTHOR := "Andrei Kramer-Miehe <andrei.kramer@scilifelab.se>"
TITLE := "RPN Derivative"
CR := "(C) Andrei Kramer-Miehe"
META = --author $(AUTHOR) --copyright $(CR) --title $(TITLE)


.PHONY: all

all: ll.html symbol.html

ll.html: ../src/ll.c ./default.css
	codedoc $(META) --section "Linked Lists" --css default.css $< > $@

symbol.html: ../src/symbol.c ./default.css
	codedoc $(META) --section "Symbols in Math Expressions" --css default.css $< > $@

