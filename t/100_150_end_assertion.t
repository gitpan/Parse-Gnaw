

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

# you can create a grammar and apply it to a text in one line

$grammar = parse('hello', 'world', end);

ok($grammar->('hello    world')==1, "match");
ok($grammar->('a  hello    world')==0, "no match");
ok($grammar->('hello    world x')==0, "no match");
