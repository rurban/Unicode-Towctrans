#! /usr/bin/env perl
use strict;

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}

# unroll bsearch CASEL upper-only and CASEL lower-only
our $suff = 'unroll2';
our $opts
    = "--unroll 10 --bsearch -v 18 --bits 18:12:8 --out towctrans-$suff.h";

do './c-unroll.pl';
