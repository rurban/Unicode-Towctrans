#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/time.h>
#include <wchar.h>

extern uint32_t _towcase(uint32_t wc, int lower);  /* towctrans-my */
extern wint_t my_towlower(wint_t wc);
extern wint_t my_towupper(wint_t wc);
extern wint_t musl_towupper(wint_t wc); /* towctrans-musl-new */
extern wint_t musl_towlower(wint_t wc);
extern wint_t old_towupper(wint_t wc);  /* towctrans-musl-old */
extern wint_t old_towlower(wint_t wc);
// our workaround via locales does not work yet
//#define glibc_towlower towlower
//#define glibc_towupper towupper
extern wint_t glibc_towupper(wint_t wc);  /* towctrans-glibc */
extern wint_t glibc_towlower(wint_t wc);

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
  wint_t ws[10000];
  wint_t *ps;
  long t0, t1;
  srandom(0U);
  /* prep */
  for (i = 0; i < SZ(ws); i++) {
    wint_t wc = (wint_t)(random() % 0x1ffff);
    ws[i] = wc;
  }
  // warmup
  ps = &ws[0];
  for (i = 0; i < SZ(ws); i++) {
      (void)my_towlower(*ps++);
  }

#define BENCH(name, locasefn, upcasefn)                                        \
  t0 = TEST_TIME();                                                            \
  ps = &ws[0];                                                                 \
  for (i = 0; i < SZ(ws); i++) {                                               \
    *ps = locasefn(*ps);                                                       \
    ps++;                                                                      \
  }                                                                            \
  ps = &ws[0];                                                                 \
  for (i = 0; i < SZ(ws); i++) {                                               \
    *ps = upcasefn(*ps);                                                       \
    ps++;                                                                      \
  }                                                                            \
  t1 = TEST_TIME();                                                            \
  printf("%10s: %10ld [us]\n", name, t1 - t0)

  BENCH("my", my_towlower, my_towupper);
  BENCH("musl-new", musl_towlower, musl_towupper);
  BENCH("musl-old", old_towlower, old_towupper);
  BENCH("glibc", glibc_towlower, glibc_towupper);

  return 0;
}
