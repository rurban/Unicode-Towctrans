#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <wchar.h>

extern uint32_t _towcase(uint32_t wc, int lower); /* towctrans-my */
extern wint_t my_towlower(wint_t wc);
extern wint_t my_towupper(wint_t wc);
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
#define SIZE 1000000
#define RETRIES 10000
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
  wint_t *ps;
  long t0, t1;
  int errs;
  srandom(0U);
  /* prep */
  ws = malloc(SIZE * sizeof(wint_t));
  lw = malloc(MAX_UNI * sizeof(wint_t));
  up = malloc(MAX_UNI * sizeof(wint_t));
  for (i = 0; i < SZ(ws); i++) {
    wint_t wc = (wint_t)(random() % 0x1ffff);
    ws[i] = wc;
  }
  /* warmup */
  for (i = 0; i < MAX_UNI; i++) {
    lw[i] = my_towlower(i);
    up[i] = my_towupper(i);
  }

#define BENCH(name, locasefn, upcasefn)                                        \
  t0 = TEST_TIME();                                                            \
  errs = 0;                                                                    \
  for (int j = 0; j < RETRIES; j++) {                                          \
    for (i = 0; i < SZ(ws); i++) {                                             \
      wint_t wc = ws[i];                                                       \
      wint_t n = locasefn(wc);                                                 \
      if (n != lw[wc])                                                         \
        errs++;                                                                \
    }                                                                          \
  }                                                                            \
  for (int j = 0; j < RETRIES; j++) {                                          \
    for (i = 0; i < SZ(ws); i++) {                                             \
      wint_t wc = ws[i];                                                       \
      wint_t n = upcasefn(wc);                                                 \
      if (n != up[wc])                                                         \
        errs++;                                                                \
    }                                                                          \
  }                                                                            \
  t1 = TEST_TIME();                                                            \
  if (errs)                                                                    \
    printf("%10s: %10ld [us]\t%u errors\n", name, t1 - t0, errs / RETRIES);    \
  else                                                                         \
    printf("%10s: %10ld [us]\n", name, t1 - t0)

  BENCH("my", my_towlower, my_towupper);
  BENCH("musl-new", musl_towlower, musl_towupper);
  BENCH("musl-old", old_towlower, old_towupper);
  BENCH("glibc", glibc_towlower, glibc_towupper);
  printf("\n");

  free(up);
  free(lw);
  free(ws);
  return 0;
}
