

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my $grammar;

# testing that we can use "match" function, which is equivalent to regexp m

$grammar = match('howdy', 'pardner');

ok($grammar->('howdy     pardner')==1, "1 match");

ok($grammar->('why howdy there pardner          ')==0, "5 no match");
