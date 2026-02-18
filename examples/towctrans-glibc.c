#include <wchar.h>
#include <wctype.h>

wint_t glibc_towlower(wint_t wc) { return towlower(wc); }
wint_t glibc_towupper(wint_t wc) { return towupper(wc); }
