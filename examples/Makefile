.PHONY: all clean test update-bench
CC = cc
DEFINES = -DHAVE_LOCALE_TR
CFLAGS_BENCH = -O2 -I. -DNDEBUG
CFLAGS = -g -Wall -Wextra $(DEFINES)
OBJ = towctrans-my.o towctrans-myexcl.o towctrans-mylow16.o towctrans-mybits.o \
      towctrans-mybsearch.o towctrans-mybsearch-both.o towctrans-myunroll.o \
      towctrans-myiftree.o towctrans-myiftree-both.o towctrans-mytable.o \
      towctrans-musl-new.o towctrans-musl-old.o towctrans-glibc.o
SRC := $(OBJ:.o=.c)
GEN = bin/gen_wctrans
TESTS = test test-low16 test-bits test-bsearch test-asan test-glibc \
	test-bsearch test-bsearch-both test-iftree test-iftree-both \
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
../UnicodeData.txt.10 :: ../$(GEN)
	cd .. && $(GEN) --with-iswalpha -v 10 --out examples/towctrans-10.h --ud UnicodeData.txt.10 --fc /dev/null
towctrans-10.h :: ../UnicodeData.txt.10
# Note: the 3 bench objects merge different UnicodeData.txt.10 together. serialize them
towctrans-low16.h :: ../UnicodeData.txt.10 Makefile
	cd .. && $(GEN) --with-iswalpha --lower16 --fn=_towcase_low16 -v 10 --out examples/$@ --ud UnicodeData.txt.10 --fc /dev/null
towctrans-bits.h :: ../UnicodeData.txt.10 Makefile
	cd .. && $(GEN) --with-iswalpha --bits 16:10:6 --fn=_towcase_bits -v 10 --out examples/$@ --ud UnicodeData.txt.10 --fc /dev/null
towctrans-excl.h :: ../UnicodeData.txt.10 Makefile
	cd .. && $(GEN) --with-iswalpha --min-excl 1000 --fn=_towcase_excl -v 10 --out examples/$@ --ud UnicodeData.txt.10 --fc /dev/null
towctrans-bsearch.h :: ../UnicodeData.txt.10 Makefile
	cd .. && $(GEN) --with-iswalpha --bsearch --fn=_towcase_bsearch -v 10 --out examples/$@ --ud UnicodeData.txt.10 --fc /dev/null
towctrans-bsearch-both.h :: ../UnicodeData.txt.10 Makefile
	cd .. && $(GEN) --with-iswalpha --bsearch-both --fn=_towcase_bsearchb -v 10 --out examples/$@ --ud UnicodeData.txt.10 --fc /dev/null
towctrans-unroll.h :: ../UnicodeData.txt.10 Makefile
	cd .. && $(GEN) --with-iswalpha --bsearch --unroll 20 --fn=_towcase_unroll -v 10 --out examples/$@ --ud UnicodeData.txt.10 --fc /dev/null
towctrans-if-tree.h :: ../UnicodeData.txt.10 Makefile
	cd .. && $(GEN) --with-iswalpha --bsearch --if-tree --fn=_towcase_iftree -v 10 --out examples/$@ --ud UnicodeData.txt.10 --fc /dev/null
towctrans-if-tree-both.h :: ../UnicodeData.txt.10 Makefile
	cd .. && $(GEN) --with-iswalpha --bsearch-both --if-tree --fn=_towcase_iftreeb -v 10 --out examples/$@ --ud UnicodeData.txt.10 --fc /dev/null
towctrans-table.h :: ../UnicodeData.txt.10 Makefile
	cd .. && $(GEN) --with-iswalpha --table --fn=_towcase_table -v 10 --out examples/$@ --ud UnicodeData.txt.10 --fc /dev/null

towctrans-my.o: towctrans-my.c towctrans-10.h
	$(CC) -c $(CFLAGS_BENCH) towctrans-my.c -o $@
towctrans-myexcl.o: towctrans-my.c towctrans-excl.h
	$(CC) -c -DEXCL $(CFLAGS_BENCH) towctrans-my.c -o $@
