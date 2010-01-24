

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

my $grammar;

# testing that we can use "match" function, which is equivalent to regexp m

$grammar = match('hello', 'world');

ok($grammar->('hello     world')==1, "1 match");

ok($grammar->('why hello there world          ')==0, "5 no match");

ok($grammar->('hey hello     world how are you')==1, "6 match");

ok($grammar->('the best hello in the whole world there  ')==0, "7 no match");

ok($grammar->('I said hello     world and I mean it')==1, "8 match");

ok($grammar->('hello')==0, "9 no match");

ok($grammar->('you say tomato, I say hello     world. lets call the whole thing off')==1, "10 match");

ok($grammar->('world')==0, "11 no match");

ok($grammar->('one for the money two for the show hello     world and away we go.')==1, "12 match");

ok($grammar->('hello          ')==0, "13 no match");
ok($grammar->('hello          ')==0, "14 no match");
ok($grammar->('hello          ')==0, "15 no match");
ok($grammar->('hello          ')==0, "16 no match");


