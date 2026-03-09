#!/usr/bin/env perl -s
use Config qw( %Config );
use Test::More import => [qw( diag is is_deeply ok plan )];

# use Data::Dump qw( dump );
BEGIN {
    chdir "t" if -e "t/test_towctrans.c";
}

our $d;
my $DEV = $d;
my $N   = $DEV ? 10 : 500;    # Number of random lookup rounds.
my $M   = $DEV ? 6  : 10;     # Length of generated @pairs. Must be even.
die if $M % 2;

my $is_mswin = $^O eq 'MSWin32';
my $cc       = $Config{cc};
my $exe      = "t_c-if" . ( $^O eq 'MSWin32' ? ".exe" : "" );
my $prefix   = $^O eq 'MSWin32' ? "" : "./";

plan tests => 3 + ( ( $N + 1 ) * 2 );

# needed to search for pairs, not ranges.

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

my @pairs = ( [ 0x49, 0x131 ] );
if ( $ENV{TEST_VERBOSE} ) {
    diag "generated pairs array:";
    diag(
        sprintf( "%u: [ %u, %u ]", $#pairs, $pairs[0]->[0], $pairs[0]->[1] )
    );
}
for ( 1 .. $M ) {    # odd array
    my $last = $pairs[-1][0];
    my $f    = $last + 1 + int( rand(32) );
    my $n
        = $f + ( int( rand(2) ) % 2 ? -int( rand(128) ) : int( rand(128) ) );
    $n++ unless $n;    # 0 is our failure
    push @pairs, [ $f, $n ];
    diag( sprintf( "%u: [ %u, %d ]", $#pairs, $f, $n ) )
        if $ENV{TEST_VERBOSE};
}
my $max_pairs = $pairs[-1][1];

sub find_pairs {
    my ( $wc, $pairs ) = @_;
    for my $p (@$pairs) {
        return $p->[1] if $wc == $p->[0];
    }
    return 0;
}

sub search_even { }
sub search_odd  { }

is( scalar @pairs % 2, 1, "odd number of pairs ranges" );

sub equal {
    my ($e) = @_;
    return sprintf( "\$wc == %u", $e->[0] );
}

sub lower {
    my ($e) = @_;
    return sprintf( "\$wc < %u", $e->[0] );
}

sub higher {
    my ($e) = @_;
    return sprintf( "\$wc > %u", $e->[0] );
}

sub value {
    my ( $i, $pairs ) = @_;
    return $pairs->[$i][1];
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
    my ( $tree, $pairs, $lvl ) = @_;
    return "0" unless defined $tree;
    my $ident = "\n          ";
    $ident .= "  " x $lvl;
    if ( ref $tree ) {

        # wc < m ? (l) : (wc > m ? (r) : m[1])
        my $m = $tree->[0];
        my $l = $tree->[1];
        my $r = $tree->[2];
        if ( ref $m ) {
            return
                  ( $lvl ? $ident : "" )
                . print_tree( $m, $pairs, $lvl + 1 ) . " ? "
                . lower( $pairs->[$m] ) . "   ? "
                . print_tree( $l, $pairs, $lvl + 1 ) . "   : "
                . print_tree( $r, $pairs, $lvl + 1 ) . " : 0";
        }
        else {
            return
                  ( $lvl ? $ident : "" )
                . lower( $pairs->[$m] ) . " ? "
                . print_tree( $l, $pairs, $lvl + 1 ) . " : "
                . equal( $pairs->[$m] ) . " ? "
                . $pairs->[$m][1] . " : "
                . print_tree( $r, $pairs, $lvl + 1 );
        }
    }
    else {
        # Leaf node: check match and return result
        return equal( $pairs->[$tree] ) . " ? " . $pairs->[$tree][1] . " : 0";
    }
}

sub gen_expr {
    my ( $name, $pairs, $off ) = @_;
    my $expr = sprintf( "sub %s {\n  my \$wc = shift;\n", $name );
    $expr
        .= "  return "
        . print_tree( ternary_tree( 0, scalar @$pairs - 1 ), $pairs, 0 )
        . ";\n}";

    # my $num_lines = () = $expr =~ /\n/g;
    # The generated code has 3 lines regardless of @pairs size
    # is( $num_lines, 5 + scalar @pairs, "lines of $name" );
    eval $expr;
    if ( $ENV{TEST_VERBOSE} ) {
        diag "generated search tree code:";
        diag $expr;
    }

    my $sz_pairs = scalar @$pairs;
    my $fn       = "c-if-tree-$name.c";
    open my $fh, ">", $fn or die "$fn: $!";
    printf $fh <<"EOF";
#include <stdio.h>
static const int pairs[$sz_pairs][2] = {
EOF
    for (@$pairs) {
        printf $fh "  {%d, %d},\n", $_->[0], $_->[1];
    }
    printf $fh "};\n",               $name;
    printf $fh "int %s(int wc) {\n", $name;
    my $c
        = "  return "
        . print_tree( ternary_tree( 0, scalar @$pairs - 1 ), $pairs, 0 )
        . ";\n}\n";

    $c =~ s/\$wc/wc/g;
    printf $fh $c;
    print $fh <<"EOF";
int main() {
  /* these must be found */
  for (int i = 0; i < $sz_pairs; i++) {
    if ($name(pairs[i][0]) != pairs[i][1]) {
      printf("not ok %u\\n", i + 1 + $off);
      return 1;
    }
    else
      printf("ok %u\\n", i + 1 + $off);
  }
  /* these not */
EOF
    $off = 2 + $sz_pairs + $off;
    for my $cand ( 0 .. 100 ) {
        next if find_pairs( $cand, $pairs );
        print $fh <<"EOF";
  if ($name($cand)) {
    printf("not ok %u - search(%u)\\n", $off, $cand);
    return 1;
  }
  else
    printf("ok %u\\n", $off);
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

        #unlink ($fn, $exe) unless $ENV{TEST_VERBOSE};
        #return 0;
    }
    print `./$cc`;
    ok( $? != 0, $fn );
    unlink( $fn, $exe ) unless $ENV{TEST_VERBOSE};
    return $expr;
}

my $odd = gen_expr( "search_odd", \@pairs, 2 );

for ( 1 .. $N ) {
    my $wc = int( rand( $max_pairs + 2 ) );
    is( search_odd($wc), find_pairs( $wc, \@pairs ), "wc=$wc" );
}

pop @pairs;
is( scalar @pairs % 2, 0, "even number of pairs ranges" );
my $even = gen_expr( "search_even", \@pairs, 3 + $N );

for ( 1 .. $N ) {
    my $wc = int( rand( $max_pairs + 2 ) );
    is( search_even($wc), find_pairs( $wc, \@pairs ), "wc=$wc" );
}
