#! /usr/bin/env perl
use strict;

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}

# unroll 3x PAIRL
our $suff = 'unroll4';
our $opts
    = "--unroll 5 --out towctrans-$suff.h -v 18 --ud UnicodeData.txt.18";

do './c-unroll.pl';
