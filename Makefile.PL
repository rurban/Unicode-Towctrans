require 5.012;
use ExtUtils::MakeMaker;

my $BIN = 'bin/gen_wctrans';
my @cf;
push @cf, "towctrans.h.$_", "CaseFolding.txt.$_" for 5..18;
my $clean = {FILES => [ 't/towctrans', 'diffs', @cf ]};
my $MM_VER = ExtUtils::MakeMaker->VERSION;
if (! -f "towctrans.h") {
    print STDERR "Making header file\n";
    do 'bin/gen_wctrans' or die;
}

WriteMakefile(
    'AUTHOR'            => 'Reini Urban <rurban@cpan.org>',
    'ABSTRACT'          => 'Generate Unicode Case Transformation Tables',
    # see perl5110delta, @INC reorganization
    'INSTALLDIRS'       => ($] >= 5.007002 && $] < 5.011) ? 'perl' : 'site',
    'LICENSE'           => 'perl',
    'NAME'              => 'Unicode::Towctrans',
    'VERSION_FROM'      => $BIN,
    'clean'             => $clean,
    'PREREQ_PM'         => {
        Carp            => 0,
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
tidy:
	perltidy -b bin/gen_wctrans
CaseFolding.txt:
	 bin/gen_wctrans
CaseFolding.txt.8 towctrans.h.8:
	for v in `seq 5 18`; do $(FULLPERLRUN) bin/gen_wctrans --out towctrans.h.$$v -v $$v --cf CaseFolding.txt.$$v; done
test-all : bin/gen_wctrans CaseFolding.txt.8
	for v in `seq 5 18`; do \
          $(FULLPERLRUN) bin/gen_wctrans --out towctrans.h -v $$v --cf CaseFolding.txt; \
          echo Unicode $$v; \
          $(FULLPERLRUN) -MExtUtils::Command::MM -MTest::Harness -e "test_harness(0)" t/*.t; \
        done
diffs : bin/gen_wctrans CaseFolding.txt.8
	for v in `seq 5 17`; do n=$$(($$v + 1)); diff -bu towctrans.h.$$v towctrans.h.$$n; done

release-test : test dist
	if test "$(shell git rev-parse --abbrev-ref HEAD)" != "master" || \
           test "$(shell git diff --raw)" != "" || \
           test "$(shell git diff --cached --raw)" != "" ; then \
          echo "You are not on a clean master branch, aborting."; \
          exit 1; \
	fi
	if test "$(shell git ls --show-signature -n 1 | head -n2 | tail -n1 | cut -c1-5)" != "gpg: " ; then \
            echo "need git commit with -S"; \
            exit 1; \
	fi
	if test "$(shell git ls --no-show-signature -n 1 | head -n5 | tail -n1 | cut -c5-11)" != "Release" ; then \
            echo "need git commit with -m Release"; \
            exit 1; \
	fi

release : release-test
	-git tag -f $(VERSION)
	cpan-upload $(DISTVNAME).tar$(SUFFIX)
	git push
	git push --tags
'
}

