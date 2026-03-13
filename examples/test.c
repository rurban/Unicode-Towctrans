#include <locale.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

/* versioned headers to compare unicode versions */
#if defined USE_GLOBAL
#include "../towctrans.h"
wint_t my_towlower(wint_t wc) { return (wint_t)_towcase(wc, 1); }
wint_t my_towupper(wint_t wc) { return (wint_t)_towcase(wc, 0); }
#elif defined LOW16
#include "../towctrans-low16.h"
wint_t my_towlower(wint_t wc) { return (wint_t)_towcase_low16(wc, 1); }
wint_t my_towupper(wint_t wc) { return (wint_t)_towcase_low16(wc, 0); }
#elif defined BITS
#include "../towctrans-bits.h"
wint_t my_towlower(wint_t wc) { return (wint_t)_towcase_bits(wc, 1); }
wint_t my_towupper(wint_t wc) { return (wint_t)_towcase_bits(wc, 0); }
#elif defined BSEARCH
#include "../towctrans-bsearch.h"
wint_t my_towlower(wint_t wc) { return (wint_t)_towcase_bsearch(wc, 1); }
wint_t my_towupper(wint_t wc) { return (wint_t)_towcase_bsearch(wc, 0); }
#elif defined BSEARCH_BOTH
#include "../towctrans-bsearch-both.h"
wint_t my_towlower(wint_t wc) { return (wint_t)_towcase_bsearchb(wc, 1); }
wint_t my_towupper(wint_t wc) { return (wint_t)_towcase_bsearchb(wc, 0); }
#elif defined IF_TREE
#include "../towctrans-if-tree.h"
wint_t my_towlower(wint_t wc) { return (wint_t)_towcase_iftree(wc, 1); }
wint_t my_towupper(wint_t wc) { return (wint_t)_towcase_iftree(wc, 0); }
#elif defined IF_TREE_BOTH
#include "../towctrans-if-tree-both.h"
wint_t my_towlower(wint_t wc) { return (wint_t)_towcase_iftreeb(wc, 1); }
wint_t my_towupper(wint_t wc) { return (wint_t)_towcase_iftreeb(wc, 0); }
#elif defined TABLE
#include "../towctrans-table.h"
wint_t my_towlower(wint_t wc) { return (wint_t)_towcase_table(wc, 1); }
wint_t my_towupper(wint_t wc) { return (wint_t)_towcase_table(wc, 0); }
#else
uint32_t _towcase(uint32_t wc, int lower);
wint_t my_towlower(wint_t wc) { return (wint_t)_towcase(wc, 1); }
wint_t my_towupper(wint_t wc) { return (wint_t)_towcase(wc, 0); }
#endif

int main(int argc, char **argv) {
    uint32_t wc;
    if (argc < 2) {
    err:
        fprintf(stderr, "Usage: %s HEXNUMBER [-u]\n", argv[0]);
        exit(1);
    }
#ifndef USE_GLOBAL
    setlocale(LC_ALL, "en_US.UTF-8");
#endif
    int rc = sscanf(argv[1], "%X", &wc);
    if (!rc) {
        goto err;
    }
    if (argc > 2 && strcmp(argv[2], "-u") == 0)
        printf("%s towupper(U+%04x) => U+%04x\n", argv[0], wc, my_towupper(wc));
    else
        printf("%s towlower(U+%04x) => U+%04x\n", argv[0], wc, my_towlower(wc));
    return 0;
}
