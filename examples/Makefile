.PHONY: all clean

MODEL = DemoModel

all: $(MODEL)_gvf.c


$(MODEL)_gvf.c: ODE.txt ParNames.txt ReactionFlux.txt Variables.txt ExpressionFormula.txt Function.txt
	./ode.sh > $@

clean:
	rm *.rm Jac_[0-9]*.txt Flux_[a-zA-Z0-9_]*.txt
