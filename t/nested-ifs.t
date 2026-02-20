#!/usr/bin/env perl -s
use Test::More import => [qw( is is_deeply plan diag )];
use Data::Dump qw( dump );
our $d;
my $DEV = $d;
my $N   = $DEV ? 10 : 500;    # Number of random lookup rounds.
my $M   = $DEV ? 6  : 10;     # Length of generated @excl. Must be even.
die if $M % 2;
plan tests => 6 + 2 + 2 + ( $N * 2 );

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

# my $n6 = ternary_tree( 1, 6 ), [ 4, [ 2, 1, 3 ], [ 6, 5 ] ];
# is_deeply( $n6, "n=6" );
is_deeply( ternary_tree( 1, 6 ), [ 4, [ 2, 1, 3 ], [ 6, 5 ] ], "n=6" );
is_deeply( ternary_tree( 1, 7 ), [ 4, [ 2, 1, 3 ], [ 6, 5, 7 ] ], "n=7" );

# diag dump($n6);

diag "generated excl array:";
my @excl = ( [ 0, 30 ] );
diag( sprintf( "%u: [ %u, %u ]", $#excl, $excl[0]->[0], $excl[0]->[1] ) );
for ( 1 .. $M ) {    # odd array
    my $last = $excl[-1][1];
    my $f    = $last + 1 + int( rand(32) );
    my $n    = $f + 1 + int( rand(32) );
    push @excl, [ $f, $n ];
    diag( sprintf( "%u: [ %u, %u ]", $#excl, $f, $n ) );
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
    return sprintf( "\$wc - %u <= %u - %u", $e->[0], $e->[1], $e->[0] );
}

# [4, [2, 1, 3], [6, 5]] => (4 ? (2 ? 1 : 3) : (6 ? 5 : 0))
sub print_tree {
    my ( $tree, $excl, $lvl ) = @_;
    my $expr  = "";
    my $ident = "       ";
    $ident .= "  " x $lvl;
    while (@$tree) {
        my $m = shift @$tree;
        my $l = shift @$tree;
        my $r = shift @$tree;
        $expr .= $ident unless $lvl;
        $expr .= print_expr( $excl->[$m] );
        if ( ref $l ) {
            $expr .= "\n$ident ? ( " . print_tree( $l, $excl, ++$lvl ) . " )";
        }
        elsif ($l) {
            $expr .= "\n$ident ? " . print_expr( $excl->[$l] );
        }
        else {
            die if $r;
        }
        if ( ref $r ) {
            $expr .= "\n$ident : ( " . print_tree( $r, $excl, ++$lvl ) . " )";
        }
        elsif ($r) {
            $expr .= "\n$ident : " . print_expr( $excl->[$r] );
        }
        else {
            $expr .= " : 0";
        }
    }

    #else {
    #    $expr .= ": 0";
    #}
    return $expr;
}

sub gen_expr {
    my ( $name, $excl ) = @_;
    my $expr
        = sprintf(
        "sub %s {\n  my \$wc = shift;\n" . "  if ( \$wc <= %u || (\n",
        $name, $excl->[0]->[1] );

    # copied from the generated C source
    $expr .= print_tree( ternary_tree( 1, scalar @$excl - 1 ), $excl );
    $expr .= " ))\n  { return 1 } else { return 0 }}\n";
    my $num_lines = () = $expr =~ /\n/g;
    is( $num_lines, 3 + scalar @excl, "lines of $name" );
    eval $expr;
    diag "generated search tree code:";
    diag $expr;
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
