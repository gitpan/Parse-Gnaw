

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my @capture;


sub greedya {get(\@capture, greedy([1],'a'))}
sub thriftya {get(\@capture, thrifty([1],'a'))}




$grammar = match( greedya, greedya );

ok($grammar->('123 aaaaaaaa 456')==1, "1 match");

ok($capture[0] eq 'aaaaaaa', "2 got");
ok($capture[1] eq 'a', "3 got");
ok(scalar(@capture)==2, "4 size");




$grammar = match( thriftya, greedya );

ok($grammar->('123 aaaaaaaa 456')==1, "11 match");

ok($capture[0] eq 'a', "12 got");
ok($capture[1] eq 'aaaaaaa', "13 got");
ok(scalar(@capture)==2, "14 size");





