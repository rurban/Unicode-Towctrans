#! /usr/bin/env perl
use strict;
use Config qw( %Config );
use Test::More import => [qw( diag ok plan skip )];

BEGIN {
    chdir ".." if -e "../examples/bench.c";
}
plan tests => 1;

my $is_mswin = $^O eq 'MSWin32';
my $cc       = $Config{cc};
my $exeext   = $Config{exe_ext};
my $bench    = "examples/bench$exeext";
my $exe      = "t_bench$exeext";
my $make     = $Config{make};

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

SKIP: {
    skip "no Unicode::UCD",           1 unless require Unicode::UCD;
    skip "not on the github windows", 1 if $is_mswin and $ENV{GITHUB_ACTION};

    unlink $bench if -e $bench;
    my $output = `$make bench`;
    my $rc     = $?;
    if ( $rc != 0 ) {
        skip "compiler unusable", 1 unless compiles_empty();
        ok( 0, "make bench $output" );
    }
    else {
        diag $output if $ENV{TEST_VERBOSE};
        ok(1);
    }
}

END {
    unlink($exe) unless $ENV{TEST_VERBOSE};
}
