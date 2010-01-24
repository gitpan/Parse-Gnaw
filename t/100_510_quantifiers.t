

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my $capture='nomatch';

$grammar = match(get(\$capture, some('a', 'b')), CC('a'));


ok($grammar->('123 oieur 912039 ababababab fdghgh gf')==1, "1 match");

ok($capture eq 'ababababab', "2 got");

ok($grammar->('123 oieur 912039 axbxaxbxaxbxaxbxaxb fdghgh gf')==0, "3 no match");

ok($capture eq 'nomatch', "4 no got");

