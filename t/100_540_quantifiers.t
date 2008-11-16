

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

# initial values in array refs get wiped out 
my @capture=('','','','','','');


sub greedya {get(\@capture, some('a'))}




$grammar = match( greedya, greedya );

ok($grammar->('123 aaaaaaaa 456')==1, "1 match");

ok($capture[0] eq 'aaaaaaa', "2 got");
ok($capture[1] eq 'a', "3 got");
ok(scalar(@capture)==2, "4 size");






$grammar = match( greedya, greedya, greedya );

ok($grammar->('123 aaaaaaaa 456')==1, "10 match");

ok($capture[0] eq 'aaaaaa', "11 got");
ok($capture[1] eq 'a', "12 got");
ok($capture[2] eq 'a', "13 got");
ok(scalar(@capture)==3, "14 size");






$grammar = match( greedya, greedya, greedya, greedya );

ok($grammar->('123 aaaaaaaa 456')==1, "20 match");

ok($capture[0] eq 'aaaaa', "21 got");
ok($capture[1] eq 'a', "22 got");
ok($capture[2] eq 'a', "23 got");
ok($capture[3] eq 'a', "23 got");
ok(scalar(@capture)==4, "24 size");






