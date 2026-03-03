.PHONY: all clean update-bench
CC = cc
DEFINES = -DHAVE_LOCALE_TR
CFLAGS_BENCH = -O2 -I. -DNDEBUG
CFLAGS = -g -Wall -Wextra $(DEFINES)
OBJ = towctrans-my.o towctrans-mylow16.o towctrans-mybits.o towctrans-mybsearch.o \
      towctrans-mybsearch-both.o towctrans-mytable.o \
      towctrans-musl-new.o towctrans-musl-old.o towctrans-glibc.o
SRC := $(OBJ:.o=.c)
GEN = bin/gen_wctrans
TESTS = test test-low16 test-bits test-bsearch test-asan test-glibc \
        test-iswalpha \
        test-5 test-6 test-7 test-8 test-9 test-10 test-11 test-12 test-13 \
	test-15 test-16 test-17 test-18
all: bench $(OBJ) $(TESTS)
bench: bench.c $(OBJ) Makefile
	$(CC) $(CFLAGS_BENCH) -o $@ bench.c $(OBJ)
	./$@
	wc -c $(OBJ)
update-bench:
	$(MAKE) -B bench > bench.log
	./update-bench.pl ../$(GEN) bench.log #&& rm bench.log
	../$(GEN)
.c.o:
	$(CC) -c $(CFLAGS_BENCH) $<
../UnicodeData.txt.10 towctrans-10.h :: ../$(GEN)
	cd .. && $(GEN) --with-iswalpha -v 10 --out examples/towctrans-10.h --ud UnicodeData.txt.10
towctrans-10.h :: ../UnicodeData.txt.10
# Note: the 3 bench objects merge different UnicodeData.txt.10 together. serialize them
towctrans-low16.h :: ../UnicodeData.txt.10
	cd .. && $(GEN) --with-iswalpha --lower16 --fn=_towcase_low16 -v 10 --out examples/$@ --ud UnicodeData.txt.10
towctrans-bits.h :: ../UnicodeData.txt.10
	cd .. && $(GEN) --with-iswalpha --bits 16:10:6 --fn=_towcase_bits -v 10 --out examples/$@ --ud UnicodeData.txt.10
towctrans-bsearch.h :: ../UnicodeData.txt.10
	cd .. && $(GEN) --with-iswalpha --bsearch --fn=_towcase_bsearch -v 10 --out examples/$@ --ud UnicodeData.txt.10
towctrans-bsearch-both.h :: ../UnicodeData.txt.10
	cd .. && $(GEN) --with-iswalpha --bsearch-both --fn=_towcase_bsearchb -v 10 --out examples/$@ --ud UnicodeData.txt.10
towctrans-table.h :: ../UnicodeData.txt.10
	cd .. && $(GEN) --with-iswalpha --table --fn=_towcase_table -v 10 --out examples/$@ --ud UnicodeData.txt.10

towctrans-my.o: towctrans-my.c towctrans-10.h
	$(CC) -c $(CFLAGS_BENCH) $< -o $@
towctrans-mylow16.o: towctrans-my.c towctrans-low16.h
	$(CC) -c -DLOW16 $(CFLAGS_BENCH) $< -o $@
towctrans-mybits.o: towctrans-my.c towctrans-bits.h
	$(CC) -c -DBITS $(CFLAGS_BENCH) $< -o $@
towctrans-mybsearch.o: towctrans-my.c towctrans-bsearch.h
	$(CC) -c -DBSEARCH $(CFLAGS_BENCH) $< -o $@
towctrans-mybsearch-both.o: towctrans-my.c towctrans-bsearch-both.h
	$(CC) -c -DBSEARCH_BOTH $(CFLAGS_BENCH) $< -o $@
towctrans-mytable.o: towctrans-my.c towctrans-table.h
	$(CC) -c -DTABLE $(CFLAGS_BENCH) $< -o $@

test-iswalpha: test-iswalpha.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-glibc: test-glibc.c towctrans-glibc.o
	$(CC) $(CFLAGS) -I. -o $@ $^
test: test.c ../towctrans.h
	$(CC) $(CFLAGS) -DUSE_GLOBAL -UHAVE_LOCALE_TR -o $@ test.c
