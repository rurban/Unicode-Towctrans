#! /usr/bin/env perl
use strict;

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}

# unroll bsearch-both CASEL
our $suff = 'unroll3';
our $opts
    = "--unroll 5 --bsearch-both -v 18 --bits 18:12:8 --out towctrans-$suff.h";

do './c-unroll.pl';
