#include <wchar.h>
#include <wctype.h>

/* Fake the libc code locale lookup table size to compare sizes:
   cd ~/Software/glibc/.build
   strip wctype/towctrans.os
   strip locale/C-ctype.os
   wc -c wctype/towctrans.os locale/C-ctype.os
       936 wctype/towctrans.os
     94872 locale/C-ctype.os
     95808 total
 */
const char _nl_C_ctype_lower_upper_tables[95808] = {1};

wint_t glibc_towlower(wint_t wc) { return towlower(wc); }
wint_t glibc_towupper(wint_t wc) { return towupper(wc); }
