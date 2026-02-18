.PHONY: all clean
OBJ = towctrans-my.o towctrans-musl-new.o towctrans-musl-old.o towctrans-glibc.o
SRC := $(OBJ:.o=.c)
GEN = bin/gen_wctrans
TESTS = test-5 test-6 test-7 test-8 test-9 test-10 test-11 test-12 test-13 \
	test-15 test-16 test-17 test-18 test-glibc
all: bench $(OBJ) $(TESTS)
bench: bench.c $(OBJ) Makefile
	cc -g -O2 -I. -o $@ bench.c $(OBJ)
	./$@
	wc -c $(OBJ)
towctrans-15.h: ../$(GEN)
	../$(GEN) -v 15 --out towctrans-15.h --cf ../CaseFolding.txt.15
towctrans-my.o: towctrans-15.h

test-glibc: test-glibc.c towctrans-glibc.o
	cc -g -O2 -I. -o $@ $^
test-5: test.c towctrans-5.c
	cc -g -O2 -I. -o $@ $^
test-6: test.c towctrans-6.c
	cc -g -O2 -I. -o $@ $^
test-7: test.c towctrans-7.c
	cc -g -O2 -I. -o $@ $^
test-8: test.c towctrans-8.c
	cc -g -O2 -I. -o $@ $^
test-9: test.c towctrans-9.c
	cc -g -O2 -I. -o $@ $^
test-10: test.c towctrans-10.c
	cc -g -O2 -I. -o $@ $^
test-11: test.c towctrans-11.c
	cc -g -O2 -I. -o $@ $^
test-12: test.c towctrans-12.c
	cc -g -O2 -I. -o $@ $^
test-13: test.c towctrans-13.c
	cc -g -O2 -I. -o $@ $^
test-15: test.c towctrans-15.c
	cc -g -O2 -I. -o $@ $^
test-16: test.c towctrans-16.c
	cc -g -O2 -I. -o $@ $^
test-17: test.c towctrans-17.c
	cc -g -O2 -I. -o $@ $^
test-18: test.c towctrans-18.c
	cc -g -O2 -I. -o $@ $^
towctrans-5.c: ../$(GEN)
	cd .. && $(GEN) -v 7 --out examples/towctrans-5.c --cf CaseFolding.txt.5
towctrans-6.c: ../$(GEN)
	cd .. && $(GEN) -v 6 --out examples/towctrans-6.c --cf CaseFolding.txt.6
towctrans-7.c: ../$(GEN)
	cd .. && $(GEN) -v 7 --out examples/towctrans-7.c --cf CaseFolding.txt.7
towctrans-8.c: ../$(GEN)
	cd .. && $(GEN) -v 8 --out examples/towctrans-8.c --cf CaseFolding.txt.8
towctrans-9.c: ../$(GEN)
	cd .. && $(GEN) -v 9 --out examples/towctrans-9.c --cf CaseFolding.txt.9
towctrans-10.c: ../$(GEN)
	cd .. && $(GEN) -v 10 --out examples/towctrans-10.c --cf CaseFolding.txt.10
towctrans-11.c: ../$(GEN)
	cd .. && $(GEN) -v 11 --out examples/towctrans-11.c --cf CaseFolding.txt.11
towctrans-12.c: ../$(GEN)
	cd .. && $(GEN) -v 12 --out examples/towctrans-12.c --cf CaseFolding.txt.12
towctrans-13.c: ../$(GEN)
	cd .. && $(GEN) -v 13 --out examples/towctrans-13.c --cf CaseFolding.txt.13
towctrans-15.c: ../$(GEN)
	cd .. && $(GEN) -v 15 --out examples/towctrans-15.c --cf CaseFolding.txt.15
towctrans-16.c: ../$(GEN)
	cd .. && $(GEN) -v 16 --out examples/towctrans-16.c --cf CaseFolding.txt.16
towctrans-17.c: ../$(GEN)
	cd .. && $(GEN) -v 17 --out examples/towctrans-17.c --cf CaseFolding.txt.17
towctrans-18.c: ../$(GEN)
	cd .. && $(GEN) -v 18 --out examples/towctrans-18.c --cf CaseFolding.txt.18

%.o: %.c
	cc -c -g -O2 -I. $<
clean:
	rm -f bench $(OBJ) $(TESTS) towctrans-*.c
