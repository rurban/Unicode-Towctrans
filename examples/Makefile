.PHONY: all clean
CC = cc
DEFINES = -DHAVE_LOCALE_TR
CFLAGS_BENCH = -O2 -Wall -Wextra
CFLAGS = -g -O2 -Wall -Wextra $(DEFINES)
OBJ = towctrans-my.o towctrans-musl-new.o towctrans-musl-old.o towctrans-glibc.o
SRC := $(OBJ:.o=.c)
GEN = bin/gen_wctrans
TESTS = test-5 test-6 test-7 test-8 test-9 test-10 test-11 test-12 test-13 \
	test-15 test-16 test-17 test-18 test-glibc test-iswalpha
all: bench $(OBJ) $(TESTS)
bench: bench.c $(OBJ) Makefile
	$(CC) $(CFLAGS_BENCH) -I. -o $@ bench.c $(OBJ)
	./$@
	wc -c $(OBJ)
.c.o:
	$(CC) $(CFLAGS_BENCH) -I. $<
towctrans-15.h: ../$(GEN)
	../$(GEN) --with-iswalpha -v 15 --out towctrans-15.h --cf ../CaseFolding.txt.15
towctrans-my.o: towctrans-15.h

test-iswalpha: test-iswalpha.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-glibc: test-glibc.c towctrans-glibc.o
	$(CC) $(CFLAGS) -I. -o $@ $^
test-5: test.c towctrans-5.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-6: test.c towctrans-6.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-7: test.c towctrans-7.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-8: test.c towctrans-8.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-9: test.c towctrans-9.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-10: test.c towctrans-10.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-11: test.c towctrans-11.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-12: test.c towctrans-12.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-13: test.c towctrans-13.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-15: test.c towctrans-15.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-16: test.c towctrans-16.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-17: test.c towctrans-17.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-18: test.c towctrans-18.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-asan: test.c towctrans-18.c
	$(CC) $(CFLAGS) -DASAN -fsanitize=address,undefined -I. -o $@ $^
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

clean:
	rm -f bench $(OBJ) $(TESTS) towctrans-[0-9][0-9]?.c
