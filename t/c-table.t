#! /usr/bin/env perl
use strict;
use Config qw( %Config );

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}
use Test::More import => [qw( diag )];

chdir("..");
system("bin/gen_wctrans --table --out towctrans-table.h");
chdir("t");

my $is_mswin = $^O eq 'MSWin32';
my $cc       = $Config{cc};
my $exe      = "t_table" . ( $^O eq 'MSWin32' ? ".exe" : "" );
my $prefix   = $^O eq 'MSWin32' ? "" : "./";
my $args     = "-DTABLE test_towctrans.c -I.. -o $exe";
$args .= " -g" if $ENV{TEST_VERBOSE};

print "running $cc $args\n" if $ENV{TEST_VERBOSE};
my $output = `$cc $args`;
if ( $? != 0 ) {
    diag $output;
    print "1..0 # $cc $args failed\n";
    exit 0;
}
print "running $prefix$exe\n" if $ENV{TEST_VERBOSE};
system("$prefix$exe");

END {
    unlink( $exe, "../towctrans-table.h" ) unless $ENV{TEST_VERBOSE};
}
