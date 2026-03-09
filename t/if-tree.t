#!/usr/bin/env perl -s
use Test::More import => [qw( diag is is_deeply plan )];

# use Data::Dump qw( dump );

our $d;
my $DEV = $d;
my $N   = $DEV ? 10 : 500;    # Number of random lookup rounds.
my $M   = $DEV ? 6  : 10;     # Length of generated @excl. Must be even.
die if $M % 2;
plan tests => 6 + 2 + ( $N * 2 );

# needed to search for pairs, not ranges.

# copied verbatim from the script.
# here we skip the first index
# for 0 1 2 3 4 5 6
# 0 || [4 [2 1 3] [6 5]]
# ie (0 || (4 ? (2 ? 1 : false) : (6 ? 5 : false))
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

is_deeply( ternary_tree( 1, 2 ), [ 2, 1 ], "n=2" );
is_deeply( ternary_tree( 1, 3 ), [ 2, 1, 3 ], "n=3" );
is_deeply( ternary_tree( 1, 4 ), [ 3, [ 2, 1 ], 4 ],        "n=4" );
is_deeply( ternary_tree( 1, 5 ), [ 3, [ 2, 1 ], [ 5, 4 ] ], "n=5" );

my $n6 = ternary_tree( 1, 6 ), [ 4, [ 2, 1, 3 ], [ 6, 5 ] ];
is_deeply( $n6, [ 4, [ 2, 1, 3 ], [ 6, 5 ] ], "n=6" );
is_deeply( ternary_tree( 1, 7 ), [ 4, [ 2, 1, 3 ], [ 6, 5, 7 ] ], "n=7" );

# diag dump($n6);

my @excl = ( [ 0, 30 ] );
if ( $ENV{TEST_VERBOSE} ) {
    diag "generated excl array:";
    diag( sprintf( "%u: [ %u, %u ]", $#excl, $excl[0]->[0], $excl[0]->[1] ) );
}
for ( 1 .. $M ) {    # odd array
    my $last = $excl[-1][1];
    my $f    = $last + 1 + int( rand(32) );
    my $n    = $f + 1 + int( rand(32) );
    push @excl, [ $f, $n ];
    diag( sprintf( "%u: [ %u, %u ]", $#excl, $f, $n ) ) if $ENV{TEST_VERBOSE};
}
my $max_excl = $excl[-1][1];

sub find_excl {
    my ( $wc, $excl ) = @_;
    for my $e (@$excl) {
        return 1 if $wc >= $e->[0] && $wc <= $e->[1];
    }
    return 0;
}

sub search_even { }
sub search_odd  { }

is( scalar @excl % 2, 1, "odd number of excl ranges" );

sub print_expr {
    my ($e) = @_;
    return sprintf( "\$wc >= %u && \$wc <= %u", $e->[0], $e->[1] );
}

# Tree format: [mid, left_subtree, right_subtree] or scalar leaf index
# The tree organizes the ORDER of range checks.
# Each node checks if wc is in its range:
#   - If yes (in range), return 1 immediately
#   - If no (not in range), continue with (left subtree OR right subtree)
#
# Leaf nodes: just check their range and return result
# Internal nodes: check range, if true return 1, else check (left || right)
# [4, [2, 1, 3], [6, 5]] => (4 ? (2 ? 1 : 3) : (6 ? 5 : 0))
sub print_tree {
    my ( $tree, $excl, $lvl ) = @_;
    return "0" unless $tree;
    my $ident = "\n          ";
    $ident .= "  " x $lvl;

    if ( ref $tree ) {
        my $m = $tree->[0];
        my $l = $tree->[1];
        my $r = $tree->[2];

        # Check midpoint range first
        my $mid_check = print_expr( $excl->[$m] );

        # Build left subtree expression
        my $left_expr;
        if ( ref $l ) {
            $left_expr = print_tree( $l, $excl, $lvl + 1 );
        }
        elsif ($l) {
            $left_expr
                = "$ident( " . print_expr( $excl->[$l] ) . " ? 1 : 0 )";
        }
        else {
            $left_expr = "0";
        }

        # Build right subtree expression
        my $right_expr;
        if ( ref $r ) {
            $right_expr = print_tree( $r, $excl, $lvl + 1 );
        }
        elsif ($r) {
            $right_expr
                = "$ident( " . print_expr( $excl->[$r] ) . " ? 1 : 0 )";
        }
        else {
            $right_expr = "0";
        }

        # Combine: mid_check ? 1 : (left || right)
        my $expr = "";
        $expr .= $ident unless $lvl;
        if ( $left_expr eq "0" && $right_expr eq "0" ) {
            $expr .= "$mid_check ? 1 : 0";
        }
        elsif ( $right_expr eq "0" ) {
            $expr .= "$mid_check ? 1 :$ident( $left_expr )";
        }
        elsif ( $left_expr eq "0" ) {
            $expr .= "$mid_check ? 1 :$ident( $right_expr )";
        }
        else {
            $expr .= "$mid_check ? 1 :$ident( $left_expr || $right_expr )";
        }

        return $expr;
    }
    else {
        # Leaf node: check range and return result
        return "( " . print_expr( $excl->[$tree] ) . " ? 1 : 0 )";
    }
}

sub gen_expr {
    my ( $name, $excl ) = @_;
    my $expr = sprintf( "sub %s {\n  my \$wc = shift;\n", $name );

    # Check index 0 separately, then use tree for indices 1..n-1
    my $tree_expr
        = print_tree( ternary_tree( 1, scalar @$excl - 1 ), $excl, 0 );
    $expr
        .= "  return (" . print_expr( $excl->[0] ) . ") || ($tree_expr);\n}";

    # my $num_lines = () = $expr =~ /\n/g;
    # The generated code has 3 lines regardless of @excl size
    # is( $num_lines, 5 + scalar @excl, "lines of $name" );
    eval $expr;
    if ( $ENV{TEST_VERBOSE} ) {
        diag "generated search tree code:";
        diag $expr;
    }
    return $expr;
}

my $odd = gen_expr( "search_odd", \@excl );

for ( 1 .. $N ) {
    my $wc = int( rand( $max_excl + 2 ) );
    is( find_excl( $wc, \@excl ), search_odd($wc), "wc=$wc" );
}

pop @excl;
is( scalar @excl % 2, 0, "even number of excl ranges" );
my $even = gen_expr( "search_even", \@excl );

for ( 1 .. $N ) {
    my $wc = int( rand( $max_excl + 2 ) );
    is( find_excl( $wc, \@excl ), search_even($wc), "wc=$wc" );
}
