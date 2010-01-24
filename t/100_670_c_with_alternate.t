
use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

use Data::Dumper;

my $grammar;

# showing numbered variables are based off of what was captured,
# not the number of parenthesis in grammar.

$grammar = parse( 
	a(  
		['hello', c('world'), 'my', 'name', 'is', c(something), '.'],
		['howdy', c(something), '.']
	) 

);

ok($grammar->('hello world my name is Alice.')==1, "1 match");

ok($c1 eq 'world', 'c1 is world');
ok($c2 eq 'Alice', 'c2 is alice');

ok($grammar->('howdy Bob.')==1, "1 match");

ok($c1 eq 'Bob', 'c1 is Bob');

print "c1 is '$c1'\n";

