#! /usr/bin/env perl
use strict;
use Config;
BEGIN {
    chdir "t" if -e "t/towctrans.c";
}
use Test::More;

my $is_mswin    = $^O eq 'MSWin32';
my $cc = $Config{cc};
my $exe = "towctrans" . ($^O eq 'MSWin32' ? ".exe" : "");
my $prefix = $^O eq 'MSWin32' ? "" : "./";
my $args = "towctrans.c -I.. -o $exe";

print "running $cc $args\n" if $ENV{TEST_VERBOSE};
system("$cc $args");
print "running $prefix$exe\n" if $ENV{TEST_VERBOSE};
system("$prefix$exe");

END {
  unlink($exe);
}
