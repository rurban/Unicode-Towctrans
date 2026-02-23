#! /usr/bin/env perl
use strict;
use Config qw( %Config );

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}
use Test::More import => [qw( diag ok )];

my $is_mswin = $^O eq 'MSWin32';
my $cc       = $Config{cc};
my $exe      = "t_towctrans" . ( $^O eq 'MSWin32' ? ".exe" : "" );
my $prefix   = $^O eq 'MSWin32' ? "" : "./";
my $args     = "test_towctrans.c -I.. -o $exe";

sub compiles_empty {
    my $args = "main.c -o $exe";
    open my $fh, ">", "main.c" or die "main.c: $!";
    print $fh "int main() { return 0; }\n";
    close $fh;
    print "running $cc $args\n" if $ENV{TEST_VERBOSE};
    my $output = `$cc $args`;
    if ( $? != 0 ) {
        diag "cc fails: $output";
        unlink "main.c", $exe;
        return 0;
    }
    unlink "main.c", $exe;
    return 1;
}

print "running $cc $args\n" if $ENV{TEST_VERBOSE};
my $output = `$cc $args`;
if ( $? != 0 ) {
    diag $output;

    # crosscheck that an empty main works. Let it fail then.
    if ( !compiles_empty() ) {
        print "1..0 # skip $cc fails to compile a simple main\n";
        exit 0;
    }

    # now we know our header is broken, not the system cc
    print "1..1\n";
    ok( 0, "$cc $args failed" );
    exit 1;
}
print "running $prefix$exe\n" if $ENV{TEST_VERBOSE};
system("$prefix$exe");

END {
    unlink($exe) unless $ENV{TEST_VERBOSE};
}
