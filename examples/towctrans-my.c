#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>

#ifdef HAVE_PAIRL
#define PAIRL_SZ sizeof(pairl) / sizeof(*pairl)
#else
#define PAIRL_SZ 0L
#endif
#define STATS                                                                  \
    char *s = malloc(64);                                                      \
    snprintf(s, 64, "%lu %lu %lu %lu %u",                                      \
             sizeof(casemaps) / sizeof(*casemaps),                             \
             sizeof(casemapsl) / sizeof(*casemapsl),                           \
             sizeof(pairs) / sizeof(*pairs), PAIRL_SZ, 6);                     \
    return s

#ifdef LOW16

#include "towctrans-low16.h"
wint_t my_low16_towlower(wint_t wc) { return _towcase_low16(wc, 1); }
wint_t my_low16_towupper(wint_t wc) { return _towcase_low16(wc, 0); }
#ifdef BITS_STATS
char *my_low16_stats(void) { STATS; }
#endif

#elif defined BITS

#include "towctrans-bits.h"
wint_t my_bits_towlower(wint_t wc) { return _towcase_bits(wc, 1); }
wint_t my_bits_towupper(wint_t wc) { return _towcase_bits(wc, 0); }
#ifdef BITS_STATS
char *my_bits_stats(void) { STATS; }
#endif

#elif defined EXCL

#include "towctrans-excl.h"
wint_t my_excl_towlower(wint_t wc) { return _towcase_excl(wc, 1); }
wint_t my_excl_towupper(wint_t wc) { return _towcase_excl(wc, 0); }
#ifdef BITS_STATS
char *my_excl_stats(void) { STATS; }
#endif

#elif defined BSEARCH

#include "towctrans-bsearch.h"
wint_t my_bsearch_towlower(wint_t wc) { return _towcase_bsearch(wc, 1); }
wint_t my_bsearch_towupper(wint_t wc) { return _towcase_bsearch(wc, 0); }
#ifdef BITS_STATS
char *my_bsearch_stats(void) { STATS; }
#endif

#elif defined BSEARCH_BOTH

#include "towctrans-bsearch-both.h"
wint_t my_bsearchb_towlower(wint_t wc) { return _towcase_bsearchb(wc, 1); }
wint_t my_bsearchb_towupper(wint_t wc) { return _towcase_bsearchb(wc, 0); }
#ifdef BITS_STATS
char *my_bsearchb_stats(void) { STATS; }
#endif

#elif defined UNROLL

#include "towctrans-unroll.h"
wint_t my_unroll_towlower(wint_t wc) { return _towcase_unroll(wc, 1); }
wint_t my_unroll_towupper(wint_t wc) { return _towcase_unroll(wc, 0); }
#ifdef BITS_STATS
char *my_unroll_stats(void) { STATS; }
#endif

#elif defined IF_TREE

#include "towctrans-if-tree.h"
wint_t my_iftree_towlower(wint_t wc) { return _towcase_iftree(wc, 1); }
wint_t my_iftree_towupper(wint_t wc) { return _towcase_iftree(wc, 0); }
#ifdef BITS_STATS
char *my_iftree_stats(void) { STATS; }
#endif

#elif defined TABLE

#include "towctrans-table.h"
wint_t my_table_towlower(wint_t wc) { return _towcase_table(wc, 1); }
wint_t my_table_towupper(wint_t wc) { return _towcase_table(wc, 0); }
#ifdef BITS_STATS
char *my_table_stats(void) { STATS; }
#endif

#else

#include "towctrans-10.h"
wint_t my_towlower(wint_t wc) { return _towcase(wc, 1); }
wint_t my_towupper(wint_t wc) { return _towcase(wc, 0); }
#ifdef BITS_STATS
char *my_stats(void) { STATS; }
#endif

#endif
