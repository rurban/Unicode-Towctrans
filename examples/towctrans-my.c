#include <wchar.h>

#ifdef LOW16
#include "towctrans-low16.h"
wint_t my_low16_towlower(wint_t wc) { return _towcase_low16(wc, 0); }
wint_t my_low16_towupper(wint_t wc) { return _towcase_low16(wc, 1); }
#else
#include "towctrans-15.h"
wint_t my_towlower(wint_t wc) { return _towcase(wc, 0); }
wint_t my_towupper(wint_t wc) { return _towcase(wc, 1); }
#endif
