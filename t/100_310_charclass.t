

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my $grammar;

# testing that we can use "match" function, which is equivalent to regexp m

my $vowel='x';

$grammar = match('b', get(\$vowel, cc('aeiou')), 'b');

ok($grammar->('hello bob !')==1, "1 match");

ok($vowel eq 'o', "2 got");

ok($grammar->('hello alice !')==0, "3 match");

ok($vowel eq 'x', "4 no got");

ok($grammar->('hello bab !')==1, "5 match");

ok($vowel eq 'a', "6 got");
