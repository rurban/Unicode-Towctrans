#include <ctype.h>
#include <locale.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wctype.h>

#include "towctrans.h"
#define CFOLD "CaseFolding.txt"

uint32_t my_towlower(uint32_t wc) { return _towcase(wc, 1); }
uint32_t my_towupper(uint32_t wc) { return _towcase(wc, 0); }

int main(void) {
    int errs = 0;
    int c, i = 1;
    char s[128];
    char code[8];
    char status[2];
    char mapping[24];
    char name[80];
    FILE *f;
    int ignore_f = 1;
    int tests = 0;
    int tests_c = 0;

    uint32_t wc, lwr;
    setlocale(LC_ALL, "en_US.UTF-8");

    /*--------------------------------------------------*/

    f = fopen("../" CFOLD, "r");
    if (!f) {
        char url[256];
        snprintf(url, 255,
                 "wget -O ../%s https://www.unicode.org/Public/%d.0.0/ucd/%s",
                 CFOLD, TOWCTRANS_UNICODE_VERSION, CFOLD);
        printf("downloading %s ...", CFOLD);
        fflush(stdout);
        if (system(url))
            printf(" done\n");
        else {
            printf(" failed\n");
            return 0;
        }
        f = fopen("../" CFOLD, "r");
        if (!f)
            return 0;
    }
    while (!feof(f)) {
        int l;
        char *p = fgets(s, sizeof(s), f);
        if (p && *p && s[0] != '#' && s[0] != '\n') {
            p = strstr(s, "; ");
            l = p - s;
            memcpy(code, s, l);
            code[l] = 0;
            *status = p[2];
            status[1] = 0;
            if (*status == 'C')
                tests_c++;
            else if (*status == 'S') // T is ignored, so only S
                tests++;
        }
    }
    printf("1..%u\n", tests_c * 2 + tests);
    fseek(f, 0, SEEK_SET);
    while (!feof(f)) {
        int l;
        char *p = fgets(s, sizeof(s), f);
        char *p1;
        if (p && *p && s[0] != '#' && s[0] != '\n') {
            p = strstr(s, "; ");
            l = p - s;
            memcpy(code, s, l);
            code[l] = 0;
            *status = p[2];
            status[1] = 0;
            p1 = strstr(&p[5], "; ");
            l = p1 - p - 5;
            memcpy(mapping, &p[5], l); /* the other cases */
            mapping[l] = 0;
            strcpy(name, &p1[4]);
            name[strlen(name) - 1] = 0;

            c = sscanf(code, "%X", &wc);
            if (c) {
                uint32_t mp, upr;
                lwr = wc < 128 ? (uint32_t)tolower(wc) : my_towlower(wc);
                c = sscanf(mapping, "%X", &mp);
                if (*status == 'T')
                    mp = lwr;
                /* we have 104 unhandled F multi-char mappings */
                else if (*status ==
                         'F') { /* lower is bigger than upper, ignored */
                    if (!ignore_f) {
                        if (lwr != wc)
                            printf("not ok %u towlower(U+%04X) => U+%04X != "
                                   "lower=(%s) F %s\n",
                                   i++, wc, lwr, mapping, name);
                        else
                            printf("ok %u towlower(U+%04X) => %s F %s\n", i++,
                                   wc, mapping, name);
                    }
                } else if (*status == 'C') { // TODO 'S' also?
                    if (mp != lwr)
                        printf("not ok %u Error towlower(U+%04X) => U+%04X != "
                               "lower=%s "
                               "status=%s "
                               "name=%s\n",
                               i++, wc, lwr, mapping, status, name);
                    else
                        printf(
                            "ok %u towlower(U+%04X) => %s status=%s name=%s\n",
                            i++, wc, mapping, status, name);
                    /* check the reverse */
                    upr = lwr < 128 ? (uint32_t)toupper(lwr) : my_towupper(lwr);
                    if (wc != upr) {
                        const uint16_t fixups[][2] = {
                            /* lower => upper */
                            {0x00E5, 0x00C5}, {0x01C6, 0x01C5},
                            {0x01C9, 0x01C8}, {0x01CC, 0x01CB},
                            {0x01F3, 0x01F1}, {0x03B2, 0x0392},
                            {0x03B5, 0x0395}, {0x03B8, 0x0398},
                            {0x03B9, 0x0399}, {0x03BA, 0x039A},
                            {0x03BC, 0x039C}, {0x03C0, 0x03A0},
                            {0x03C1, 0x03A1}, {0x03C3, 0x03A3},
                            {0x03C6, 0x03A6}, {0x03C9, 0x03A9},
                            {0x0432, 0x0412}, {0x0434, 0x0414},
                            {0x043E, 0x041E}, {0x0441, 0x0421},
                            {0x0442, 0x0422}, {0x044A, 0x042A},
                            {0x0463, 0x0462}, {0x1E61, 0x1E60},
                            {0xA64B, 0xA64A}, {0, 0}};
                        wc = towupper(lwr);
                        printf("# check against towupper()\n");
                        if (wc != upr) {
                            /* fix a typically wrong libc function */
                            for (int i = 0; fixups[i][0]; i++) {
                                if (fixups[i][0] == lwr) {
                                    printf("# your libc towupper(0x%x) => 0x%x "
                                           "is wrong\n",
                                           lwr, wc);
                                    wc = fixups[i][1];
                                    break;
                                }
                                if (fixups[i][0] > lwr)
                                    break;
                            }
                        }
                        if (wc != upr) {
                            printf(
                                "not ok %u Error towupper(U+%04X) => U+%04X != "
                                "upper=U+%04X %s\n",
                                i++, lwr, upr, wc, name);
                        } else {
                            printf("ok %u towupper(U+%04X) => U+%04X "
                                   "(cross-checked)\n",
                                   i++, lwr, upr);
                        }
                    } else {
                        printf("ok %u towupper(U+%04X) => U+%04X\n", i++, lwr,
                               upr);
                    }
                } else {
                    printf("ok %u towlower(U+%04X) => %s status=%s name=%s\n",
                           i++, wc, mapping, status, name);
                }
            } else {
                printf("not ok %u wc not parsed from %s\n", i++, code);
            }
        }
    }
    fclose(f);
    return (errs);
}
