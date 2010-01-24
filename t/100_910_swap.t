
use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

use Data::Dumper;

my $grammar;


my $input = "hello Alice ! How are you?";
ok(swap('Alice', sub{return "Bob";}) -> ($input)==1, "checking match was found");
ok($input eq 'hello Bob ! How are you?', "checking substitution/swap took place");
