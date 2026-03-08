require 5.012;
use Config              qw( %Config );
use ExtUtils::MakeMaker qw( WriteMakefile );

my $BIN = 'bin/gen_wctrans';

# Check if this iswalpha() works or is locale sensitive.
if ( has_working_iswalpha() ) {

    # we may want to change the default in bin/gen_wctrans
    print "iswalpha() works, you can use $BIN with --with-iswalpha\n";
}

if ( !-f "towctrans.h" ) {
    print STDERR "Making header file\n";
    do 'bin/gen_wctrans' or die;
}

my @ud;
push @ud, "towctrans.h.$_", "UnicodeData.txt.$_" for 5 .. 18;
push @ud, "examples/test-$_" for 5 .. 18;
my $clean = {
    FILES => [
        't/towctrans',                'diffs',
        @ud,                          'examples/test-glibc',
        'bin/gen_wctrans.bak',        glob('t/*.bak'),
        glob('examples/tow*.o'),      'examples/towctrans.h',
        glob('examples/bits-*.[ch]'), 'examples/bits.h',
        'examples/bench-bits',        'examples/bench-bits.h',
        't/c-if-tree-search_even',    't/c-if-tree-search_even.c',
        't/c-if-tree-search_odd',     't/c-if-tree-search_odd.c',
        glob('t/t_*'),
    ]
};
my $MM_VER = ExtUtils::MakeMaker->VERSION;
WriteMakefile(
    'AUTHOR'       => 'Reini Urban <rurban@cpan.org>',
    'ABSTRACT'     => 'Generate Wide-Char Unicode Case Mapping Tables',
    'INSTALLDIRS'  => 'site',
    'LICENSE'      => 'perl',
    'NAME'         => 'Unicode::Towctrans',
    'VERSION_FROM' => $BIN,
    'clean'        => $clean,
    'PREREQ_PM'    => {
        Carp         => 0,
        strict       => 0,
        warnings     => 0,
        Config       => 0,
        constant     => 0,
        Getopt::Long => 0,
        Unicode::UCD => 0,
        Test::More   => 0,
    },
    ( $MM_VER < 6.48 ? () : MIN_PERL_VERSION => 5.6.0 ),
    (   $MM_VER < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                resources   => {
                    repository => {
                        url =>
                            'https://github.com/rurban/Unicode-Towctrans.git',
                        web  => 'https://github.com/rurban/Unicode-Towctrans',
                        type => 'git',
                    },
                    bugtracker => {
                        web =>
                            'https://github.com/rurban/Unicode-Towctrans/issues',
                    },
                },
            }
        )
    ),
);

# i.e if it's musl it works, if it's glibc not.
sub has_working_iswalpha {
    my $is_mswin = $^O eq 'MSWin32';
    my $exe = "examples/test-iswalpha" . ( $^O eq 'MSWin32' ? ".exe" : "" );
    my $rc;
    if ( !-x "$exe" ) {
        my $cc     = $Config{cc};
        my $prefix = $^O eq 'MSWin32' ? "" : "./";
        my $file   = "examples/test-iswalpha.c";
        my $args   = "$file -o $exe";
        system("$cc $args") or return 0;
    }
    return system("$exe") == 0;
}

package MY;

# filter any temp .c files. We have no XS nor C files.
sub libscan {
    return 0;
}

sub depend {
    '
.PHONY: tidy test-all diffs examples release-test release update-bench
all :: towctrans.h README
' . (   $^O eq 'MSWin32'
        ? ""
        : '
.PHONY: test-precommit
xt xtest :: test-precommit test-checkmake
	prove xt/*.t
test-checkmake :
	if command -v checkmake; then checkmake examples/Makefile; fi
test-precommit :
	if command -v prek; then prek run -a; \
	elif command -v pre-commit; then pre-commit run -a; \
        fi
'
        ) . '
README: bin/gen_wctrans
	cp towctrans.h towctrans.h.bak
	bin/gen_wctrans
	if ! cmp towctrans.h towctrans.h.bak 2>/dev/null; then \
	  make -C examples update-bench; fi
	rm -f towctrans.h.bak
	pod2text $< >$@
tidy:
	perltidy -b bin/gen_wctrans
UnicodeData.txt:
	 bin/gen_wctrans
UnicodeData.txt.8 towctrans-8.h:
	for v in `seq 5 18`; do $(FULLPERLRUN) bin/gen_wctrans --out towctrans-$$v.h -v $$v --ud UnicodeData.txt.$$v; done
test-all : bin/gen_wctrans UnicodeData.txt.8 towctrans-8.h
	for v in `seq 5 18`; do \
	  $(FULLPERLRUN) bin/gen_wctrans --out towctrans.h -v $$v --ud UnicodeData.txt; \
	  echo Unicode $$v; \
	  $(FULLPERLRUN) -MExtUtils::Command::MM -MTest::Harness -e "test_harness(0)" t/*.t; done; \
	$(FULLPERLRUN) bin/gen_wctrans --out towctrans.h
diffs : bin/gen_wctrans UnicodeData.txt.8
	for v in `seq 5 17`; do n=$$(($$v + 1)); diff -bu towctrans-$$v.h towctrans-$$n.h; done
towctrans.h: bin/gen_wctrans
	$(FULLPERLRUN) bin/gen_wctrans
UnicodeData.txt.10:
	$(FULLPERLRUN) bin/gen_wctrans --out towctrans-10.h -v 10 --ud UnicodeData.txt.10
towctrans-10.h: UnicodeData.txt.10
bench: towctrans-10.h
	@if test -f examples/bench; then rm examples/bench; fi
	make -C examples bench
update-bench:
	make -C examples $@
examples:
	make -C examples
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
