

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my $capture='';


sub greedya {get(\@capture, greedy([1],'a'))}
sub thriftya {get(\@capture, thrifty([1],'a'))}




$grammar = match(  get(\$capture, 'b', thrifty([3,3],'a'), 'c') );

ok($grammar->('baaac')==1, "1 match");

ok($capture eq 'baaac', "2 got");



ok($grammar->('baaaac')==0, "3 no match");

ok($capture eq '', "4 no got");



ok($grammar->('baac')==0, "5 no match");

ok($capture eq '', "6 no got");



