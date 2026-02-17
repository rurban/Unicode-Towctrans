#include <wchar.h>

#include "towctrans-15.h"

wint_t my_towlower(wint_t wc) { return _towcase(wc, 0); }
wint_t my_towupper(wint_t wc) { return _towcase(wc, 1); }
