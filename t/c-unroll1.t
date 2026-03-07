#! /usr/bin/env perl
use strict;

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}

# unrolls 6x casemapsl
our $suff = 'unroll1';
our $opts = "--unroll 6 --lower16 --out towctrans-$suff.h";

do './c-unroll.pl';
