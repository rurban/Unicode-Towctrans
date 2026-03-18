#! /usr/bin/env perl
use strict;
use Config qw( %Config );

BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}
use Test::More import => [qw( diag )];

sub _diag_excerpt {
    my ($text) = @_;
    return if !defined($text) || $text eq "";
    if ( $ENV{TEST_VERBOSE} ) {
        diag $text;
        return;
    }
    my @lines = split /\n/, $text;
    my $max   = 40;
    if ( @lines > $max ) {
        @lines = @lines[ 0 .. $max - 1 ];
        push @lines, "... (truncated diagnostic output)";
    }
    diag join "\n", @lines;
}

my $is_mswin = $^O eq 'MSWin32';
my $cc       = $Config{cc};
my $exe      = "t_towctrans_asan" . ( $^O eq 'MSWin32' ? ".exe" : "" );
my $prefix   = $^O eq 'MSWin32' ? "" : "./";
my $args     = "-fsanitize=address -I.. -o $exe test_towctrans.c";
$args .= " -g" if $ENV{TEST_VERBOSE};

print "running $cc $args\n" if $ENV{TEST_VERBOSE};
my $output = `$cc $args 2>&1`;
if ( $? != 0 ) {
    _diag_excerpt($output);
    print "1..0 # skip AddressSanitizer not supported by $cc\n";
    exit 0;
}
print "running $prefix$exe\n" if $ENV{TEST_VERBOSE};
my $run_output = `$prefix$exe 2>&1`;
my $run_status = $?;

# Some CPAN environments can compile with -fsanitize=address but cannot run
# the instrumented binary, or it may emit diagnostics without any TAP.
if ( $run_status != 0 ) {
    _diag_excerpt($run_output);
    print
        "1..0 # skip AddressSanitizer runtime not usable on this platform\n";
    exit 0;
}
if ( $run_output !~ /^(?:1\.\.\d+|ok\b|not ok\b)/m ) {
    _diag_excerpt($run_output);
    print "1..0 # skip AddressSanitizer test produced no TAP output\n";
    exit 0;
}
print $run_output;

END {
    unlink($exe) unless $ENV{TEST_VERBOSE};
}
