#ifdef SET_LOCALE
#include <locale.h>
#endif
#include <stdio.h>
#include <wctype.h>

int main(int argc, char **argv) {
    (void)argc;
#ifdef SET_LOCALE
    setlocale(LC_ALL, "en_US.UTF-8");
#endif
    int rc0 = iswalpha(0x0181);
    if (!rc0)
        printf("%s: iswalpha(U+0181) %s\n", argv[0],
               "is broken for U+0181 already");
    int rc1 = iswalpha(0x1DF51);
    int rc = rc0 & rc1; // both must be 1
    printf("%s: iswalpha(0x1DF51) %s\n", argv[0],
           !rc ? "is broken" : "works ok");
    return rc == 0 ? 1 : 0;
}
