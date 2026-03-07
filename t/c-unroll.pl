use Config qw( %Config );
use Test::More import => [qw( diag )];
our $is_mswin = $^O eq 'MSWin32';
our $cc       = $Config{cc};

chdir("..");
system("bin/gen_wctrans $opts");
chdir("t");

my $exe    = "t_$suff" . ( $^O eq 'MSWin32' ? ".exe" : "" );
my $prefix = $^O eq 'MSWin32' ? "" : "./";
my $args   = "-D" . uc($suff) . " test_towctrans.c -I.. -o $exe";
$args .= " -g" if $ENV{TEST_VERBOSE};

print "running $cc $args\n" if $ENV{TEST_VERBOSE};
my $output = `$cc $args 2>&1`;
if ( $? != 0 ) {
    diag $output;
    print "1..0 # skip $cc $args failed\n";
    exit 0;
}
print "running $prefix$exe\n" if $ENV{TEST_VERBOSE};
system("$prefix$exe");

END {
    unlink( $exe, "../towctrans-$suff.h" ) unless $ENV{TEST_VERBOSE};
}
