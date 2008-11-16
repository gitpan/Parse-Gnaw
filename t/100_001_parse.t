

use Test::More 'no_plan';

use Parse::Gnaw;

my $grammar;

$grammar = parse('hello', 'world');
ok($grammar->('hello     world')==1, "match");