towctrans-mylow16.o: towctrans-my.c towctrans-low16.h
	$(CC) -c -DLOW16 $(CFLAGS_BENCH) towctrans-my.c -o $@
towctrans-mybits.o: towctrans-my.c towctrans-bits.h
	$(CC) -c -DBITS $(CFLAGS_BENCH) towctrans-my.c -o $@
towctrans-mybsearch.o: towctrans-my.c towctrans-bsearch.h
	$(CC) -c -DBSEARCH $(CFLAGS_BENCH) towctrans-my.c -o $@
towctrans-mybsearch-both.o: towctrans-my.c towctrans-bsearch-both.h
	$(CC) -c -DBSEARCH_BOTH $(CFLAGS_BENCH) towctrans-my.c -o $@
towctrans-myunroll.o: towctrans-my.c towctrans-unroll.h
	$(CC) -c -DUNROLL $(CFLAGS_BENCH) towctrans-my.c -o $@
towctrans-myiftree.o: towctrans-my.c towctrans-if-tree.h
	$(CC) -c -DIF_TREE $(CFLAGS_BENCH) towctrans-my.c -o $@
towctrans-myiftree-both.o: towctrans-my.c towctrans-if-tree-both.h
	$(CC) -c -DIF_TREE_BOTH $(CFLAGS_BENCH) towctrans-my.c -o $@
towctrans-mytable.o: towctrans-my.c towctrans-table.h
	$(CC) -c -DTABLE $(CFLAGS_BENCH) towctrans-my.c -o $@

test-iswalpha: test-iswalpha.c
	$(CC) $(CFLAGS) -I. -o $@ $^
test-glibc: test-glibc.c towctrans-glibc.o
	$(CC) $(CFLAGS) -I. -o $@ $^
../towctrans.h: ../$(GEN)
	../$(GEN) --out $@
test: test.c ../towctrans.h
	$(CC) $(CFLAGS) -DUSE_GLOBAL -UHAVE_LOCALE_TR -o $@ test.c
../towctrans-low16.h: ../$(GEN)
	../$(GEN) --lower16 --fn=_towcase_low16 --out $@ --fc /dev/null
test-low16: test.c ../towctrans-low16.h
	$(CC) $(CFLAGS) -DLOW16 -UHAVE_LOCALE_TR -o $@ test.c
../towctrans-bits.h: ../$(GEN)
	../$(GEN) --bits 16:10:6 --fn=_towcase_bits --out $@ --fc /dev/null
test-bits: test.c ../towctrans-bits.h
	$(CC) $(CFLAGS) -DBITS -UHAVE_LOCALE_TR -o $@ test.c
../towctrans-bsearch.h: ../$(GEN)
	../$(GEN) --bsearch --fn=_towcase_bsearch --out $@ --fc /dev/null
test-bsearch: test.c ../towctrans-bsearch.h
	$(CC) $(CFLAGS) -DBSEARCH -UHAVE_LOCALE_TR -o $@ test.c
../towctrans-bsearch-both.h: ../$(GEN)
	../$(GEN) --bsearch-both --fn=_towcase_bsearchb --out $@ --fc /dev/null
test-bsearch-both: test.c ../towctrans-bsearch-both.h
	$(CC) $(CFLAGS) -DBSEARCH_BOTH -UHAVE_LOCALE_TR -o $@ test.c
../towctrans-if-tree.h: ../$(GEN)
	../$(GEN) --bsearch --if-tree --fn=_towcase_iftree --out $@ --fc /dev/null
test-iftree: test.c ../towctrans-if-tree.h
	$(CC) $(CFLAGS) -DIF_TREE -UHAVE_LOCALE_TR -o $@ test.c
../towctrans-if-tree-both.h: ../$(GEN)
	../$(GEN) --bsearch-both --if-tree --fn=_towcase_iftreeb --out $@ --fc /dev/null
