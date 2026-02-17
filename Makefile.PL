require 5.006001;
use ExtUtils::MakeMaker;

my $clean = {};

my $mm_ver = ExtUtils::MakeMaker->VERSION;

if (-f "Towctrans.xs") {
    print STDERR "Making header files for XS...\n";

    our $ind = 1;
    do './mkheader' or die $@ || "mkheader -ind: $!";

    $clean = { FILES => 'un8ifcan.h un8ifcmb.h un8ifcmp.h un8ifcpt.h un8ifexc.h' };
}

WriteMakefile(
    'AUTHOR' => 'Reini Urban <rurban@cpan.org>'
    'ABSTRACT'          => 'Unicode Lowercase Transformation Tables',
    'INSTALLDIRS'       => ($] >= 5.007002 && $] < 5.011) ? 'perl' : 'site',
                            # see perl5110delta, @INC reorganization
    'LICENSE'           => 'perl',
    'NAME'              => 'Unicode::Towctrans',
    'VERSION_FROM'      => 'Towctrans.pm', # finds $VERSION
    'clean'             => $clean,
    'depend'            => { 'Towctrans.o' => '$(H_FILES)' },
    'PREREQ_PM'         => {
        Carp            => 0,
        constant        => 0,
        DynaLoader      => 0,
        Exporter        => 0,
        File::Spec      => 0,
        strict          => 0,
        warnings        => 0,
        SelectSaver     => 0,
    },
    ($mm_ver < 6.48 ? () : MIN_PERL_VERSION => 5.6.0),
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources       => {
            repository    => {
                url  => 'https://github.com/rurban/Unicode-Towctrans.git',
                web  => 'https://github.com/rurban/Unicode-Towctrans',
                type => 'git',
            },
            bugtracker    => {
                web  => 'https://github.com/rurban/Unicode-Towctrans/issues',
            },
        },
    })),
);
