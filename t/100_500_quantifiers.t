

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my $capture='42';

$grammar = match(get(\$capture, some('a')));

ok($grammar->('123 oieur 912039 a fdghgh gf')==1, "1 match");

ok($capture eq 'a', "2 got");


ok($grammar->('123 oieur 912039 aaaaaaaa fdghgh gf')==1, "3 match");

ok($capture eq 'aaaaaaaa', "4 got");


ok($grammar->('123 oieur 912039 fdghgh gf')==0, "5 no match");

ok($capture eq '42', "6 no got");


ok($grammar->('a')==1, "7 match");

ok($capture eq 'a', "8 got");
