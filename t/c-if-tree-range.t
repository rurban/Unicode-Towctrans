#!/usr/bin/env perl -s
use Config qw( %Config );
use integer;
use Test::More import => [qw( diag is is_deeply ok plan )];

# use Data::Dump qw( dump );
BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}

our $d;
my $DEV = $d;
my $N   = $DEV ? 10 : 500;    # Number of random lookup rounds.
my $M   = $DEV ? 6  : 10;     # Length of generated @case. Must be even.
die if $M % 2;

my $is_mswin = $^O eq 'MSWin32';
my $cc       = $Config{cc};
my $prefix   = $^O eq 'MSWin32' ? "" : "./";

plan tests => 5;              # 3 + ( ( $N + 1 ) * 2 );

# needed to search for case, not ranges.

# copied verbatim from t/nested-ifs.t
# ie (4 ? (2 ? 1 : false) : (6 ? 5 : false))
sub ternary_tree {
    my ( $lo, $hi ) = @_;
    return undef if $lo > $hi;
    my $mid  = int( ( $lo + $hi + 1 ) / 2 );
    my @node = (
        $mid,
        ternary_tree( $lo,      $mid - 1 ),
        ternary_tree( $mid + 1, $hi )
    );
    pop @node while @node && !defined $node[-1];
    return @node == 1 ? $node[0] : \@node;
}

my $n6 = ternary_tree( 0, 5 );
is_deeply( $n6, [ 3, [ 1, 0, 2 ], [ 5, 4 ] ], "n=6" );

# diag dump($n6) if $ENV{TEST_VERBOSE};

