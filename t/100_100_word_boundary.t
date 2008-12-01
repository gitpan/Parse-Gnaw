

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

# you can create a grammar and apply it to a text in one line


	$grammar = match(bb, 'alice', bb);

	ok($grammar->('alice Bob Charlie')==1, "match found");
	ok($grammar->('Bob alice Charlie')==1, "match found");
	ok($grammar->('Bob Charlie alice')==1, "match found");

	ok($grammar->('Bob alice(42) Charlie')==1, "match found");
	ok($grammar->('Bob (71)alice Charlie')==1, "match found");

	ok($grammar->('Bob bobalice Charlie')==0, "match not found");
	ok($grammar->('Bob alicecharlie Charlie')==0, "match not found");
	ok($grammar->('Bob bobalicecharlie Charlie')==0, "match not found");
