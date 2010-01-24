
use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

use Data::Dumper;

my $grammar;





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

ok($GNAW[0] eq 'abcde', "checking index 0");
ok($GNAW[1] eq 'ab',    "checking index 1");
ok($GNAW[2] eq 'a', 	"checking index 2");
ok($GNAW[3] eq 'b', 	"checking index 3");
ok($GNAW[4] eq 'cde', 	"checking index 4");
ok($GNAW[5] eq 'c', 	"checking index 5");
ok($GNAW[6] eq 'd', 	"checking index 6");
ok($GNAW[7] eq 'e', 	"checking index 7");










