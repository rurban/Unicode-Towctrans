#include <locale.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <wchar.h>

extern uint32_t _towcase(uint32_t wc, int lower); /* towctrans-my */

#define CAT(a, b) a##b
#define PASTE(a, b) CAT(a, b)
#define JOIN(prefix, name) PASTE(prefix, name)
#define DECL_BENCH(name, fn)                                                   \
    extern wint_t JOIN(fn, _towlower)(wint_t wc);                              \
    extern wint_t JOIN(fn, _towupper)(wint_t wc)

DECL_BENCH("my", my);
DECL_BENCH("my_excl", my_excl);
DECL_BENCH("my_low16", my_low16);
DECL_BENCH("my_bits", my_bits);
DECL_BENCH("my_bsearch", my_bsearch);
DECL_BENCH("my_bsearchb", my_bsearchb);
DECL_BENCH("my_unroll", my_unroll);
DECL_BENCH("my_iftree", my_iftree);
DECL_BENCH("my_iftreeb", my_iftreeb);
DECL_BENCH("my_table", my_table);
DECL_BENCH("musl-new", musl);
DECL_BENCH("musl-old", old);
DECL_BENCH("glibc", glibc);

#define MAX_UNI 0x1ffff
#define SIZE 10000
#define RETRIES 10
#define SZ(a) sizeof(a) / sizeof(*a)

#ifndef _WIN32
static inline long TEST_TIME(void) {
    struct timeval now;
    gettimeofday(&now, NULL);
    return 1000000L * now.tv_sec + now.tv_usec;
}
#else
static inline long TEST_TIME(void) { return GetTickCount(); }
#endif

int main(void) {
    int i, j;
    wint_t *ws, *lw, *up;
    wint_t *ps;
    long t0, t1;
    int errs = 0, perf_errs = 0;
    long t, t_my = 0, t_my_table;
    double perc;

    setlocale(LC_ALL, "");
    srandom(0U);
    /* prep */
    ws = malloc(SIZE * sizeof(wint_t));
    lw = malloc(MAX_UNI * sizeof(wint_t));
    up = malloc(MAX_UNI * sizeof(wint_t));
    for (i = 0; i < SIZE; i++) {
        wint_t wc = (wint_t)(random() % 0x1ffff);
        ws[i] = wc;
    }
    /* warmup */
    for (i = 0; i < MAX_UNI; i++) {
        lw[i] = my_towlower(i);
        up[i] = my_towupper(i);
    }
#define CAT(a, b) a##b
#define PASTE(a, b) CAT(a, b)
#define JOIN(prefix, name) PASTE(prefix, name)
#define BENCH(name, fn)                                                        \
    t0 = TEST_TIME();                                                          \
    errs = 0;                                                                  \
    for (j = 0; j < RETRIES; j++) {                                            \
        for (i = 0; i < SIZE; i++) {                                           \
            wint_t wc = ws[i];                                                 \
            wint_t n = JOIN(fn, _towlower)(wc);                                \
            if (n != lw[wc])                                                   \
                errs++;                                                        \
        }                                                                      \
    }                                                                          \
    for (j = 0; j < RETRIES; j++) {                                            \
        for (i = 0; i < SIZE; i++) {                                           \
            wint_t wc = ws[i];                                                 \
            wint_t n = JOIN(fn, _towupper)(wc);                                \
            if (n != up[wc])                                                   \
                errs++;                                                        \
        }                                                                      \
    }                                                                          \
    t1 = TEST_TIME();                                                          \
    t1 = (t1 - t0) / RETRIES;                                                  \
    perc = t_my ? t_my * 100.0 / t1 : 100;                                     \
    if (errs)                                                                  \
        printf("  %12s: %10ld [us] %7.02f %%\t%u errors\n", name, t1, perc,    \
               errs / RETRIES);                                                \
    else                                                                       \
        printf("  %12s: %10ld [us] %7.02f %%\n", name, t1, perc)

    BENCH("my", my);
    t_my = t1;
    BENCH("my_excl", my_excl);
    BENCH("my_low16", my_low16);
    BENCH("my_bits", my_bits);
    BENCH("my_bsearch", my_bsearch);
    BENCH("my_bsearchb", my_bsearchb);
    BENCH("my_unroll", my_unroll);
    BENCH("my_iftree", my_iftree);
    BENCH("my_iftreeb", my_iftreeb);
    BENCH("my_table", my_table);
    t_my_table = t1;
    BENCH("musl-new", musl);
    /* compare my_table against musl-new (both O(1) table lookup) */
    if (t_my_table > t1 * 4)
        perf_errs++;
    BENCH("musl-old", old);
    /* compare my against musl-old (both linear search) */
    if (t_my > t1 * 3)
        perf_errs++;
    BENCH("glibc", glibc);
    /* compare my_table against glibc (both O(1) table lookup) */
    if (t_my_table > t1 * 4)
        perf_errs++;
    printf("\n");

    if (perf_errs)
        printf("too slow\n");
    free(up);
    free(lw);
    free(ws);
    return perf_errs;
}
