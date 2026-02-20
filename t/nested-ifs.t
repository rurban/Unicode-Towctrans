# -*- perl -*-
use Test::More import => [qw( is is_deeply plan diag )];
my $N = 100;
plan tests => $N + 5;

# copied verbatim from the script.
# here we skip the first index
sub binary_search_indices {
    my ($n) = @_;
    return () if $n <= 1;

    my @indices;
    my @queue = ( [ 1, $n - 1 ] );

    while (@queue) {
        my ( $lo, $hi ) = @{ shift @queue };
        my $mid = int( ( $lo + $hi ) / 2 );
        push @indices, $mid;

        push @queue, [ $lo, $mid - 1 ] if $lo < $mid;
        push @queue, [ $mid + 1, $hi ] if $mid < $hi;
    }

    return @indices;
}

is_deeply( [ binary_search_indices(2) ], [1],            "n=2" );
is_deeply( [ binary_search_indices(3) ], [ 1, 2 ],       "n=3" );
is_deeply( [ binary_search_indices(4) ], [ 2, 1, 3 ],    "n=4" );
is_deeply( [ binary_search_indices(5) ], [ 2, 1, 3, 4 ], "n=5" );

diag "generated excl array:";
my @excl = ( [ 0, 30 ] );
for ( 0 .. 10 ) {
    my $last = $excl[-1][1];
    my $f    = $last + 1 + int( rand(32) );
    my $n    = $f + 1 + int( rand(32) );
    push @excl, [ $f, $n ];
    diag( sprintf( "[ 0x%x, 0x%x ]", $f, $n ) );
}

sub find_excl {
    my ( $wc, $excl ) = @_;
    for my $e (@$excl) {
        return 1 if $wc >= $e->[0] && $wc <= $e->[1];
    }
    return 0;
}

sub search { }
my $expr = "sub search {\n  my \$wc = shift;\n  if (";
# copied from the generated C source
my $j    = 0;
for my $i ( binary_search_indices( scalar @excl ) ) {
    my $e = $excl[$i];
    $expr .= sprintf( " \$wc - 0x%x <= 0x%x - 0x%x", $e->[0], $e->[1],
        $e->[0] );
    if ( $j == $#excl - 1 ) {
        $expr .= " : 0" if $j % 2;
    }
    elsif ( $j % 2 ) {
        $expr .= " :";
    }
    else {
        $expr .= " ?";
    }
    $j++;
}
$expr .= ")\n  { return 1 } else { return 0 }}\n";
eval $expr;
diag $expr;

for ( 0 .. $N ) {
    my $wc = int( rand(1000) );
    is( find_excl( $wc, \@excl ),
        search($wc), "wc=0x" . sprintf( "%x", $wc ) );
}
