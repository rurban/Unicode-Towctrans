require 5.012;
use ExtUtils::MakeMaker;

my @cf;
push @cf, "towctrans.h.$_", "CaseFolding.txt.$_" for 5..18;
my $clean = {FILES => [ 't/towctrans', 'diffs', @cf ]};
my $MM_VER = ExtUtils::MakeMaker->VERSION;
if (! -f "towctrans.h") {
    print STDERR "Making header file\n";
    do './mkheader' or die;
}

WriteMakefile(
    'AUTHOR'            => 'Reini Urban <rurban@cpan.org>',
    'ABSTRACT'          => 'Generate Unicode Case Transformation Tables',
    # see perl5110delta, @INC reorganization
    'INSTALLDIRS'       => ($] >= 5.007002 && $] < 5.011) ? 'perl' : 'site',
    'LICENSE'           => 'perl',
    'NAME'              => 'Unicode::Towctrans',
    'VERSION_FROM'      => 'Towctrans.pm', # finds $VERSION
    'clean'             => $clean,
     #'depend'            => { 'Towctrans.o' => '$(H_FILES)' },
    'PREREQ_PM'         => {
        Carp            => 0,
        constant        => 0,
        strict          => 0,
        warnings        => 0,
    },
    ($MM_VER < 6.48 ? () : MIN_PERL_VERSION => 5.6.0),
    ($MM_VER < 6.46 ? () : (META_MERGE => {
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

package MY;
sub depend {
  '
CaseFolding.txt:
	./mkheader
CaseFolding.txt.8 towctrans.h.8:
	for v in `seq 5 18`; do ./mkheader --out towctrans.h.$$v -v $$v --cf CaseFolding.txt.$$v; done
test-all : mkheader CaseFolding.txt.8
	for v in `seq 5 18`; do \
          $(FULLPERLRUN) mkheader --out towctrans.h -v $$v --cf CaseFolding.txt; \
          echo Unicode $$v; \
          $(FULLPERLRUN) -MExtUtils::Command::MM -MTest::Harness -e "test_harness(0)" t/*.t; \
        done
diffs : mkheader CaseFolding.txt.8
	for v in `seq 5 17`; do n=$$(($$v + 1)); diff -bu towctrans.h.$$v towctrans.h.$$n; done
'
}

