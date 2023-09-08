.PHONY: all clean

MODEL = DemoModel

all: $(MODEL)_gvf.c


$(MODEL)_gvf.c: $(MODEL).tar.gz
	../sh/ode.sh $< > $@

$(MODEL).tar.gz: *.txt
	tar czf $@ $^

$(MODEL).zip: *.txt
	zip $@ $^

clean:
	rm $(MODEL).tar.gz $(MODEL).zip
