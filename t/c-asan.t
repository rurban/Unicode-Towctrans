#! /usr/bin/env perl
use strict;
use Config qw( %Config );

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}
use Test::More import => [qw( diag )];

my $is_mswin = $^O eq 'MSWin32';
my $cc       = $Config{cc};
my $exe      = "t_towctrans_asan" . ( $^O eq 'MSWin32' ? ".exe" : "" );
my $prefix   = $^O eq 'MSWin32' ? "" : "./";
my $args     = "-fsanitize=address -I.. -o $exe test_towctrans.c";

print "running $cc $args\n" if $ENV{TEST_VERBOSE};
my $output = `$cc $args`;
if ( $? != 0 ) {
    diag $output;
    print "1..0 # skip AddressSanitizer not supported by $cc\n";
    exit 0;
}
print "running $prefix$exe\n" if $ENV{TEST_VERBOSE};
system("$prefix$exe");

END {
    unlink($exe) unless $ENV{TEST_VERBOSE};
}
