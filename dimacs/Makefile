# Makefile to build and clean up DIMACS sources

BASEFILES=assign.c dcube.c universal.c
CFLAGS=-O4
TARGETS=assign dcube universal

all:	$(TARGETS)

clean:  $(BASEFILES)
	rm -f $(TARGETS)

assign:	assign.c
	cc $(CFLAGS) -o $@ assign.c

dcube:	dcube.c
	cc $(CFLAGS) -o $@ dcube.c

universal:	universal.c
	cc $(CFLAGS) -o $@ universal.c
