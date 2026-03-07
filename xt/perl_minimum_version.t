# -*- perl -*-

# Test that our declared minimum Perl version matches our syntax
use strict;

BEGIN {
    $|  = 1;
    $^W = 1;
}

my @MODULES = (
    'Perl::MinimumVersion::Fast 0.22',
    'Test::MinimumVersion::Fast 0.04',
    'YAML::Tiny 1.40',
    'File::Find::Rule',
    'File::Find::Rule::Perl'
);

# Don't run tests during end-user installs
use Test::More import => [qw( plan )];
unless ( -d '.git' || $ENV{AUTHOR_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Load the testing modules
foreach my $MODULE (@MODULES) {
    eval "use $MODULE";
    if ($@) {
        plan( skip_all => "$MODULE not available for testing" );
        die "Failed to load required release-testing module $MODULE"
            if -d '.git' || $ENV{AUTHOR_TESTING};
    }
}

all_minimum_version_ok(
    "5.012",
    {   paths => [qw(bin/gen_wctrans t examples Makefile.PL)],
        skip  => [
            qw(t/changes.t t/kwalitee.t t/manifest.t t/meta.t t/perl_minimum_version.t
                t/pod-coverage.t t/pod-spell-mistakes.t t/pod-spelling.t t/pod.t)
        ]
    }
);

1;
