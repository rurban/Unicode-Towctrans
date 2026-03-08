#! /usr/bin/env perl
use strict;

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}

# unroll bsearch PAIRL and PAIRL_UPPER
our $suff = 'unroll5';
our $opts
    = "--unroll 5 --bsearch-both --out towctrans-$suff.h -v 18 --ud UnicodeData.txt.18";

do './c-unroll.pl';
