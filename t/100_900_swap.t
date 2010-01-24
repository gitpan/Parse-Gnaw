
use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

use Data::Dumper;

my $grammar;


my $input = "please call 555-1212 for more details";
ok(swap(greedy([1],dgt),'-',greedy([1],dgt), sub{return "***".shift(@_)."***";}) -> ($input)==1, "checking match was found");
ok($input eq 'please call ***555-1212*** for more details', "checking substitution/swap took place");