test-iftree-both: test.c ../towctrans-if-tree-both.h
	$(CC) $(CFLAGS) -DIF_TREE_BOTH -UHAVE_LOCALE_TR -o $@ test.c
../towctrans-table.h: ../$(GEN)
	../$(GEN) --table --fn=_towcase_table --out $@ --fc /dev/null
test-table: test.c ../towctrans-table.h
	$(CC) $(CFLAGS) -DTABLE -UHAVE_LOCALE_TR -o $@ test.c

test-%: test.c towctrans-%.c
	$(CC) $(CFLAGS) -I. -o $@ test.c towctrans-$*.c
test-asan: test.c ../towctrans.h
	$(CC) $(CFLAGS) -DUSE_GLOBAL -DASAN -fsanitize=address,undefined -I. -o $@ test.c
towctrans-5.c: ../$(GEN)
	cd .. && $(GEN) -v 7 --out examples/towctrans-5.c --fc examples/towfc-5.c --ud UnicodeData.txt.5 --cf CaseFolding.txt.5
towctrans-6.c: ../$(GEN)
	cd .. && $(GEN) -v 6 --out examples/towctrans-6.c --fc examples/towfc-6.c --ud UnicodeData.txt.6 --cf CaseFolding.txt.6
towctrans-7.c: ../$(GEN)
	cd .. && $(GEN) -v 7 --out examples/towctrans-7.c --fc examples/towfc-7.c --ud UnicodeData.txt.7 --cf CaseFolding.txt.7
towctrans-8.c: ../$(GEN)
	cd .. && $(GEN) -v 8 --out examples/towctrans-8.c --fc examples/towfc-8.c --ud UnicodeData.txt.8 --cf CaseFolding.txt.8
towctrans-9.c: ../$(GEN)
	cd .. && $(GEN) -v 9 --out examples/towctrans-9.c --fc examples/towfc-9.c --ud UnicodeData.txt.9 --cf CaseFolding.txt.9
towctrans-10.c: ../$(GEN)
	cd .. && $(GEN) -v 10 --out examples/towctrans-10.c --fc examples/towfc-10.c --ud UnicodeData.txt.10 --cf CaseFolding.txt.10
towctrans-11.c: ../$(GEN)
	cd .. && $(GEN) -v 11 --out examples/towctrans-11.c --fc examples/towfc-11.c --ud UnicodeData.txt.11 --cf CaseFolding.txt.11
towctrans-12.c: ../$(GEN)
	cd .. && $(GEN) -v 12 --out examples/towctrans-12.c --fc examples/towfc-12.c --ud UnicodeData.txt.12 --cf CaseFolding.txt.12
towctrans-13.c: ../$(GEN)
	cd .. && $(GEN) -v 13 --out examples/towctrans-13.c --fc examples/towfc-13.c --ud UnicodeData.txt.13 --cf CaseFolding.txt.13
towctrans-15.c: ../$(GEN)
	cd .. && $(GEN) -v 15 --out examples/towctrans-15.c --fc examples/towfc-15.c --ud UnicodeData.txt.15 --cf CaseFolding.txt.15
towctrans-16.c: ../$(GEN)
	cd .. && $(GEN) -v 16 --out examples/towctrans-16.c --fc examples/towfc-16.c --ud UnicodeData.txt.16 --cf CaseFolding.txt.16
towctrans-17.c: ../$(GEN)
	cd .. && $(GEN) -v 17 --out examples/towctrans-17.c --fc examples/towfc-17.c --ud UnicodeData.txt.17 --cf CaseFolding.txt.17
towctrans-18.c: ../$(GEN)
	cd .. && $(GEN) -v 18 --out examples/towctrans-18.c --fc examples/towfc-18.c --ud UnicodeData.txt.18 --cf CaseFolding.txt.18

clean:
	rm -f bench $(OBJ) $(TESTS) towctrans-[0-9][0-9]?.c towctrans-*.h \
	  ../towctrans-low16.h ../towctrans-bits.h \
	  bench-bits bench-bits.h bits-*.[ch] bits.h
