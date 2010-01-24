

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my $capture='nomatch';

$grammar = match(get(\$capture, 'x', greedy([3,3], 'a', 'b'), 'y'));


ok($grammar->('123 x ababab y 456')==1, "1 match");

ok($capture eq 'x ababab y', "2 got");


ok($grammar->('123 x abababab y 456')==0, "3 no match");

ok($capture eq 'nomatch', "4 no got");

ok($grammar->('123 x abab y 456')==0, "5 no match");

ok($capture eq 'nomatch', "6 no got");


