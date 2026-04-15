#! /usr/bin/env perl
use strict;
use Config qw( %Config );

BEGIN {
    chdir "t" if -e "t/test_towfc.c";
}
use Test::More import => [qw( diag ok plan )];

my $is_mswin = $^O eq 'MSWin32';
my $cc       = $Config{cc};
my $exe      = "t_towfc" . ( $^O eq 'MSWin32' ? ".exe" : "" );
my $prefix   = $^O eq 'MSWin32' ? "" : "./";
my $args     = "test_towfc.c -I.. -o $exe";
$args .= " -g" if $ENV{TEST_VERBOSE};

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
my $output = `$cc $args 2>&1`;
if ( $? != 0 ) {
    diag $output;

    # crosscheck that an empty main works. Let it fail then.
    if ( !compiles_empty() ) {
        plan skip_all => "$cc fails to compile a simple main";
    }

    # now we know our header is broken, not the system cc
    plan tests => 1;
    ok( 0, "$cc $args failed" );
    exit 1;
}
print "running $prefix$exe\n" if $ENV{TEST_VERBOSE};
system("$prefix$exe");

END {
    unlink($exe) unless $ENV{TEST_VERBOSE};
}
