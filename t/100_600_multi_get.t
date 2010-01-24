
use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

use Data::Dumper;

my $grammar;


my ($g1, $g2, $g3, $g4, $g5, $g6, $g7, $g8);

$grammar = parse( 
	get(\$g8,
		get(\$g1, get(\$g2, thing), get(\$g3, thing) ),
		get(\$g4, get(\$g5, thing), get(\$g6, thing), get(\$g7, thing) ),
	) 

);

$grammar->('abcdefghijklmnop');

ok($g2 eq 'a', "g2");
ok($g3 eq 'b', "g3");
ok($g1 eq 'ab', "g1");
ok($g5 eq 'c', "g5");
ok($g6 eq 'd', "g6");
ok($g7 eq 'e', "g7");
ok($g4 eq 'cde', "g4");
ok($g8 eq 'abcde', "g8");

