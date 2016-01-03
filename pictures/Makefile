# Makefile to build and clean up DIMACS sources

BASEFILES=p5pgmtoasn.c
CFLAGS=-O3
TARGETS=p5pgmtoasn

all:	$(TARGETS)

clean:  $(BASEFILES)
	rm -f $(TARGETS)

p5pgmtoasn:	p5pgmtoasn.c
	cc $(CFLAGS) -o $@ p5pgmtoasn.c
