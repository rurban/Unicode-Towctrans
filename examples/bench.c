#include <locale.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <wchar.h>

extern uint32_t _towcase(uint32_t wc, int lower); /* towctrans-my */
extern wint_t my_towlower(wint_t wc);
extern wint_t my_towupper(wint_t wc);
extern wint_t my_low16_towlower(wint_t wc);
extern wint_t my_low16_towupper(wint_t wc);
extern wint_t my_bits_towlower(wint_t wc);
extern wint_t my_bits_towupper(wint_t wc);
extern wint_t my_bsearch_towlower(wint_t wc);
extern wint_t my_bsearch_towupper(wint_t wc);
extern wint_t my_bsearchb_towlower(wint_t wc);
extern wint_t my_bsearchb_towupper(wint_t wc);
extern wint_t my_table_towlower(wint_t wc);
extern wint_t my_table_towupper(wint_t wc);
extern wint_t musl_towupper(wint_t wc); /* towctrans-musl-new */
extern wint_t musl_towlower(wint_t wc);
extern wint_t old_towupper(wint_t wc); /* towctrans-musl-old */
extern wint_t old_towlower(wint_t wc);
// our workaround via locales does not work
// #define glibc_towlower towlower
// #define glibc_towupper towupper
extern wint_t glibc_towupper(wint_t wc); /* towctrans-glibc */
extern wint_t glibc_towlower(wint_t wc);

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
    int i;
    wint_t *ws, *lw, *up;
    setlocale(LC_ALL, "");
    wint_t *ps;
    long t0, t1;
    int errs = 0, perf_errs = 0;
    long t, t_my = 0;
    double perc;

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

#define BENCH(name, locasefn, upcasefn)                                        \
    t0 = TEST_TIME();                                                          \
    errs = 0;                                                                  \
    for (int j = 0; j < RETRIES; j++) {                                        \
        for (i = 0; i < SIZE; i++) {                                           \
            wint_t wc = ws[i];                                                 \
            wint_t n = locasefn(wc);                                           \
            if (n != lw[wc])                                                   \
                errs++;                                                        \
        }                                                                      \
    }                                                                          \
    for (int j = 0; j < RETRIES; j++) {                                        \
        for (i = 0; i < SIZE; i++) {                                           \
            wint_t wc = ws[i];                                                 \
            wint_t n = upcasefn(wc);                                           \
            if (n != up[wc])                                                   \
                errs++;                                                        \
        }                                                                      \
    }                                                                          \
    t1 = TEST_TIME();                                                          \
    t1 = (t1 - t0) / RETRIES;                                                  \
    perc = t_my ? t_my * 100.0 / t1 : 100;                                     \
    if (errs)                                                                  \
        printf("  %12s: %10ld [us] %.02f %%\t%u errors\n", name, t1, perc,     \
               errs / RETRIES);                                                \
    else                                                                       \
        printf("  %12s: %10ld [us] %.02f %%\n", name, t1, perc)

    BENCH("my", my_towlower, my_towupper);
    t_my = t1;
    BENCH("my_low16", my_low16_towlower, my_low16_towupper);
    BENCH("my_bits", my_bits_towlower, my_bits_towupper);
    BENCH("my_bsearch", my_bsearch_towlower, my_bsearch_towupper);
    BENCH("my_bsearchb", my_bsearchb_towlower, my_bsearchb_towupper);
    BENCH("my_table", my_table_towlower, my_table_towupper);
    BENCH("musl-new", musl_towlower, musl_towupper);
    if (perc > 800) /* musl-new uses --table (O(1) lookup), inherently faster */
        perf_errs++;
    BENCH("musl-old", old_towlower, old_towupper);
    if (perc > 300)
        perf_errs++;
    BENCH("glibc", glibc_towlower, glibc_towupper);
    if (perc > 1000) /* glibc uses table lookup, inherently faster */
        perf_errs++;
    printf("\n");

    if (perf_errs)
        printf("my is too slow\n");
    free(up);
    free(lw);
    free(ws);
    return perf_errs;
}
