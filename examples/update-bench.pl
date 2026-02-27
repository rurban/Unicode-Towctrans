#!/usr/bin/env perl
use strict;
use warnings;

sub usage {
    die "Usage: $0 gen_wctrans bench.log\n$!";
}
usage() if @ARGV != 2;

my $bench;
{
    local $/;
    open my $fh, '<', $ARGV[1] or usage();
    my $s = <$fh>;
    close $fh;
    ($bench) = $s =~ m{^(\./bench.+?)^\d+ total}ms;
}
$bench =~ s/ towctrans-my\.o .+?glibc\.o$/ towctrans-*.o/ms;
$bench =~ s/\n/\n    /gms;
$bench =~ s/\n    \n/\n\n/gms;
$bench =~ s/\n    $/\n/;
$bench = "    " . $bench;

{
    my $found;
    my $gen = $ARGV[0];
    open my $in,  '<', $gen       or usage();
    open my $out, '>', "$gen.tmp" or usage();
    while (<$in>) {
        if (m{^    ./bench}) {
            $found = 1;
            next;
        }
        if (m{Results with more various}) {
            $found = 0;
            print $out $bench . "\n";
        }
        if ( !$found ) {
            print $out $_;
        }
    }
    close $in;
    close $out;
    chmod 0755, "$gen.tmp";
    system("mv $gen.tmp $gen") == 0 or die "mv: $!";
    unlink "$gen.tmp";
}
