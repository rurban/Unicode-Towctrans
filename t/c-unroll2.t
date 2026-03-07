#! /usr/bin/env perl
use strict;

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}

# unroll bsearch CASEL upper-only and CASEL lower-only
our $suff = 'unroll2';
our $opts
    = "--unroll 10 --bsearch --bits 18:12:8 --out towctrans-$suff.h -v 16 --ud UnicodeData.txt.16";

do './c-unroll.pl';
