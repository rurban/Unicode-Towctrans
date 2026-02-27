#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <wchar.h>

#include "bits.h"

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
    // wint_t *ps;
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

#define BENCH(name, prefix)                                                    \
    t0 = TEST_TIME();                                                          \
    errs = 0;                                                                  \
    for (int j = 0; j < RETRIES; j++) {                                        \
        for (i = 0; i < SIZE; i++) {                                           \
            wint_t wc = ws[i];                                                 \
            wint_t n = prefix##_towlower(wc);                                  \
            if (n != lw[wc])                                                   \
                errs++;                                                        \
        }                                                                      \
    }                                                                          \
    for (int j = 0; j < RETRIES; j++) {                                        \
        for (i = 0; i < SIZE; i++) {                                           \
            wint_t wc = ws[i];                                                 \
            wint_t n = prefix##_towupper(wc);                                  \
            if (n != up[wc])                                                   \
                errs++;                                                        \
        }                                                                      \
    }                                                                          \
    t1 = TEST_TIME();                                                          \
    t1 = (t1 - t0) / RETRIES;                                                  \
    perc = t_my ? t_my * 100.0 / t1 : 100;                                     \
    printf("  %10s: %10ld [us] %3.1f %% ", name, t1, perc);                    \
    {                                                                          \
        char *s = prefix##_stats();                                            \
        printf("\t%s", s);                                                     \
        free(s);                                                               \
    }                                                                          \
    if (errs)                                                                  \
        printf("\t%u errors ", errs / RETRIES);                                \
    printf("\n")

    BENCH("16:8:8", my);
    t_my = t1;
    BENCH("16:16:8", my_low16);
    BENCH("16:10:8", my_bits);

#include "bench-bits.h"

    printf("\n");

    if (perf_errs)
        printf("my is too slow\n");
    free(up);
    free(lw);
    free(ws);
    return perf_errs;
}
