# -*- perl -*-
use strict;
use Test::More import => [qw( plan )];

plan skip_all => 'This test is only run for the module author'
    unless -d '.git' || $ENV{AUTHOR_TESTING};

eval "use Test::Spelling;";
plan skip_all => "Test::Spelling required"
    if $@;

add_stopwords(<DATA>);
open my $fh, '<', 'MANIFEST' or die "MANIFEST: $!";
my @manifest = <$fh>;
my %SKIP     = map { $_ => 1 }
    qw(t/changes.t t/kwalitee.t t/manifest.t t/meta.t t/perl_minimum_version.t
    t/pod-coverage.t t/pod-spell-mistakes.t t/pod-spelling.t t/pod.t);
@manifest = grep { !/^\s*#/ } @manifest;
chomp for @manifest;
@manifest = grep { !$SKIP{$_} } @manifest;
close $fh;
all_pod_files_spelling_ok(@manifest);

__DATA__
CaseFolding
Reini
azeri
casefolding
foldcasing
libc
musl
fixups
safeclib
turkish
un
unicode
wget
