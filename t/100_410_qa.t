

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my $capture='random string';

$grammar = match(get(\$capture, qa('apple pear banana')));

ok($grammar->('an apple a day')==1, "1 match");

ok($capture eq 'apple', "2 got");



ok($grammar->('bacon cheeseburger')==0, "3 match");

ok($capture eq 'random string', "4 no got");



ok($grammar->('a pear a day')==1, "5 match");

ok($capture eq 'pear', "6 got");

ok($grammar->('a banana a day')==1, "7 match");

ok($capture eq 'banana', "8 got");


ok($grammar->('bacon cheeseburger')==0, "9 match");

ok($capture eq 'random string', "10 no got");
