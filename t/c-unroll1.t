#! /usr/bin/env perl
use strict;

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}

# unrolls 6x casemapsl
our $suff = 'unroll1';
our $opts
    = "--unroll 6 --lower16 --out towctrans-$suff.h -v 16 --ud UnicodeData.txt.16";

do './c-unroll.pl';
