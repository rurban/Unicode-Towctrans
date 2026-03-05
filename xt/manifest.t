# -*- perl -*-
use Test::More import => [qw( is ok plan )];
if ( !-d ".git" and $^O != /^(linux|.*bsd|darwin|solaris|sunos|cygwin)$/ ) {
    plan skip_all => "requires a git checkout and a unix for git and diff";
}
plan tests => 1;

system(   "git ls-tree -r --name-only HEAD |"
        . " grep -v -f MANIFEST.SKIP >MANIFEST.git" );
if ( -e "MANIFEST.git" && -s "MANIFEST.git" ) {

    #diag "MANIFEST.git created with git ls-tree";
    is( `diff -bu MANIFEST.git MANIFEST`,
        "",
        "MANIFEST.git compared to MANIFEST"
    ) and unlink "MANIFEST.git";
}
else {
    ok( 1, "skip no git or grep" );
}
