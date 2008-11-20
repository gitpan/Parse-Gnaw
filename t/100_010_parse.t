

use Test::More 'no_plan';

use lib 'lib';

use Parse::Gnaw;

my $grammar;

# testing that we can call same grammar over and over with different strings and still work.

$grammar = parse('hello', 'world');
ok($grammar->('hello     world')==1, "1 match");
ok($grammar->('hello     world')==1, "2 match");
ok($grammar->('hello     world')==1, "3 match");
ok($grammar->('hello     world')==1, "4 match");

ok($grammar->('hello          ')==0, "5 no match");

ok($grammar->('hello     world')==1, "6 match");

ok($grammar->('hello          ')==0, "7 no match");

ok($grammar->('hello     world')==1, "8 match");

ok($grammar->('hello          ')==0, "9 no match");

ok($grammar->('hello     world')==1, "10 match");

ok($grammar->('hello          ')==0, "11 no match");

ok($grammar->('hello     world')==1, "12 match");

ok($grammar->('hello          ')==0, "13 no match");
ok($grammar->('hello          ')==0, "14 no match");
ok($grammar->('hello          ')==0, "15 no match");
ok($grammar->('hello          ')==0, "16 no match");


