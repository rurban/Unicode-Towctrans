#include <ctype.h>
#include <locale.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wctype.h>

#include "towctrans.h"
#include "towfc.h"

/* Build versioned filename after towfc.h defines TOWFC_UNICODE_VERSION */
#define _TOWFC_STR_(x) #x
#define _TOWFC_STR(x) _TOWFC_STR_(x)
#define CFDATA "CaseFolding.txt." _TOWFC_STR(TOWFC_UNICODE_VERSION)

/* Parse semicolon-separated fields from a CaseFolding.txt line.
   Trims leading/trailing spaces from each field.
   Returns number of fields parsed. Modifies buf in-place. */
static int parse_cf_fields(char *buf, char *fields[], int maxfields) {
    int nf = 0;
    char *p = buf;
    /* strip trailing newline */
    char *nl = strchr(p, '\n');
    if (nl)
        *nl = '\0';
    nl = strchr(p, '\r');
    if (nl)
        *nl = '\0';
    while (nf < maxfields) {
        while (*p == ' ')
            p++; /* trim leading spaces */
        fields[nf++] = p;
        p = strchr(p, ';');
        if (!p)
            break;
        /* trim trailing spaces from previous field */
        char *end = p - 1;
        while (end >= fields[nf - 1] && *end == ' ')
            end--;
        *(end + 1) = '\0';
        p++;
    }
    return nf;
}

/* Extract name from comment field (strips leading "# " if present) */
static const char *cf_name(const char *field) {
    if (!field)
        return "";
    while (*field == ' ')
        field++;
    if (field[0] == '#' && field[1] == ' ')
        return field + 2;
    if (field[0] == '#')
        return field + 1;
    return field;
}

int main(void) {
    int errs = 0;
    int i = 1;
    char s[512];
    char buf[512];
    FILE *f;
    int tests = 0;

    setlocale(LC_ALL, "en_US.UTF-8");

    f = fopen("../" CFDATA, "r");
    if (!f) {
        char url[256];
        snprintf(url, 255,
                 "wget -q -O ../%s "
                 "https://www.unicode.org/Public/%d.0.0/ucd/CaseFolding.txt",
                 CFDATA, TOWFC_UNICODE_VERSION);
        printf("# downloading %s ...", CFDATA);
        fflush(stdout);
        if (system(url) == 0) {
            printf(" done\n");
            f = fopen("../" CFDATA, "r");
        } else {
            printf(" failed\n");
        }
        if (!f) {
            printf("1..0 # skip %s not available\n", CFDATA);
            return 0;
        }
    }

    /* First pass: count tests.
       C entries: 1 towfc test each.
       F entries: 1 towfc test + 1 iswfc test each.
       S and T entries are skipped. */
    while (fgets(s, sizeof(s), f)) {
        char *fields[4];
        int nf;
        char type;
        if (s[0] == '#' || s[0] == '\n' || s[0] == '\0')
            continue;
        strcpy(buf, s);
        nf = parse_cf_fields(buf, fields, 4);
        if (nf < 3)
            continue;
        type = fields[1][0];
        if (type == 'C')
            tests++; /* towfc test */
        else if (type == 'F')
            tests += 2; /* towfc test + iswfc test */
        /* skip S (simple) and T (Turkic) */
    }

    printf("1..%u\n", tests);
    fseek(f, 0, SEEK_SET);

    /* Second pass: run tests */
    while (fgets(s, sizeof(s), f)) {
        char *fields[4];
        int nf;
        char type;
        unsigned cp;
        unsigned mapped[3];
        int nmapped;
        wchar_t dest[4];
        int ret;
        char *mp;
        const char *name;

        if (s[0] == '#' || s[0] == '\n' || s[0] == '\0')
            continue;
        strcpy(buf, s);
        nf = parse_cf_fields(buf, fields, 4);
        if (nf < 3)
            continue;
        if (sscanf(fields[0], "%X", &cp) != 1)
            continue;

        type = fields[1][0];
        if (type != 'C' && type != 'F')
            continue;

        name = (nf >= 4) ? cf_name(fields[3]) : "";

        /* Parse mapping codepoints from fields[2] */
        nmapped = 0;
        mapped[0] = mapped[1] = mapped[2] = 0;
        mp = fields[2];
        while (nmapped < 3) {
            while (*mp == ' ')
                mp++;
            if (!*mp)
                break;
            if (sscanf(mp, "%X", &mapped[nmapped]) != 1)
                break;
            nmapped++;
            while (*mp && *mp != ' ')
                mp++;
        }
        if (nmapped == 0)
            continue;

        /* Test towfc */
        dest[0] = dest[1] = dest[2] = dest[3] = L'\0';
        ret = towfc(dest, 4, (uint32_t)cp);

        if (type == 'C') {
            /* Expect single-char result matching mapped[0] */
            if (ret != 1 || (uint32_t)dest[0] != mapped[0]) {
                printf("not ok %u Error towfc(U+%04X) => {U+%04X} ret=%d, "
                       "expected {U+%04X} name=%s\n",
                       i++, cp, (unsigned)dest[0], ret, mapped[0], name);
                errs++;
            } else {
                printf("ok %u towfc(U+%04X) => U+%04X name=%s\n", i++, cp,
                       mapped[0], name);
            }
        } else {
            /* F entry: expect multi-char result */
            int ok = 1;
            if (ret != nmapped)
                ok = 0;
            if (ok && (uint32_t)dest[0] != mapped[0])
                ok = 0;
            if (ok && nmapped >= 2 && (uint32_t)dest[1] != mapped[1])
                ok = 0;
            if (ok && nmapped >= 3 && (uint32_t)dest[2] != mapped[2])
                ok = 0;

            if (!ok) {
                if (nmapped == 2)
                    printf("not ok %u Error towfc(U+%04X) => {U+%04X,U+%04X}"
                           " ret=%d, expected {U+%04X,U+%04X} name=%s\n",
                           i++, cp, (unsigned)dest[0], (unsigned)dest[1], ret,
                           mapped[0], mapped[1], name);
                else
                    printf("not ok %u Error towfc(U+%04X) => "
                           "{U+%04X,U+%04X,U+%04X} ret=%d, expected "
                           "{U+%04X,U+%04X,U+%04X} name=%s\n",
                           i++, cp, (unsigned)dest[0], (unsigned)dest[1],
                           (unsigned)dest[2], ret, mapped[0], mapped[1],
                           mapped[2], name);
                errs++;
            } else {
                if (nmapped == 2)
                    printf("ok %u towfc(U+%04X) => {U+%04X,U+%04X} name=%s\n",
                           i++, cp, mapped[0], mapped[1], name);
                else
                    printf("ok %u towfc(U+%04X) => {U+%04X,U+%04X,U+%04X}"
                           " name=%s\n",
                           i++, cp, mapped[0], mapped[1], mapped[2], name);
            }

            /* Test iswfc: should return nmapped (2 or 3) */
            {
                int isw = iswfc((uint32_t)cp);
                if (isw != nmapped) {
                    printf("not ok %u Error iswfc(U+%04X) => %d, expected %d"
                           " name=%s\n",
                           i++, cp, isw, nmapped, name);
                    errs++;
                } else {
                    printf("ok %u iswfc(U+%04X) => %d name=%s\n", i++, cp,
                           nmapped, name);
                }
            }
        }
    }
    fclose(f);
    return (errs);
}
