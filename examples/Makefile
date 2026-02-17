OBJ = towctrans-my.o towctrans-musl-new.o towctrans-musl-old.o
.PHONY: all clean
all: bench $(OBJ)
bench: bench.c $(OBJ) ../towctrans-15.h Makefile
	cc -g -O2 -I.. -I. -o $@ bench.c towctrans-musl-new.c towctrans-musl-old.c
	./$@
	wc -c $(OBJ)
../towctrans-15.h: ../towctrans.h
	cd .. && bin/gen_towctrans -v 15 --out towctrans-15.h --cf CaseFolding.txt.15
towctrans-musl-new.o: towctrans-musl-new.c
	cc -c -O2 -I.. -I. -o $@ $<
towctrans-musl-old.o: towctrans-musl-old.c
	cc -c -O2 -I.. -I. -o $@ $<
towctrans-my.o: towctrans-my.c
	cc -c -O2 -I.. -I. -o $@ $<
clean:
	rm -f bench $(OBJ)