my @case = ( [ 0x41, 32, 26 ] );
if ( $ENV{TEST_VERBOSE} ) {
    diag "generated casemaps:";
    diag(
        sprintf(
            "%u: [ %u, %d, %u ]",
            $#case, $case[0]->[0], $case[0]->[1], $case[0]->[2]
        )
    );
}
for ( 1 .. $M ) {    # odd array
    my $last1 = $case[-1][0] + $case[-1][1] + $case[-1][2];
    my $last2 = $case[-1][0] + $case[-1][2];
    my $last  = $last1 > $last2 ? $last1 : $last2;
    my $upper = $last + 1 + int( rand(32) );
    my $len   = 1 + int( rand(32) );
    my $lower = int( rand(2) ) % 2 ? -int( rand(128) ) : int( rand(128) );
    $lower unless $lower;    # 0 is our failure
    push @case, [ $upper, $lower, $len ];
    diag( sprintf( "%u: [ %u, %d, %u ]", $#case, $upper, $lower, $len ) )
        if $ENV{TEST_VERBOSE};
}
my $max_case = $case[-1][0] + $case[-1][2];

sub find_case {
    my ( $wc, $case ) = @_;
    for my $m (@$case) {
        if ( $wc >= $m->[0] && $wc <= $m->[0] + $m->[2] ) {
            return $wc + $m->[1] + ( $wc - $m->[0] );
        }
    }
    return 0;
}

sub search_even { }
sub search_odd  { }

is( scalar @case % 2, 1, "odd number of case ranges" );

sub in_range {    # lower only
    my ($e) = @_;
    return
        sprintf( "\$wc >= %u && \$wc <= %u + %u", $e->[0], $e->[0], $e->[2] );
}

sub lower {
    my ($m) = @_;
    return sprintf( "\$wc < %u", $m->[0] );
}

sub result {
    my ($m) = @_;
    return sprintf( "%d + (\$wc - %u)", $m->[0] + $m->[1], $m->[0] );
}

# Tree format: [mid, left_subtree, right_subtree] or scalar leaf index
# The tree organizes the ORDER of range checks.
# Each node checks if wc matches:
#   - If yes (in range), return 1 immediately
#   - If no (not in range), continue with (left subtree OR right subtree)
#
# Leaf nodes: just check for found and return result
# Expanding to: x < m ? (l) : (x > m ? (r) : m-value)
# with l and r being subtrees recursively expanded.
# [4, [2, 1, 3], [6, 5]]
# => (x < a[4] ? (x < a[2] ? a[1] : a[3]) : (x < a[6] ? a[5] : x))
sub print_tree {
    my ( $tree, $case, $lvl ) = @_;
    return "\$wc" unless defined $tree;
    my $ident = "\n          ";
    $ident .= "  " x $lvl;
    if ( ref $tree ) {

        # wc < m ? (left) : (wc > m ? (right) : result)
        my $m = $tree->[0];
        my $l = $tree->[1];
        my $r = $tree->[2];
        if ( ref $m ) {
            return
                  ( $lvl ? $ident : "" )
                . print_tree( $m, $case, $lvl + 1 ) . " ? "
                . lower( $case->[$m] ) . "   ?"
                . print_tree( $l, $case, $lvl + 1 ) . "   : "
                . print_tree( $r, $case, $lvl + 1 )
                . " : \$wc";
        }
        else {
            return
                  ( $lvl ? $ident : "" )
                . lower( $case->[$m] ) . " ? "
                . print_tree( $l, $case, $lvl + 1 ) . " : "
                . in_range( $case->[$m] ) . " ? "
                . result( $case->[$m] ) . " : "
                . print_tree( $r, $case, $lvl + 1 );
        }
    }
    else {
        # Leaf node: check match and return result
        return
              in_range( $case->[$tree] ) . " ? "
            . result( $case->[$tree] )
            . " : \$wc";
    }
}

sub gen_expr {
    my ( $name, $case, $off ) = @_;
    my $expr = sprintf( "sub %s {\n  my \$wc = shift;\n", $name );
    $expr
        .= "  return "
        . print_tree( ternary_tree( 0, scalar @$case - 1 ), $case, 0 )
        . ";\n}";

    # my $num_lines = () = $expr =~ /\n/g;
    # The generated code has 3 lines regardless of @case size
    # is( $num_lines, 5 + scalar @case, "lines of $name" );
    eval $expr;
    if ( $ENV{TEST_VERBOSE} ) {
        diag "generated search tree code:";
        diag $expr;
    }

    my $sz_case = scalar @$case;
    my $fn      = "c-if-range-$name.c";
    open my $fh, ">", $fn or die "$fn: $!";
    printf $fh <<"EOF";
#include <stdio.h>
static const int casemaps[$sz_case][3] = {
EOF
    for (@$case) {
        printf $fh "  {%d, %d, %d},\t/* (%d..%d) -> (%d..%d) */\n", $_->[0],
            $_->[1], $_->[2],
            $_->[0], $_->[0] + $_->[2], $_->[0] + $_->[1],
            $_->[0] + $_->[1] + $_->[2];
    }
    printf $fh "};\n",                    $name;
    printf $fh "int %s(unsigned wc) {\n", $name;
    my $c
        = "  return "
        . print_tree( ternary_tree( 0, scalar @$case - 1 ), $case, 0 )
        . ";\n}\n";

    $c =~ s/\$wc/wc/g;
    $c =~ s/ \n/\n/g;
    printf $fh $c;
    print $fh <<"EOF";
int main() {
  int i, len, j = 0;
  /* these must be found */
  for (i = 0; i < $sz_case; i++) {
    for (len = 0; len < casemaps[i][2]; len++) {
      unsigned wc = casemaps[i][0] + len;
      if ($name(wc) == wc) {
        printf("not ok %u - not found $name(%u)\\n", $off + j++, wc);
        return 1;
      }
      else
        printf("ok %u - found $name(%u)\\n", $off + j++, wc);
    }
  }
  /* these not */
EOF
    for my $wc ( 0 .. $max_case ) {
        next if find_case( $wc, $case );
        print $fh <<"EOF";
  if ($name($wc) != $wc) {
    printf("not ok %u - $name(%u) found\\n", $off + j++, $wc);
    return 1;
  }
  else
    printf("ok %u - $name(%u) not found\\n", $off + j++, $wc);
EOF
        $off++;
    }
    print $fh <<'EOF';
  return 0;
}
EOF
    close $fh;
    my ($exe) = ( $fn =~ /^(.+)\.c$/ );
    my $args = "-g $fn -o $exe";
    print "running $cc $args\n" if $ENV{TEST_VERBOSE};
    my $output = `$cc $args`;

    if ( $? != 0 ) {
        diag "cc failed: $output";

        # unlink ($fn, $exe) unless $ENV{TEST_VERBOSE};
        # return 0;
    }
    print `./$cc`;
    ok( $? != 0, $fn );
    unlink( $fn, $exe ) unless $ENV{TEST_VERBOSE};
    return $expr;
}

my $odd = gen_expr( "search_odd", \@case, 2 );

#for ( 1 .. $N ) {
#    my $wc = int( rand( $max_case + 2 ) );
#    is( search_odd($wc), find_case( $wc, \@case ), "wc=$wc" );
#}

pop @case;
is( scalar @case % 2, 0, "even number of case ranges" );
my $even = gen_expr( "search_even", \@case, 3 + $N );

#for ( 1 .. $N ) {
#    my $wc = int( rand( $max_case + 2 ) );
#    is( search_even($wc), find_case( $wc, \@case ), "wc=$wc" );
#}
