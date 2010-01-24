

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my $grammar;

# testing that we can use "match" function, which is equivalent to regexp m

my $greeting='init';

$grammar = match(get(\$greeting, ql('hello world')));

ok($grammar->('hello     world')==1, "1 match");

ok($greeting eq 'hello     world', "2 got");


ok($grammar->('hello  there   world')==0, "3 no match");

ok($greeting eq 'init', "4 no got");
