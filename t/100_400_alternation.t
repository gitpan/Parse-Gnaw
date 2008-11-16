

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my $capture='nothing';

$grammar = match(get(\$capture, a(['hello', 'world'], ['howdy', 'partner'])));

ok($grammar->('why  hello   world how are you')==1, "1 match");

ok($capture eq 'hello   world', "2 got");


ok($grammar->('why  hello you world howdy there partner how are you')==0, "3 no match");

ok($capture eq 'nothing', "4 not got");


ok($grammar->('why  hello you world howdy   partner how are you')==1, "5 match");

ok($capture eq 'howdy   partner', "6 got");



ok($grammar->('d')==0, "7 no match");

ok($capture eq 'nothing', "8 not got");


