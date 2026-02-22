#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <wctype.h>

// wint_t glibc_towlower(wint_t wc);

int main(int argc, char **argv) {
    wint_t wc;
    if (argc < 2) {
    err:
        fprintf(stderr, "Usage: %s HEXNUMBER [-u]\n", argv[0]);
        exit(1);
    }
    int rc = sscanf(argv[1], "%X", &wc);
    if (!rc) {
        goto err;
    }
    if (argc > 2 && strcmp(argv[2], "-u") == 0)
        printf("%s towupper(U+%04x) => U+%04x\n", argv[0], wc,
               /*glibc_*/ towupper(wc));
    else
        printf("%s towlower(U+%04x) => U+%04x\n", argv[0], wc,
               /*glibc_*/ towlower(wc));
    return 0;
}
