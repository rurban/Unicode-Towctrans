#include <locale.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

/* versioned headers to compare unicode versions */
#ifdef USE_GLOBAL
#include "../towctrans.h"
#else
uint32_t _towcase(uint32_t wc, int lower);
#endif
wint_t my_towlower(wint_t wc) { return (wint_t)_towcase((uint32_t)wc, 1); }
wint_t my_towupper(wint_t wc) { return (wint_t)_towcase((uint32_t)wc, 0); }

int main(int argc, char **argv) {
  wint_t wc;
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
