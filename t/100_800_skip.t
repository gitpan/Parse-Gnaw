

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

# you can create a grammar and apply it to a text in one line

	$grammar = match('x', noskip('hello', 'world'), 'y');

	# turn off skipping after x, no space between literals till skipping turned back on.
	ok($grammar->('xhelloworld  y')==1, "1 match found");

	# this doesn't match because of space between x and hello
	ok($grammar->('x  helloworld  y')==0, "2 match not found");

	# this doesn't match because of space between x and hello
	ok($grammar->('xhello world  y')==0, "3 match not found");


