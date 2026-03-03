#include <ctype.h>
#include <locale.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wctype.h>

// no wupper yet
#ifdef LOW16
#include "towctrans-low16.h"
#elif defined BITS
#include "towctrans-bits.h"
#elif defined TABLE
#include "towctrans-table.h"
#elif defined BSEARCH_BOTH
#include "towctrans-bsearch-both.h"
#elif defined BSEARCH
#include "towctrans-bsearch.h"
#else
#include "towctrans.h"
#endif
#define UDATA "UnicodeData.txt"

#ifdef TABLE
uint32_t my_towlower(uint32_t wc) { return (uint32_t)_towcase(wc, 1); }
uint32_t my_towupper(uint32_t wc) { return (uint32_t)_towcase(wc, 0); }
#else
uint32_t my_towlower(uint32_t wc) { return _towcase(wc, 1); }
uint32_t my_towupper(uint32_t wc) { return _towcase(wc, 0); }
#endif

/* Parse semicolon-separated fields from a UnicodeData.txt line.
   Returns number of fields parsed. Modifies buf in-place. */
static int parse_ud_fields(char *buf, char *fields[], int maxfields) {
    int nf = 0;
    char *p = buf;
    while (nf < maxfields) {
        fields[nf++] = p;
        p = strchr(p, ';');
        if (!p)
            break;
        *p++ = '\0';
    }
    return nf;
}

int main(void) {
    int errs = 0;
    int i = 1;
    char s[512];
    char buf[512];
    FILE *f;
    int tests = 0;

    setlocale(LC_ALL, "en_US.UTF-8");

    /*--------------------------------------------------*/

    f = fopen("../" UDATA, "r");
    if (!f) {
        char url[256];
        snprintf(
            url, 255,
            "wget -q -O ../%s https://www.unicode.org/Public/%d.0.0/ucd/%s",
            UDATA, TOWCTRANS_UNICODE_VERSION, UDATA);
        printf("# downloading %s ...", UDATA);
        fflush(stdout);
        if (system(url) == 0) {
            printf(" done\n");
            f = fopen("../" UDATA, "r");
        } else {
            printf(" failed\n");
        }
        if (!f) {
            printf("1..0 # skip %s not available\n", UDATA);
            return 0;
        }
    }

    /* First pass: count tests.
       field 13 (Simple_Lowercase_Mapping) non-empty => towlower test
       field 12 (Simple_Uppercase_Mapping) non-empty => towupper test */
    while (fgets(s, sizeof(s), f)) {
        char *fields[15];
        int nf;
        if (s[0] == '#' || s[0] == '\n' || s[0] == '\0')
            continue;
        strcpy(buf, s);
        nf = parse_ud_fields(buf, fields, 15);
        if (nf < 14)
            continue;
        /* field 13: Simple_Lowercase_Mapping */
        if (fields[13][0] && fields[13][0] != '\n' && fields[13][0] != '\r')
            tests++;
        /* field 12: Simple_Uppercase_Mapping */
        if (fields[12][0] && fields[12][0] != '\n' && fields[12][0] != '\r')
            tests++;
    }

    printf("1..%u\n", tests);
    fseek(f, 0, SEEK_SET);

    /* Second pass: run tests */
    while (fgets(s, sizeof(s), f)) {
        char *fields[15];
        int nf;
        unsigned cp, expected;
        uint32_t result;

        if (s[0] == '#' || s[0] == '\n' || s[0] == '\0')
            continue;
        strcpy(buf, s);
        nf = parse_ud_fields(buf, fields, 15);
        if (nf < 14)
            continue;
        if (sscanf(fields[0], "%X", &cp) != 1)
            continue;

        /* Test towlower: field 13 = Simple_Lowercase_Mapping */
        if (fields[13][0] && fields[13][0] != '\n' && fields[13][0] != '\r') {
            if (sscanf(fields[13], "%X", &expected) == 1) {
                result = cp < 128 ? (uint32_t)tolower(cp) : my_towlower(cp);
                if (result != expected) {
                    printf("not ok %u Error towlower(U+%04X) => U+%04X != "
                           "expected U+%04X name=%s\n",
                           i++, cp, result, expected, fields[1]);
                    errs++;
                } else {
                    printf("ok %u towlower(U+%04X) => U+%04X name=%s\n", i++,
                           cp, expected, fields[1]);
                }
            }
        }

        /* Test towupper: field 12 = Simple_Uppercase_Mapping */
        if (fields[12][0] && fields[12][0] != '\n' && fields[12][0] != '\r') {
            if (sscanf(fields[12], "%X", &expected) == 1) {
                result = cp < 128 ? (uint32_t)toupper(cp) : my_towupper(cp);
                if (result != expected) {
                    printf("not ok %u Error towupper(U+%04X) => U+%04X != "
                           "expected U+%04X name=%s\n",
                           i++, cp, result, expected, fields[1]);
                    errs++;
                } else {
                    printf("ok %u towupper(U+%04X) => U+%04X name=%s\n", i++,
                           cp, expected, fields[1]);
                }
            }
        }
    }
    fclose(f);
    return (errs);
}