../towctrans-low16.h: ../$(GEN)
	../$(GEN) --lower16 --fn=_towcase_low16 -v 15 --out $@ --ud ../UnicodeData.txt.15
test-low16: test.c ../towctrans-low16.h
	$(CC) $(CFLAGS) -DLOW16 -UHAVE_LOCALE_TR -o $@ test.c
../towctrans-bits.h: ../$(GEN)
	../$(GEN) --bits 16:10:6 --fn=_towcase_bits -v 15 --out $@ --ud ../UnicodeData.txt.15
test-bits: test.c ../towctrans-bits.h
	$(CC) $(CFLAGS) -DBITS -UHAVE_LOCALE_TR -o $@ test.c
../towctrans-bsearch.h: ../$(GEN)
	../$(GEN) --bsearch --fn=_towcase_bsearch -v 15 --out $@ --ud ../UnicodeData.txt.15
../towctrans-bsearch-both.h: ../$(GEN)
	../$(GEN) --bsearch-both --fn=_towcase_bsearchb -v 15 --out $@ --ud ../UnicodeData.txt.15
../towctrans-table.h: ../$(GEN)
	../$(GEN) --table --fn=_towcase_table -v 15 --out $@ --ud ../UnicodeData.txt.15
test-bsearch: test.c ../towctrans-bsearch.h
	$(CC) $(CFLAGS) -DBSEARCH -UHAVE_LOCALE_TR -o $@ test.c
test-bsearch-both: test.c ../towctrans-bsearch-both.h
	$(CC) $(CFLAGS) -DBSEARCH_BOTH -UHAVE_LOCALE_TR -o $@ test.c
test-table: test.c ../towctrans-table.h
	$(CC) $(CFLAGS) -DTABLE -UHAVE_LOCALE_TR -o $@ test.c
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
	cd .. && $(GEN) -v 7 --out examples/towctrans-5.c --ud UnicodeData.txt.5
towctrans-6.c: ../$(GEN)
	cd .. && $(GEN) -v 6 --out examples/towctrans-6.c --ud UnicodeData.txt.6
towctrans-7.c: ../$(GEN)
	cd .. && $(GEN) -v 7 --out examples/towctrans-7.c --ud UnicodeData.txt.7
towctrans-8.c: ../$(GEN)
	cd .. && $(GEN) -v 8 --out examples/towctrans-8.c --ud UnicodeData.txt.8
towctrans-9.c: ../$(GEN)
	cd .. && $(GEN) -v 9 --out examples/towctrans-9.c --ud UnicodeData.txt.9
towctrans-10.c: ../$(GEN)
	cd .. && $(GEN) -v 10 --out examples/towctrans-10.c --ud UnicodeData.txt.10
towctrans-11.c: ../$(GEN)
	cd .. && $(GEN) -v 11 --out examples/towctrans-11.c --ud UnicodeData.txt.11
towctrans-12.c: ../$(GEN)
	cd .. && $(GEN) -v 12 --out examples/towctrans-12.c --ud UnicodeData.txt.12
towctrans-13.c: ../$(GEN)
	cd .. && $(GEN) -v 13 --out examples/towctrans-13.c --ud UnicodeData.txt.13
towctrans-15.c: ../$(GEN)
	cd .. && $(GEN) -v 15 --out examples/towctrans-15.c --ud UnicodeData.txt.15
towctrans-16.c: ../$(GEN)
	cd .. && $(GEN) -v 16 --out examples/towctrans-16.c --ud UnicodeData.txt.16
towctrans-17.c: ../$(GEN)
	cd .. && $(GEN) -v 17 --out examples/towctrans-17.c --ud UnicodeData.txt.17
towctrans-18.c: ../$(GEN)
	cd .. && $(GEN) -v 18 --out examples/towctrans-18.c --ud UnicodeData.txt.18

clean:
	rm -f bench $(OBJ) $(TESTS) towctrans-[0-9][0-9]?.c towctrans-*.h \
	  ../towctrans-low16.h ../towctrans-bits.h \
	  bench-bits bench-bits.h bits-*.[ch] bits.h
