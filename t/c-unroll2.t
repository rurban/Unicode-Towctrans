#! /usr/bin/env perl
use strict;

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}

# TODO: unroll bsearch CASEL_UPPER
our $suff = 'unroll2';
our $opts = "--unroll 10 --bsearch --bits 18:12:8 --out towctrans-$suff.h";

do './c-unroll.pl';
