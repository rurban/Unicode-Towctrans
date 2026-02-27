#!/bin/sh
cd "$(dirname "$0")" || exit
CC="${CC:-cc}"
CFLAGS="${CFLAGS:- -O2 -I.}"
GEN=../bin/gen_wctrans
OBJ="towctrans-bmy.o towctrans-bmylow16.o towctrans-bmybits.o"

make bench
$CC -c $CFLAGS -DBITS_STATS         -o towctrans-bmy.o      towctrans-my.c
$CC -c $CFLAGS -DBITS_STATS -DLOW16 -o towctrans-bmylow16.o towctrans-my.c
$CC -c $CFLAGS -DBITS_STATS -DBITS  -o towctrans-bmybits.o  towctrans-my.c

echo "wint_t my_towlower(wint_t wc); // 16:8:8" >bits.h
echo "wint_t my_towupper(wint_t wc);" >>bits.h
echo "char *my_stats(void);" >>bits.h
echo "" >>bits.h
echo "wint_t my_low16_towlower(wint_t wc); // 16:16:8" >>bits.h
echo "wint_t my_low16_towupper(wint_t wc);" >>bits.h
echo "char *my_low16_stats(void);" >>bits.h
echo "" >>bits.h
echo "wint_t my_bits_towlower(wint_t wc);  // 16:10:8" >>bits.h
echo "wint_t my_bits_towupper(wint_t wc);" >>bits.h
echo "char *my_bits_stats(void);" >>bits.h
echo "" >>bits.h
echo "" >bench-bits.h

test(){
    bits="$1"
    s="$(echo $bits | sed 's/:/_/g')"
    $GEN --with-iswalpha --bits $bits --fn=_towcase_bits_$s -v 15 --out bits-$s.h --cf ../CaseFolding.txt.15
    echo "wint_t bits_${s}_towlower(wint_t wc);" >>bits.h
    echo "wint_t bits_${s}_towupper(wint_t wc);" >>bits.h
    echo "char *bits_${s}_stats(void);" >>bits.h
    echo "" >>bits.h

    echo "#include <stdio.h>" >bits-$s.c
    echo "#include <stdlib.h>" >>bits-$s.c
    echo "#include <wchar.h>" >>bits-$s.c
    echo "#include \"bits-$s.h\"" >>bits-$s.c
    echo "wint_t bits_${s}_towlower(wint_t wc) { return _towcase_bits_$s(wc, 0); };" >>bits-$s.c
    echo "wint_t bits_${s}_towupper(wint_t wc) { return _towcase_bits_$s(wc, 0); };" >>bits-$s.c
    echo "char *bits_${s}_stats(void) {"  >>bits-$s.c
    cat <<"EOF" >>bits-$s.c
#define ARRAY_SZ(a) (sizeof(a) / sizeof(*a))
    char *s = malloc(64);
    snprintf(s, 64, "%lu %lu %lu %lu %u",
             ARRAY_SZ(casemaps), ARRAY_SZ(casemapsl), ARRAY_SZ(pairs),
#ifdef HAVE_PAIRL
             ARRAY_SZ(pairl),
#else
             0L,
#endif
             6);
    return s;
}
EOF
    $CC -c $CFLAGS -o bits-$s.o bits-$s.c
    OBJ="bits-$s.o $OBJ"

    echo "    BENCH(\"$bits\", bits_${s});" >>bench-bits.h
}

# already: 16:8:8 16:16:8 16:10:8
for b in 18:14:10 18:14:8 18:12:10 18:12:8 16:12:6 16:10:6 14:10:8 14:12:6 12:12:8 ; do
    test $b
done

$CC $CFLAGS -o bench-bits bench-bits.c $OBJ
./bench-bits
wc -c $OBJ
