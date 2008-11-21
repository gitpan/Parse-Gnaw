
use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

use Data::Dumper;

my $grammar;

# would like to export $c1 $c2 $c3 type variables.
# doesn't seem to work though.





$grammar = parse( 
	c(
		c( 
			c(thing),c(thing) 
		),
		c( 
			c(thing), c(thing), c(thing) 
		),
	) 

);

$grammar->('abcdefghijklmnop');

#print Dumper \@GNAW;

ok($c1 eq 'abcde', 	"checking c1 ");
ok($c2 eq 'ab',    	"checking c2 ");
ok($c3 eq 'a', 		"checking c3 ");
ok($c4 eq 'b', 		"checking c4 ");
ok($c5 eq 'cde', 	"checking c5 ");
ok($c6 eq 'c', 		"checking c6 ");
ok($c7 eq 'd', 		"checking c7 ");
ok($c8 eq 'e', 		"checking c8 ");










