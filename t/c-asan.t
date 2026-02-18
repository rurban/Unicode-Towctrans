#! /usr/bin/env perl
use strict;
use Config qw( %Config );

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}
use Test::More ();

my $is_mswin = $^O eq 'MSWin32';
my $cc       = $Config{cc};
my $exe      = "t_towctrans_asan" . ( $^O eq 'MSWin32' ? ".exe" : "" );
my $prefix   = $^O eq 'MSWin32' ? "" : "./";
my $args     = "-fsanitize=address -I.. -o $exe test_towctrans.c";

print "running $cc $args\n" if $ENV{TEST_VERBOSE};
system("$cc $args");
print "running $prefix$exe\n" if $ENV{TEST_VERBOSE};
system("$prefix$exe");

END {
    unlink($exe);
}
