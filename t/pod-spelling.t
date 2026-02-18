# -*- perl -*-
use strict;
use Test::More import => [qw( plan )];

plan skip_all => 'This test is only run for the module author'
    unless -d '.git' || $ENV{AUTHOR_TESTING};

eval "use Test::Spelling;";
plan skip_all => "Test::Spelling required"
    if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok( 'bin', '.' );

__DATA__
Reini
CaseFolding
casefolding
libc
musl
un
wget
