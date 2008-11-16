

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my $capture='nomatch';

$grammar = match(get(\$capture, g([5,8], 'a', 'b')));


ok($grammar->('912039 ababababab fdghgh')==1, "1 match");

ok($capture eq 'ababababab', "2 got");


ok($grammar->('912039 abababab fdghgh')==0, "3 no match");

ok($capture eq 'nomatch', "4 no got");


ok($grammar->('912039 abababababababababababab fdghgh')==1, "5 match");

ok($capture eq 'abababababababab', "6 got max");


