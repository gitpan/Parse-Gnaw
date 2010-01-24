

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

# you can create a grammar and apply it to a text in one line

	

	$grammar = match('x', id, 'y');

	# skip after x, no space between literals till skipping turned back on.
	ok($grammar->('x helloworld  y')==1, "1 match found");

	# this doesn't match because of space between x and hello
	ok($grammar->('x hello world  y')==0, "2 match not found");


	my $gotten='';

	$grammar = match('x', id(\$gotten), 'y');

	# skip after x, no space between literals till skipping turned back on.
	ok($grammar->('x helloworld  y')==1, "1 match found");
	ok($gotten eq 'helloworld', "check gotten");

	# this doesn't match because of space between x and hello
	ok($grammar->('x hello world  y')==0, "2 match not found");
	ok($gotten eq '', "check not gotten");

