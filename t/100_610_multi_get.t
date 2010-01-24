
use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

use Data::Dumper;

my $grammar;

# this test confirms that pushes into array happen from left to right
# want it to behave similar to the way capturing parens work in regexps.

my @cap;

$grammar = parse( 
	get(\@cap,
		get(\@cap, 
			get(\@cap, thing), get(\@cap, thing) 
		),
		get(\@cap, 
			get(\@cap, thing), get(\@cap, thing), get(\@cap, thing) 
		),
	) 

);

$grammar->('abcdefghijklmnop');

#print Dumper \@cap;

ok($cap[0] eq 'abcde', 	"checking index 0");
ok($cap[1] eq 'ab',    	"checking index 1");
ok($cap[2] eq 'a', 	"checking index 2");
ok($cap[3] eq 'b', 	"checking index 3");
ok($cap[4] eq 'cde', 	"checking index 4");
ok($cap[5] eq 'c', 	"checking index 5");
ok($cap[6] eq 'd', 	"checking index 6");
ok($cap[7] eq 'e', 	"checking index 7");


