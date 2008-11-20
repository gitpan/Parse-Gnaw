
1; 
{ 
package Parse::Gnaw; 
our $VERSION = '0.21'; 
}  
1;

use warnings;
use strict;
use Data::Dumper; 

#use Parse::Gnaw::Decomment;

### die "you just uncommented this die statement";

# these two subroutines are used to turn on/off debugging info
sub GNAWMONITOR_0 {}  

sub GNAWMONITOR  {
	print "MONITOR: "; 

	# if user passes in a message, print it
	if(scalar(@_)){
		my $str=shift(@_);
		chomp($str);
		print $str." ";
	} 

	# print the name of the subroutine that called MONITOR
	my $subname = (caller(1))[3];
	print $subname." ";
	my $linenum = (caller(1))[2];

	# print the name of the subroutine that called this subroutine
	print " called from ";
	my $calledfrom = (caller(2))[3];
	unless(defined($calledfrom)) {
		$calledfrom = '(no one?) ';
	}
	print $calledfrom." ";

	print "line ".$linenum."\n";
}

sub __gnaw__whereami {
	print "whereami\n";
	my $iter=0;
	my @caller = caller($iter++);

	while(scalar(@caller)) {
		# print Dumper \@caller;
		my($pkg,$file,$lnum,$func)=@caller;
		print "whereami sub $func called from $lnum in file $file\n";
		@caller = caller($iter++);
	}

}

sub __gnaw__die {
	my ($message)=@_;
	my $location='';
	$location .= __gnaw__whereami;
	$location .= __gnaw__string_showing_user_current_location_in_text();
	my $string = $message . "\n" . $location;

	die $string;
}

=head1 NAME

Parse::Gnaw - Define a grammar and create a parser by calling nothing but perl subroutines. 

=head1 SYNOPSIS

Gnaw is a perl module which implements full regular expressions and 
full text parsing grammars using nothing but pure perl code limited 
to subroutine closures and basic perl variables such as scalars, 
hashes, arrays, and references.

You write your grammar in pure perl. There is no intermediate 
"parser language" that then gets interpreted into something executable.

When you do a "use Parse::Gnaw", the Gnaw module will import a 
number of functions directly into your namespace. Yes, this is 
completely bad form for normal modules. But this is not a normal 
module. The imported subroutines include regular expression and 
parsing functions for matching, quantifiers, literals, 
alternations, character classes, and so on. You build up your 
grammar by calling these functions. The final call will return 
a code reference. This code reference is your grammar.

When you dereference that grammar, if it is a "match" function, 
then you pass in the string you want to parse.

	use Parse::Gnaw;

	# create the grammar
	my $grammar = match('hello');

	# apply the grammar to a string
	if($grammar->('hello world')) {
		print "match\n";
	} else {
		print "no match";
	}

You can also create the grammar and execute it in one step:

	my $texttoparse = "howdy partner";

	if(match('hello', 'world')->($texttoparse)) {
		print "match\n";
	} else {
		print "no match\n";
	}

Note the above example translated into perls regular expression syntax 
would look something like this:

	my $texttoparse = "howdy partner";

	if($texttoparse =~ m{hello\s*world}) {
		print "match\n";
	} else {
		print "no match\n";
	}


You can build up more complicated grammars fairly easily.
This one looks for a sentence about fruits.

	$grammar = match(ql('I would like to buy'), some('a', qa('banana apple pear peach')));

The "match" function looks for a match to the grammar in the string being parsed.

The "ql" function (quoted literal) allows you to put a sequence of 
literals into a single string. It the splits the string up into 
individual literals much like perls "qw" function does. Then it puts 
them into a grammar sequence for you. This saves you from putting 
quotes around each individual literal.

The "some" function is a quantifier looking for "1 or more" of whatever it surrounds, 
in this case, a sequence of the literal "a" followed by an alternation
of different possible fruit.

The "qa" function (quoted alternation) takes a single string and splits it 
into individual words, also similar to perls "qw" function. The "qa" function
then takes those individual words and creates an alternation that tries to 
match any individual word in the string as a valid alternate.

=head2 BETA

Please note that this is a beta release. This is more of a 
proof of concept than something ready for production code 
or for massive grammars. The interfaces may change completely 
in the future. When the interfaces have settled, I will release 
this as a version 1.0+ module. Until then, please do not use 
this to develop some gigantic parser when the grammar may have 
to completely change.

=head1 EXPORT

Currently, EVERYTHING is exported into the callers namespace. 
Yes, I know, bad programmer. No biscuit. 

The problem is I did not want grammars to be weighed down with 
a bunch of package prefixes at every step.

	my $grammar = Parse::Gnaw::match(Parse::Gnaw::a(Parse::Gnaw::l('hello'),Parse::Gnaw::l('howdy'));

Gets rather tedious.

Hopefully, no one will have collisions with subroutine names. 
If they do, then it might make sense to create a new package, 
declare the grammar in there, then simply pull out the code 
reference and use that in the rest of your code.

	package mynormalpackage;

	our $grammar;

	{
		package mylocalpackage;

		use Parse::Gnaw; # all subs imported into mylocalpackage

		$mynormalpackage::grammar = match('hello', 'world');

	}


	$grammar->('howdy');

Again, everything may change tomorrow as I sort this out.

=head1 ok function

In the examples provided, the "ok" function is used repeatedly.
This allows the examples to be used directly in the Parse::Gnaw
tests directly. The "ok" function is defined there by the 
Test::More package. Here is a stub for the "ok" function so that
you can use the examples independent of Test::More.

	use Parse::Gnaw;

	sub ok {
	 	my $boolean = shift(@_);
	
		if($boolean) {
			print "pass";
		} else {
			print "FAIL";
		}
		print " : ";
	
		my $msg = shift(@_);
	
		if(defined($msg)) {
			chomp($msg);
			print $msg;
		}
	
		print "\n";
	}

	my $grammar; # declare it here so other examples can just use it.

The above code is assumed to be contained in all the examples that follow.

=head1 OVERVIEW

So, again, when you do a

	use Parse::Gnaw;

in your code, a number of subroutines are imported into your namespace.
You can then call these subroutines to build up a grammar. The grammar
is held in the form of a code reference. You then dereference the coderef
to call the parser and provide it with the string you want to parse.
The dereferenced code reference that is the parser will return a boolean
to indicate whether a match was found or not.

	$grammar = match('hello', 'world');
	
	ok($grammar->('hello world')==1), "match");
	ok($grammar->('howdy world')==0), "NO match");

	> pass : match
	> pass : NO match

If you want your grammar to match a literal string, simply pass that string
into the "parse" or "match" function. Strings passed into the Gnaw
functions are interpreted to mean that they are literals to look for in the
text being parsed.

=head2 Top Level and Low Level Functions

The Gnaw module provides a number of "top level" functions to create  your 
grammars. These top level functions return code references which are your
grammar. You then dereference these code references to call the grammar
and pass in the string you want to parse.

Only top level functions return grammar code references. They include:

	match	Find the first match of the grammar in the string.
		Skip any text until we find a match.

	parse	Parse the string from the beginning only. 
		Do not skip any text looking for a match.

	swap	Find the first match of the grammar in the string.
		Skip any text until we find a match.
		Upon finding the first match, replace the matched text
		with something else.

		!!!THE "swap" FUNCTION IS CURRENTLY NOT IMPLEMENTED!!!

These functions return code references that are the grammar, code references
you dereference to run the grammar on a string.

	my $grammar = match('hello', 'world');
	ok($grammar->("these are not the droids you are looking for")==0, 'no match');

Low level functions return code references that are called "stitchers". 
These are low level subroutines used by Parse::Gnaw to build up the grammar. 
Most of the low level and high level Gnaw functions know how to handle stitchers.
A "stitcher" is not a grammar, and if you try to dereference a 
coderef from a low level function, your script will die with strange errors.

	my $stitcher = a('hello', 'howdy');
	
	# WRONG! Don't do it!
	$stitcher->("these are not the droids you are looking for");  

Always make sure you use a top level function as your final function 
of your grammar.

=head2 Literals

Most of the Parse::Gnaw subroutines will recognize strings passed in as
parameters as string literals to become part of the grammar. We already
saw this in the above example:

	$grammar = match('hello', 'world');

This example will create a grammar that looks for the literal 'hello'
followed by the literal 'world'.

Actually, the grammar will look for the literal 'hello', it will then
Skip over any text that the Skip function tells it to Skip (by default,
it will skip over any whitespace), and then look for the literal 'world'.

See the "Skip" function for more information.

Strings passed into Parse::Gnaw functions are perl strings, meaning
that they follow the normal perl rules for string evaluation.
i.e. Single quotes do NOT get evaluated. Double quotes do.

If you want to match a tab character, then be sure to use "\t" 
instead of '\t'.

=head2 List Context

Before we go too far into talking about Gnaw, we need to address a meta issue
around Parse::Gnaw. 

The thing to keep in mind is that all Parse::Gnaw subroutines are... 

... perl subroutines. 

This means that they are susceptible to list context issues that occur 
in perl when you call the functions, and that they are susceptible to 
list context issues and return mechanism issues when you declare your 
own subroutines to wrap up a subrule of your grammar.

When you call any perl subroutine, the parameters passed in are flattend
into one gigantic list by the list context mechanism in perl.

	# all parameters are flattened. subroutine receives 6 parameters.
	my_perl_sub( (1,2,3),('a', 'b', 'c') ); 

When the my_perl_sub subroutine is called, perl takes all the parameters
and flattens them into a single list context. This means in the above 
example that my_perl_sub receives 6 parameters:

	1, 2, 3, 'a', 'b', 'c'

This also means that my_perl_sub has no idea that the numbers had been
grouped together in one set of parens and the letters had been grouped 
together in another set of parens. The my_perl_sub subroutine sees 
nothing but a flat list of parameters being passed in.

If you want to call a subroutine and have it treat parameters in groups,
then the most common way to do that is to group the parameters you want
grouped by putting them into arrays and passing references to those arrays.

	# my_perl_sub receives two parameters, two array references.
	my_perl_sub( [1,2,3] , ['a', 'b', 'c'] ); 

This exact same list context mechanism affects Parse::Gnaw. And the solution
within Parse::Gnaw is the same as for general perl: wrap groups of items
in anonymous arrays.

Example. You want a grammar with two possible alternates. The first alternate 
is "hello" followed by "world". The second alternate is "howdy" followed by
"planet". If you try to put them into the alternate function (the "a" function),
you might try this:

	$grammar = match( a( 
			"hello", "world",
			"howdy", "planet"
	));

The problem is that the "a" function has no way of knowing how it is supposed
to group the parameters. Instead, the above example will look for four possible
alternates:

	"hello"
	or
	"world"
	or
	"howdy"
	or
	"planet"

The solution is to group the parameters with an anonymous array reference.
The above example can be rewritten as follows:

	$grammar = match( a( ["hello", "world"],["howdy", "planet"]	));

This will look for two possible alternates:

	"hello" "world"
	or
	"howdy" "planet"

Most of the Parse::Gnaw functions (such as the "a" (alternate) function) are 
smart enough to recognize array references and treat them as a series of 
grammar components meant to be addressed as a single unit.

=head2 declare subroutines for your own sub-rules

The other issue around perl list context and Parse::Gnaw occurs around
perl and its "return" function in subroutines. In Parse::Gnaw, if you have
a complex grammar, you can break it up into rules which take the form
of perl subroutines you declare. The subroutine is some subset of the
whole grammar, and must return something that the rest of the grammar
can use.

This means you must be aware of perls "return" functionality when declaring
subroutines as your rules.

For example, you can declare the following subroutine in any perl code:

	sub mysub { 'hello', 'there' };

When you call a perl subroutine, it will return whatever was the last
expression evaluated. And in the above example, "there" is the last 
expression evaluated, and "there" is what mysub will return.

	my $retval = tester;
	print "retval is '$retval'\n";

	> retval is 'there'

Again this is an issue relating to perls list context. If you want a subroutine
to return a list of items, then enclose them in parenthesis to force 
list context on the return value.

	sub fruit { ('apple', 'banana', 'pear') } # parens force list context

You could then call this subroutine and pass it to the Parse::Gnaw "a" function
as a list of possible alternates.

	$grammar = match(a( fruit ));

However, if you want to declare a subroutine which is intended to contain
a sequence of items, then you will want to wrap them in an anonymous array
so that a single array reference is returned and is treated as a sequence
by the rest of the grammar.

	# square brackets groups return value
	sub greetworld { ['hello', 'world'] }	
	sub greetplanet{ ['howdy', 'planet'] }

	$grammar = match(a( greetworld, greetplanet ));

Note that the two subroutines define a sequence of literals that get
passed into the "a" function. To keep the "a" function from flattening
the return value of the two subroutines, the subroutines need to group
their sequences into array references.

Always keep in mind that Parse::Gnaw functions are perl functions and
are susceptible to list context issues relating to the things being
passed into a function as well as what is returned by the function.

As a general rule, when declaring subroutines to describe pieces of your
grammar, if that subroutine contains more than one grammar component,
you should wrap the return value in parenthesis if you intend to use
the components in list context (a list of different alternates to pass in
to "a"), or you should wrap the return value in square brackets if you
intend to use the components as one sequence of components.

If the subroutine contains ONLY one Parse::Gnaw grammar component, then
you do not have to wrap that component in parens or square brackets.
Parse::Gnaw low level functions always return one scalar, a stitcher
code reference that can be used by other Parse::Gnaw functions.

Since Parse::Gnaw grammar functions always return one scalar, you do not
have to worry about forcing scalar context with square brackets. Just
call the Gnaw function and perl will return the stitcher for you.

	# return value of 'a' function is a scalar, 
	# (a scalar containing a code ref that is a stitcher function)
	# therefore, subroutine "fruit" doesn't have to put 
	# the "a" function in square brackets to force scalar context on
	# return value.
	sub fruit { a('apple', 'banana', 'pear') }

=head2 summary of return values in subroutines/subrules 

Always using parens or square brackets in your subroutines will 
show how you intend the subroutine to be used in a larger grammar.

	# parens forces return in list context. items may be used in parallel
	sub fruit { ('apple', 'pear', 'banana') } 

	# square brackets forces return in scalar context. items are seqential.
	sub greeting { ['may', 'the', 'force', 'be', 'with', 'you'] }

Do not use a wrapper (no parens, no square brackets) if subroutine 
only calls a single Gnaw grammar component. 

	# 'name' subroutine only calls one function 'a'. don't have to wrap.
	sub name { a('Alice', 'Bob', 'Charlie') }

Now back to the grammar functions.

=head2 cc (character classes)

The Parse::Gnaw "cc" function is used to declare a character class.
The input to the "cc" function is a single string which lists all the
characters that are to be part of the character class. The class will
match any single character that is listed in the string.

	$grammar = match( cc('0123456789') ); # any single digit. 0,1,2,3,4,5,6,7,8,9

The "cc" function recognizes the '-' character as a meta character which
operates the same as the '-' in perl character classes, creating a character
class with all the characters between the two characters (inclusive) 
separated by the '-' character.

	$grammar = match( cc('0-9') ); # any single digit. 0,1,2,3,4,5,6,7,8,9

If you want the '-' character to be part of your character class, make it 
the first character in the string.

	$grammar = match( cc('-aeiou') ); # a hyphen or any vowel

Character class shortcuts are provided for common character classes.

	ccdigit => 0-9
	ccword => a-zA-Z0-9_
	ccspace => \n \t \r \f or literal space

	$grammar = match( ccdigit ); # any single digit. 0,1,2,3,4,5,6,7,8,9

Note that the "cc" function and its related shortcuts are one of the functions
in Parse::Gnaw that do NOT handle array references, nor do they handle multiple
strings being passed into them in list context. The only valid parameter to
pass to the "cc" function is a single string containing all the characters 
that you want in the character class.

The cc shortcuts take no parameters at all.

=head2 CC (inverted character class)

The Parse::Gnaw "CC" function is an inverted character class. The input is a
single string which defines the characters that you do NOT want to be part of
the character class. Note that the "CC" function is uppercase and the "cc" 
function is lower case.

	$grammar = match( CC('0-9') ); # any single character EXCEPT a digit

Short cuts are provided for common inverted character classes:

	CCDIGIT => anything BUT 0-9
	CCWORD => anything BUT a-zA-Z0-9_
	CCSPACE => anything BUT \n \t \r \f or literal space

	$grammar = match( CCDIGIT ); # any single character EXCEPT a digit

Note that the "CC" function has the same parameter restrictions as "cc".
Only one string containing the characters defining the NOT character class.
No more than a single parameter. No array references. The shortcuts take
no parameters at all.

=head2 thing

The Parse::Gnaw "thing" function is a special character class that 
matches any single character. It is equivalent to the perl
regular expression '.' character. But perl does not allow '.' to be
the name of a subroutine, so I called it "thing". Part of the reason 
for this name was because of how it works well with quantifier 
shortcuts of "any" and "some", described below.

The "thing" function takes no parameters.

	$grammar=match('b', thing, 'b');

	ok($grammar->('bob')==1, "bob matches");
	ok($grammar->('bb')==0, "bb does not match");

=head2 a (alternation)

The "a" function is an alternation function. It interprets each
of its parameters to be one of several possible alternates.

The following will look for one of any possible fruit in your text.

	$grammar=match(a('apple', 'banana', 'pear', 'peach'));

	ok($grammar->("she is the apple of my eye")==1, "found apple");

Because listing a bunch of alternate literals is fairly common,
the "qa" function allows you to do that with fewer quotation marks.
The "qa" function takes a single string, breaks it up into individual
literals based on whitespace, and then treats each literal as an
alternate in the grammar.

The above example could be shortened to this:

	$grammar = match(qa('apple banana pear peach'));

	ok($grammar->("she is the apple of my eye")==1, "found apple");
	
Grouping of a sequence of components into one alternate is done
by putting the sequence in an array reference, see "list context"
issues described above for a more detailed explanation of why this
is.

The following example looks for two possible alternates. The first
alternate is the literal 'hello' followed by the literal 'world'.
The second alternate is the literal 'howdy' followed by 'partner'.

	$grammar = match(a( ['hello', 'world'], ['howdy', 'partner'] ));
	ok($grammar->("why howdy partner !")==1, "found alternate");

The alternates can be any sequence of grammar components wrapped in 
an array reference.

=head2 g and t (greedy and thrifty quantifiers)

The "g" and "t" functions are quantifier functions. They allow you 
to define a grammar that looks for some pattern that repeats for
some number of times.

The format for a quantifier call looks like this:

	g ( [min, max(?)], grammar component(, component)* )

The first parameter to the "g" or "t" function is an array reference.
This contains the parameters that control how the quantifier works.
The "min" value determines the minimum number of times the pattern
must match before considered a pass. The "max" value is optional. If 
max is not defined, it is assumed to be infinite, and the parser will 
attempt to fit as many patterns into memory as can fit.

The remaining one or more parameters define the pattern to which 
the quantifier will be applied. If more than one are supplied, 
they will be applied as one large sequence.

The difference between "g" and "t" is how quickly the quantifier
will try to match. The "g" function is greedy and will try to match
as many patterns as possible. If it fails to match, the greedy 
quantifier will start backing off pattern counts and try to let the
rest of the grammar find a match.

The "t" function is thrifty and will try to match as few patterns
as possible. If the rest of the grammar fails to match, the 
thrifty pattern will try to match another pattern, before trying
the rest of the grammar.

	# seventeen or more 'g' or 'a' or 't' or 'c' characters.
	$grammar = match( g([17], cc('gatc')) ); 

	# one or more "word" characters
	$grammar = match( g([1], ccword) );

	# zero or more "digit" characters
	$grammar = match( g([0], ccdigit) );

	# at least 3 and up to 8 letters
	$grammar = match( g([3,8], cc('a-zA-Z')));

Note that the "g" and "t" quantifiers are functions that can accept
one or more parameters passed into them. These parameters can be
other grammar components, string literals, or array references
for grouped bits of grammar.

	# one or more 'hello' followed by 'world'
	$grammar = match( g([1], 'hello', 'world') )

Shorcuts are provided for g([0],...) and g([1], ...), called 
"any" and "some" respectively

=head2 any and some functions

Because greedy quantifiers of "zero or more" and "one or more" are fairly 
common, shortcuts 'any' and 'some' have been provided.

	$grammar = match( any(ccdigit) ); # zero or more digits

	$grammar = match( some(ccword) ); # one or more word characters.

The "any" and "some" functions take any number of input parameters,
and the parameters can be string literals, array references, and other
grammar components.

	# one or more of "hello" followed by "world"
	$grammar = match( some('hello', 'world') );

=head2 anything and something functions

The character set "thing" matches any single character. The "any" and "some" 
functions are quantifiers of zero or more and one or more. These two functions
are commonly combined, therefore a shortcut has been provided:

	anything  => g([0], thing)
	something => g([1], thing)

You can use these in your grammars to make them slightly more readable.

	# literal 'hello' followed by 1 or more characters, followed by
	# literal 'how', literal 'are', and literal 'you'
	$grammar = match( 'hello', something, 'how', 'are', 'you' );

=head2 get

The "get" function is used to capture the text that matches a specific portion
of the grammar and pass it into a user defined subroutine.

The first parameter of the "get" function can be one of several possible things. 

(1) a scalar reference

(2) an array reference

(3) a subroutine reference. 

If the first parameter is a scalar reference, the scalar will be used 
to hold whatever matched the "get" function.

	my $name;

	$grammar = match('hello', get(\$name, some(ccword)), '!' );

	$grammar->('hello Alice !');

	print "name is '$name'\n";

	> name is 'Alice'

If your grammar gets more than one match while it parses,
the scalar reference only holds the last match. If you use the
same grammar to parse different strings, scalars are initialized
to whatever value they held when the grammar was generated, and
this value is overwritten only if a match occurs.

	my $name;

	$grammar = match('hello', get(\$name, some(ccword)), '!' );
	$grammar->('hello Alice !');
	$grammar->('hello Bob !');
	$grammar->('hello Charlie !');

	print "name is '$name'\n";

	> name is 'Charlie'

If the first parameter is an array reference, then every match
by the "get" function will get pushed into the array. If you call
the same grammar multiple times, the array is emptied at the start
of parsing. Note this behaviour is different from scalars.

	my @name;

	$grammar = match(some('hello', get(\@name, some(ccword)), '!') );
	$grammar->('hello Alice ! hello Bob ! hello Charlie !');

	print "name is ". Dumper \@name;

	> name is $VAR1 = [
	>	'Alice',
	> 	'Bob',
	> 	'Charlie'
	> ];

If the first parameter is a subroutine reference, the parser will
call this subroutine on every match and pass in as the first parameter
the value of the string that matched. You may then do whatever you
wish with this string inside the subroutine you define.	

	my $name = sub{
		my ($string) = @_;
		# write $string to a file, or whatever
		print "called subroutine, received '$string'\n";
	};

	$grammar = match('hello', get($name, some(ccword)), '!' );

	$grammar->('hello Alice !');

	> called subroutine, received 'Alice'


The remaining parameters of the "get" function are one or more 
grammar components. Literals, character classes, alternations, 
quantifiers, array refs used for grouping sequences of grammar
components, etc.

The "get" function can be nested, like nested capturing parens
in perl regular expressions.

	my ($g1, $g2, $g3, $g4, $g5, $g6, $g7, $g8);

	$grammar = parse( 
		get(\$g8,
			get(\$g1, get(\$g2, thing), get(\$g3, thing) ),
			get(\$g4, get(\$g5, thing), get(\$g6, thing), get(\$g7, thing) ),
		) 
	
	);

	$grammar->('abcdefghijklmnop');
	
	ok($g2 eq 'a', "g2");
	ok($g3 eq 'b', "g3");
	ok($g1 eq 'ab', "g1");
	ok($g5 eq 'c', "g5");
	ok($g6 eq 'd', "g6");
	ok($g7 eq 'e', "g7");
	ok($g4 eq 'cde', "g4");
	ok($g8 eq 'abcde', "g8");
	
Translating the "get" function to use a callback that writes the results to the
proper perl regexp variables of $1, $2, $3 is left as an exercise for the reader.

=head2 now versus defer

The "now" function allows you to define a subroutine to be called every time
the parser hits that part of the grammar. The code subroutine will be called whether
that part of the grammar eventually matches the text being parsed or not.

The "defer" function allows you to define a subroutine to be called only if
that branch of the grammar matches the text being parsed. The subroutine
handed to the "defer" function is called at the end of parsing when a match occurs
or when the "commit" function is called.

This example uses the "now" function:

	sub howdy { [ now(sub{print"trying howdy\n"}), 'howdy' ] }

	sub hi    { [ now(sub{print"trying hi   \n"}), 'hi' ] }

	$grammar = match(a(howdy, hi);

	$grammar->("hi");

The above example will print 

	trying howdy
	trying hi

Even though the alternative "howdy" ended up failing.


The next example uses the "defer" function instead:

	sub howdy { [ defer(sub{print"trying howdy\n"}), 'howdy' ] }

	sub hi    { [ defer(sub{print"trying hi   \n"}), 'hi' ] }

	$grammar = match(a(howdy, hi);

	$grammar->("hi");

The above example with print only

	trying hi

Because "howdy" ended up failing, the defered subroutine for "howdy" did not get called.

Because the "defer" function is more likely to be useful in more grammars, the short
cut to do a "defer" function is to simply pass in a subroutine to any of the other 
grammar functions. Any code reference will be assumed to be a "defer".

Rewriting the "defer" example above but with the shorthand would look like this:

	sub howdy { [ sub{print"trying howdy\n"}, 'howdy' ] }

	sub hi    { [ sub{print"trying hi   \n"}, 'hi' ] }

	$grammar = match(a(howdy, hi);

	$grammar->("hi");

As before, the above example with print only

	trying hi


The "defer" function is useful for doing things only when the parser knows it has
a correct interpretation of the text being parsed. The "get" function is a "defer"
function that has been wrapped.

The "now" function is useful for doing something even if the interpretation might 
fail later. One example is printing debug statements of a grammar to understand 
where ther parser is going as it works through a piece of text. The "commit" function
is a "now" function that has been wrapped with extra features.

=head2 commit

The "commit" function is used to commit the parser to a particular interpretation
of a grammar. If the parser is working a grammar and applying it to a text,
and the parser hits a "commit" function, then that path in the grammar must
match. If the grammar fails to match after a "commit", rather than try any other 
possible interpretations, the parser will quit with an error.

The "commit" function will cause any currently scheduled "defer" functions 
to be executed by the parser. The "commit" function can also trigger the
text being parsed to be deleted up to the current character being parsed.

Use "commit" if your grammar contains a reserved keyword and you want to force
the parser to interpret the text as a keyword. Use the "commit" function if
you are parsing a large chunk of text and you want to be able to remove the
previous text from memory.

	$grammar = match(some('keyword', commit, 'blah', 'blah', 'blah'));

=head1 EXAMPLES

=head2 trekisms

The following grammar shows how one might identify dialogue and 
attribute it to a particular fictional character. 

The "attributeline" subroutine allowed us to bundle the functionality
of the output into one spot and then easily use that functionality 
at several different points in the grammar.

	my $captured="";

	sub attributeline { 
		my ($name, $restofgrammar) = @_;
		my $callback = sub{$captured.=sprintf ("%8s says: %s\n", $name,shift(@_));};
		my $stitcher = get($callback, $restofgrammar);
		return $stitcher;
	}

	sub trekname { qa('Jim Captain Spock Bones Doctor Scotty') } 
	sub occupation {a('ditch digger', 'bricklayer', 'mechanic')}
	sub mccoy_job { [ql("I'm a doctor, not a"), occupation, a('!', '.')] }
	sub mccoy_diag { [ "He's", 'dead', ',', trekname, a('!', '.') ] }
	sub mccoy_rant1 { [ql('You green-blooded Vulcan'), a('!', '.') ] }
	sub mccoy_isms {
		attributeline('McCoy', a(mccoy_job, mccoy_diag, mccoy_rant1)) 
	}

	sub spock_awe {['Fascinating', ',', trekname, '.']}
	sub spock_logic {['Highly', 'illogical',',', trekname, '.']}
	sub spock_sensors { [ql("It's life ,"), trekname, ql(', but not as we know it .')]}
	sub spock_isms {
		attributeline('Spock', a(spock_awe, spock_logic, spock_sensors))
	}
	
	sub kirk_dipolomacy1 {ql('We come in peace .')}
	sub kirk_dipolomacy2 {ql('Shoot to kill .')}
	sub kirk_to_scotty {ql('I need warp speed now, Scotty !')}
	sub kirk_to_spock {ql('What is it , Spock ?')}
	sub kirk_to_bones {ql('Just fix him , Bones')}
	sub kirk_solution {ql('Activate ship self-destruct mechanism .')}
	sub kirk_isms {
		attributeline('Kirk', a(
			kirk_dipolomacy1, 
			kirk_dipolomacy2,
			kirk_to_scotty,
			kirk_to_spock,	
			kirk_to_bones,	
			kirk_solution
		))
	}

	sub scotty_phy101 {ql('Ya kenna change the laws of physics .')}
	sub time_units {qa('minutes hours days weeks')}
	sub scotty_estimate {[ ql("I'll have it ready for you in three"), time_units, '.' ]}
	
	sub scotty_isms {attributeline('Scotty', a(scotty_phy101, scotty_estimate))}
	
	
	sub alien_isms {attributeline('alien', 'weeboo')}
	
	
	sub trek_isms {a(mccoy_isms, spock_isms, kirk_isms, scotty_isms, alien_isms )}
	sub trek_script {some(trek_isms)}	
	
	$grammar = parse(  trek_script );
		
	my $script = <<'SCRIPT';
	What is it, Spock?
	It's life, Jim, but not as we know it.
	We come in peace.
	weeboo
	Shoot to kill.
	weeboo
	I need warp speed now, Scotty!
	I'll have it ready for you in three minutes.
	weeboo
	I need warp speed now, Scotty!
	Ya kenna change the laws of physics.	
	weeboo
	weeboo
	Shoot to kill.
	Shoot to kill.
	I'm a doctor, not a bricklayer.
	Highly illogical, Doctor.
	You green-blooded Vulcan.
	Shoot to kill.
	Shoot to kill.
	He's dead, Jim.
	Activate ship self-destruct mechanism.
	Highly illogical, Captain.
	SCRIPT
	;

	#print "script is '$script'\n";

	ok($grammar->( $script )==1, "1 match");

	my $expected =  <<'EXPECTED';
	    Kirk says: What is it, Spock?
	   Spock says: It's life, Jim, but not as we know it.
	    Kirk says: We come in peace.
	   alien says: weeboo
	    Kirk says: Shoot to kill.
	   alien says: weeboo
	    Kirk says: I need warp speed now, Scotty!
	  Scotty says: I'll have it ready for you in three minutes.
	   alien says: weeboo
	    Kirk says: I need warp speed now, Scotty!
	  Scotty says: Ya kenna change the laws of physics.
	   alien says: weeboo
	   alien says: weeboo
	    Kirk says: Shoot to kill.
	    Kirk says: Shoot to kill.
	   McCoy says: I'm a doctor, not a bricklayer.
	   Spock says: Highly illogical, Doctor.
	   McCoy says: You green-blooded Vulcan.
	    Kirk says: Shoot to kill.
	    Kirk says: Shoot to kill.
	   McCoy says: He's dead, Jim.
	    Kirk says: Activate ship self-destruct mechanism.
	   Spock says: Highly illogical, Captain.
	EXPECTED
	;
	
		
	
	ok($captured eq $expected, "checking captured string matches expected");

The above example is included as a test in the t directory of the tarball from CPAN.

	
=head1 NOT IMPLEMENTED YET



=head2 recursive

The "recursive" function has not been implemented yet.

If you define a grammar which is recursive, you must
wrap the recursive call in the "recursive" function. 

If you declare a recursive grammar without using a 
"recursive" function, then perl will recursively call 
the subroutine until it dies a horrible death.

	sub expression;
	sub expression{ a([ '(' expression ')'], 'a+b') }

	# this call to "expression" will recursively call itself
	# until perl crashes.
	my $grammar = match(expression); 

The above example will crash. Note that it crashes during the
"generate" stage of creating the grammar. The grammar isnt
even being used to try to match a string yet. The mere act of 
declaring a recursive grammar without the "recursive" function will
cause a crash.

What you need to do is wrap any recursive call to a rule in
the "recursive" function.

	sub expression;
	sub expression{ a([ '(' recursive(\&expression) ')'], 'a+b') }

	my $grammar = match(expression);



=cut 
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




sub __GNAW__WHAT {0;} # what kind of element is this  

sub __GNAW__PAYLOAD {1;} 

sub __GNAW__NEXT {2;}

sub __GNAW__PREV {3;}

sub __GNAW__DEBUG {4;} # use this only during debug mode, contains debug string to describe element

sub __GNAW__DELETE_WHAT { 0; } # element has been deleted, removed from linked list
sub __GNAW__LETTER_WHAT { 1; } # element holds a text letter
sub __GNAW__MARKER_WHAT { 2; } # element is a marker
sub __GNAW__CLLBCK_WHAT { 3; } # element holds a callback
sub __GNAW__HEADER_WHAT { 4; } # element is a head/tail point




# these two elements never get deleted
our $__gnaw__head_text_element    ;
our $__gnaw__tail_text_element    ;

# keep a pointer to current position in text.
our $__gnaw__curr_text_element ;  


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# explaining "markers" to text in linked list.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# text is a linked list. Each element is a letter.
# Markers are inserted into the linked list as new elements in between
# the text elements. We can then jump back to an old marker by jumping
# back to a reference to the element.
# 
# hello world
# h-e-l-l-o- -w-o-r-l-d
# start parsing, set a marker BEFORE first character
# say its for an alternation function.
# (marker1)-h-e-l-l-o- -w-o-r-l-d
# move forward to 'w' in world
# set another marker there, say for a "get" function.
# (marker1)-h-e-l-l-o- -(marker2)-w-o-r-l-d
# continue parsing
# parse fails, fallback position is the (marker1)
# alternation may decide to keep marker in place
# to try another alternate.
# meanwhile, (marker2) still exists but is meaningless since it
# was from an interpretation that failed.
#
# As we move current position forward, delete any meta-elements we come across.
# since they can only exist from a failed interpretation, we can delete them
# as we move forward.
#
# code-wise, what are markers?
#
# When code requests a marker, it may request a marker either
# before the current position or after it.
#
# If a rule is starting a capture, it hasn't read any text yet,
# so the marker would go *before* the current position.
# If a rule completes a capture, the rules have parsed the current
# text position and have probably moved the pointer forward to 
# the next character, therefore the end marker would be inserted
# *before* the current pointer.
#
# Most functions should insert their markers just before the 
# current position. But each requester will have to figure out 
# if they want a marker before or after the current letter.
#
# when requesting a marker, the code will insert an element before/after
# the current location and return a reference to that element.
# 
# fallback won't cause the marker to be deleted. That will be the
# responsibility of whoever generated the fallback position in the first place.
#
# if someone requests that a marker be deleted, it will be removed from
# the linked list and it's "what" marker will be set to "deleted".
# It won't be removed from memory until perl's garbage collection 
# claims it. This means that if somehow an old pointer to the marker
# is used for anything, it will come back as "deleted". 
#
# The alternative is that we force a deletion of the element
# and any pointers to that element suddenly point to random data in the heap
# that's probably not good.
# 
# Will try to properly account for all references, but keeping them
# around will be a backup plan to prevent accidentally using an old marker.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


# if you pass in a code ref payload, I'll return a marker that is a callback.
# if you pass in any other payload, I'll assume its a letter and make this a letter element.
# if you don't pass in any payload, I'll return a plain marker.
sub __gnaw__create_new_element_before_or_aftern_this_element { # ($before_or_aftern, $thiselement, $typenum, $payload?) 
	########GNAWMONITOR;
	my $before_or_aftern = shift(@_);
	my $thiselement      = shift(@_);
	my $typenum          = shift(@_);


	my $firstelement;
	my $lastelement;

	########GNAWMONITOR(__gnaw__string_showing_user_current_location_in_text());

	my $newelement = [];
	########GNAWMONITOR("newelement is '$newelement'");

	######## __gnaw__whereami;
	if($before_or_aftern == 1) {
		# BEFORE
		if($thiselement eq $__gnaw__head_text_element) {
			__gnaw__die("tried to insert marker before head element");
		}

		$firstelement = $thiselement->[__GNAW__PREV];
		$lastelement = $thiselement;

		########GNAWMONITOR("firstelement is '$firstelement'");
		########GNAWMONITOR("lastelement is '$lastelement'");

	} else {
		# AFTER
		if($thiselement eq $__gnaw__tail_text_element) {
			__gnaw__die("tried to insert marker after tail element");
		}
	
		$firstelement = $thiselement;
		$lastelement = $thiselement->[__GNAW__NEXT];

		########GNAWMONITOR("firstelement is '$firstelement'");
		########GNAWMONITOR("lastelement is '$lastelement'");
	}

	$newelement->[__GNAW__WHAT] = $typenum;

	if($typenum==__GNAW__LETTER_WHAT) {
		my $payload = shift(@_);
		$newelement->[__GNAW__PAYLOAD] = $payload;

		########GNAWMONITOR("added letter '$payload' to linked list");

		# if we just inserted a text element before the tail element
		# and the current text pointer points to the tail element,
		# then move current text pointer to the element we just inserted.
		if(	($thiselement eq $__gnaw__tail_text_element) 
			and ($__gnaw__curr_text_element eq $__gnaw__tail_text_element)
		) {
			$__gnaw__curr_text_element = $newelement;
			########GNAWMONITOR("current text was pointing to tail element. moved to '$newelement'");
		}

	} elsif($typenum==__GNAW__MARKER_WHAT) {
		$newelement->[__GNAW__WHAT] = __GNAW__MARKER_WHAT;
		########GNAWMONITOR("added marker to linked list");

	} elsif($typenum==__GNAW__CLLBCK_WHAT) {
		my $payload = shift(@_);
		$newelement->[__GNAW__PAYLOAD] = $payload;
		########GNAWMONITOR("added callback to linked list");
	} else {
		__gnaw__die("tried to create a text element with an unknown typenum, '$typenum'");
	}

	# during debug mode, if we pass in a string describing the element,
	# attach it to the element so we know who created what in the list.
	######## 
	######## if(scalar(@_)) {
	######## 	my $debugstring = shift(@_);
	######## 	$newelement->[__GNAW__DEBUG] = $debugstring;
	######## }
	######## 

	$firstelement->[__GNAW__NEXT]=$newelement;
	$newelement->[__GNAW__PREV]=$firstelement;

	$newelement->[__GNAW__NEXT]=$lastelement;
	$lastelement->[__GNAW__PREV]=$newelement;


	########GNAWMONITOR(__gnaw__string_showing_user_current_location_in_text());

	return $newelement;
}

# if you pass in a code ref payload, I'll return a marker that is a callback.
# if you pass in any other payload, I'll assume its a letter and make this a letter element.
# if you don't pass in any payload, I'll return a plain marker.
sub __gnaw__create_new_element_before_this_element { # ($thiselement, $typenum, $payload?)
	########GNAWMONITOR;
	return __gnaw__create_new_element_before_or_aftern_this_element(1,@_);
}

# if you pass in a code ref payload, I'll return a marker that is a callback.
# if you pass in any other payload, I'll assume its a letter and make this a letter element.
# if you don't pass in any payload, I'll return a plain marker.
sub __gnaw__create_new_element_after_this_element { # ($thiselement, $typenum, $payload?)
	########GNAWMONITOR;
	return __gnaw__create_new_element_before_or_aftern_this_element(0,@_);
}


sub __gnaw__create_new_element_before_current_element { # ($typenum, $payload?)
	########GNAWMONITOR;
	return __gnaw__create_new_element_before_this_element($__gnaw__curr_text_element, @_);		
}

sub __gnaw__create_new_element_after_current_element { # ($typenum, $payload?)
	########GNAWMONITOR;
	return __gnaw__create_new_element_after_this_element($__gnaw__curr_text_element, @_);		
}


sub __gnaw__create_new_marker_before_current_element { # might pass in a debug string
	########GNAWMONITOR;
	return __gnaw__create_new_element_before_current_element(__GNAW__MARKER_WHAT , @_);		
}

sub __gnaw__create_new_marker_after_current_element { #  might pass in a debug string
	########GNAWMONITOR;
	return __gnaw__create_new_element_after_current_element( __GNAW__MARKER_WHAT, @_);		
}


# remove the marker from the linked list and 
# reattach the linked list elements around the marker.
# remove the contents of the marker array.
# set the "what" element to indicate this is a deleted marker.
sub __gnaw__delete_this_text_element { # (this element) return next element after deleted one
	########GNAWMONITOR;
	my ($marker) = @_;

	########GNAWMONITOR(__gnaw__string_describing_single_text_element($marker));

	unless(defined($marker)) {
		########GNAWMONITOR("tried to garbage collect an undefined marker");
		return;
	}

	unless(ref($marker) eq 'ARRAY') {
		########GNAWMONITOR("tried to garbage collect something tht didn't poitn to a marker");
		return;
	}

	my $firstelement = $marker->[__GNAW__PREV];
	my $lastelement = $marker->[__GNAW__NEXT];

	$firstelement->[__GNAW__NEXT]=$lastelement;
	$lastelement->[__GNAW__PREV]=$firstelement;

	# if current text pointer is pointing at the element we're deleting, we need to point to something valid. point to the next element.
	if($__gnaw__curr_text_element eq $marker) {
		$__gnaw__curr_text_element = $lastelement;
	}

	@$marker=(__GNAW__DELETE_WHAT);  # works because __GNAW__WHAT is zero.
	return $lastelement;
}


sub __gnaw__text_element_is_valid { # (textelement)
	my($textelement)=@_;

	unless(defined($textelement)) {
		__gnaw__die("tried to use an undefined text element");
		return;
	}

	unless(ref($textelement) eq 'ARRAY') {
		__gnaw__die("tried to use a text element that was not an array reference");
		return;
	}

	if($textelement->[__GNAW__WHAT] == __GNAW__DELETE_WHAT) {
		__gnaw__die("tried to use a text element marked as previously deleted (". __gnaw__string_describing_single_text_element($textelement) . ")" );
		return;
	}

	return;
}

sub __gnaw__restore_old_text_marker {
	my ($textmarker) = @_;

	__gnaw__text_element_is_valid($textmarker);
	$__gnaw__curr_text_element = $textmarker;

	return;
}




sub __gnaw__call_all_callbacks_from_beginning_to_current_element { # including current element if it is a callback
	########GNAWMONITOR("__gnaw__call_all_callbacks_from_beginning_to_current_element BEGIN");

	my $curr = $__gnaw__head_text_element;

	# while still looking
	my $still_looking=1;
	while ($still_looking) {
		if($curr->[__GNAW__WHAT] == __GNAW__CLLBCK_WHAT) {
			my $callback = $curr->[__GNAW__PAYLOAD];

			########GNAWMONITOR("aaaaaa call_all_callbacks found callback '$callback'\n");
			$callback->();
			########GNAWMONITOR("zzzzzz\n");

			my $callelement = $curr;
			$curr = $callelement->[__GNAW__NEXT];
			__gnaw__delete_this_text_element($callelement);
		}

		if($curr eq $__gnaw__curr_text_element) {
			$still_looking=0;
		} else {
			# now go to next element
			$curr = $curr->[__GNAW__NEXT];
		}

	}

	########GNAWMONITOR("__gnaw__call_all_callbacks_from_beginning_to_current_element END");
	return;
}


# this assumes you've already called any callbacks
sub __gnaw__delete_all_elements_from_beginning_to_just_prior_to_current_element {
	########GNAWMONITOR("__gnaw__delete_all_elements_from_beginning_to_just_prior_to_current_element BEGIN");
	my $count;

	# starting from current location,
	# back up to the beginning of the line.
	# don't go more than 10 characters
	# and don't go past the beginning marker.
	my $stop = $__gnaw__curr_text_element;
	$count = 10;
	while( 	($count--) and  
		($stop ne $__gnaw__head_text_element)
	){
		$stop = $stop->[__GNAW__PREV];
	}


	my $curr = $__gnaw__head_text_element;
	my $next;
	while ($curr ne $stop) {
		$next = $curr->[__GNAW__NEXT];

		# delete any references in element. set the "what" element to deleted.
		@$curr = (__GNAW__DELETE_WHAT);

		$curr = $next;
	}

	$__gnaw__head_text_element->[__GNAW__NEXT] = $stop;
	$stop->[__GNAW__PREV] = $__gnaw__head_text_element;

	########GNAWMONITOR("__gnaw__delete_all_elements_from_beginning_to_just_prior_to_current_element END");
	return;
}


sub __gnaw__commit_text_to_current_location {
	########GNAWMONITOR;
	__gnaw__call_all_callbacks_from_beginning_to_current_element();
	__gnaw__delete_all_elements_from_beginning_to_just_prior_to_current_element();
	return;
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# text linked list handling subroutines.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub __gnaw__initialize_text_linked_list_to_empty {
	########GNAWMONITOR;

	# if the text linked list currently has data in it, 
	# go through and delete everything in list
	if(defined($__gnaw__head_text_element)) {
		my $element = $__gnaw__head_text_element;
		while(defined($element)) {
			my $next = $element->[__GNAW__NEXT];
			@$element=();
			undef $element;
			$element = $next;
		}

	}

	$__gnaw__head_text_element = [];
	$__gnaw__tail_text_element = [];

	$__gnaw__head_text_element->[__GNAW__WHAT]	= __GNAW__HEADER_WHAT;
	$__gnaw__head_text_element->[__GNAW__PREV]	= undef;
	$__gnaw__head_text_element->[__GNAW__NEXT]	= $__gnaw__tail_text_element;
	$__gnaw__head_text_element->[__GNAW__PAYLOAD]	= '';

	$__gnaw__tail_text_element->[__GNAW__WHAT]	= __GNAW__HEADER_WHAT;
	$__gnaw__tail_text_element->[__GNAW__PREV]	= $__gnaw__head_text_element;
	$__gnaw__tail_text_element->[__GNAW__NEXT]	= undef;
	$__gnaw__tail_text_element->[__GNAW__PAYLOAD]	= '';

	# we will initialize to pointing to tail element.
	# when we add text, if curr pointer is pointing to tail element, then we will
	# add text to the end, and move curr pointer to the previous element.
	# we should never be pointing to the head element, if we do, it may be a bug.
	$__gnaw__curr_text_element  = $__gnaw__tail_text_element;
}


__gnaw__initialize_text_linked_list_to_empty();

sub __gnaw__insert_string_at_end_of_linked_list { #(string)
	my ($string) = @_;
	########GNAWMONITOR("__gnaw__insert_string_at_end_of_linked_list inserting string '$string'");

	my @letters = split(//, $string);

	foreach my $letter (@letters) {
		__gnaw__create_new_element_before_this_element($__gnaw__tail_text_element, __GNAW__LETTER_WHAT, $letter
			######## , 'from __gnaw__insert_string_at_end_of_linked_list'
		);
	}

}


sub __gnaw__insert_string_just_before_marker { #(string, marker)
	my ($string,$marker) = @_;
	########GNAWMONITOR("__gnaw__insert_string_at_end_of_linked_list inserting string '$string'");

	my @letters = split(//, $string);

	foreach my $letter (@letters) {
		__gnaw__create_new_element_before_this_element($marker, __GNAW__LETTER_WHAT, $letter
			######## , 'from __gnaw__insert_string_just_before_marker'
		);
	}
}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# some higher level subroutines for string manipulation
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# assuming start and stop elements are both markers that don't hold text.
# returned string will not include either endpoint markers, start or stop.
sub __gnaw__read_string_between_markers { # (startelement, stopelement)
	########GNAWMONITOR ( "__gnaw__read_string_between_markers" );
	my($startelement, $stopelement) = @_;

	__gnaw__text_element_is_valid($startelement);
	__gnaw__text_element_is_valid($stopelement);

	########GNAWMONITOR("startelement is '$startelement'");
	########GNAWMONITOR("stopelement is '$stopelement'");

	my $string = '';

	my $element = $startelement->[__GNAW__NEXT];

	while( ($element ne  $__gnaw__tail_text_element) and ($element ne $stopelement) ) {
		if($element->[__GNAW__WHAT] == __GNAW__LETTER_WHAT) {
			my $letter = $element->[__GNAW__PAYLOAD];
			$string .= $letter;
		}
		$element = $element->[__GNAW__NEXT];
	}

	return $string;
}


# note neither marker start/stop will be deleted.
sub __gnaw__delete_string_between_markers { # (startelement, stopelement)
	########GNAWMONITOR ( "__gnaw__delete_string_between_markers" );
	my($startelement, $stopelement) = @_;

	__gnaw__text_element_is_valid($startelement);
	__gnaw__text_element_is_valid($stopelement);

	########GNAWMONITOR("startelement is '$startelement'");
	########GNAWMONITOR("stopelement is '$stopelement'");

	my $element = $startelement->[__GNAW__NEXT];

	while( ($element ne  $__gnaw__tail_text_element) and ($element ne $stopelement) ) {
		$element = __gnaw__delete_this_text_element($element);
	}

	return;
}


sub __gnaw__replace_text_between_markers_with_string { #(startmarker, stopmarker, string)
	########GNAWMONITOR ( "__gnaw__replace_text_between_markers_with_string" );
	my($startmarker, $stopmarker, $string) = @_;
	__gnaw__delete_string_between_markers($startmarker, $stopmarker);
	__gnaw__insert_string_just_before_marker($string, $stopmarker); 
	return;
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# low level parsing subroutines.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub __gnaw__at_end_of_input_text { # return boolean
	########GNAWMONITOR;
	if($__gnaw__curr_text_element eq $__gnaw__tail_text_element) {
		return 1;
	} else { 
		return 0;
	}
}


sub __gnaw__move_pointer_forward { # move forward to first text element. delete anything in front of us
	########GNAWMONITOR ("MOVE POINTER FORWARD, CHECKING END OF INPUT");
	if(__gnaw__at_end_of_input_text()) {
		########GNAWMONITOR ("MOVE POINTER FORWARD, AT END PARSE FAILED");
		__gnaw__parse_failed();
		return;
	}
	########GNAWMONITOR ("MOVE POINTER FORWARD, getting next");
	$__gnaw__curr_text_element = $__gnaw__curr_text_element->[__GNAW__NEXT];

	# delete any element that is not a letter. markers, callbacks, etc. all go
	# move forward to first letter element.
	while(	
		    ($__gnaw__curr_text_element ne $__gnaw__tail_text_element) 
		and ($__gnaw__curr_text_element->[__GNAW__WHAT] != __GNAW__LETTER_WHAT)
	) {
		$__gnaw__curr_text_element = __gnaw__delete_this_text_element($__gnaw__curr_text_element);
	}
	return;
}	


sub __gnaw__curr_character { # return current character in text linked list
	########GNAWMONITOR;
	if(__gnaw__at_end_of_input_text()) {
		__gnaw__parse_failed();
		return 'FAIL';
	}

	if($__gnaw__curr_text_element->[__GNAW__WHAT] != __GNAW__LETTER_WHAT) {
		__gnaw__die("tried to call __gnaw__curr_character, but current text element no longer pointing at a letter element");
	}

	return $__gnaw__curr_text_element->[__GNAW__PAYLOAD];
}



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Note: if you create your own "skip" subroutine, make sure it doesn't
# use the __gnaw__curr_character routine because the __gnaw__curr_character 
# will call the "skip" subroutine, and things will go kersplewy.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
our $__gnaw__skip_whitespace = sub{
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	########GNAWMONITOR('skipwhitespace');

	while(1) {
		########GNAWMONITOR('skipwhitespace while 1');
		########GNAWMONITOR('skipwhitespace about to test end of input text');
		if(__gnaw__at_end_of_input_text()) {
			########GNAWMONITOR('skipwhitespace at end of input text');

			return;
		}
		########GNAWMONITOR('skipwhitespace not at end of input text');

		my $letter =  __gnaw__curr_character;

		if(
			($letter eq ' ' ) or
			($letter eq "\t") or
			($letter eq "\n") or
			($letter eq "\f")
		) {
			########GNAWMONITOR('skipwhitespace trying to move pointer forward');
			__gnaw__move_pointer_forward();
		} else {
			return;
		}

	}
};




#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
our $__gnaw__skip_nothing = sub{};
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# change the coderef assigned to this to change what we skip.
# probably want to do it with a "local" command.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
our $__gnaw__skip_code = $__gnaw__skip_whitespace;
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub __gnaw__string_describing_single_text_element { # pass in text element, return string description of element
	my ($curr)=@_; 

	unless(defined($curr)) {
		return "-----reference is undefined--------\n";
	}

	my $final_string ='';

	if($curr eq $__gnaw__curr_text_element) {
		$final_string.= ">>>";
	} else {
		$final_string.= "   ";
	}

	$final_string .= $curr." ";

	if ($curr->[__GNAW__WHAT] == __GNAW__LETTER_WHAT) {
		my $letter = $curr->[__GNAW__PAYLOAD];

		   if($letter eq "\n") { $letter = '\\n'; }
		elsif($letter eq "\t") { $letter = '\\t'; }
		else {$letter = ' '.$letter; }
			$final_string.= $letter;
	} else {
		$final_string .= '  ';
	}

	$final_string.= " : ";

	if($curr eq $__gnaw__head_text_element) {
		$final_string.= "HEAD     ";
	} elsif ($curr eq $__gnaw__tail_text_element){
		$final_string.= "TAIL     ";
	} elsif ($curr->[__GNAW__WHAT] == __GNAW__DELETE_WHAT) {
		$final_string.= "!DELETED!";
	} elsif ($curr->[__GNAW__WHAT] == __GNAW__LETTER_WHAT) {
		$final_string.= "letter   ";
	} elsif ($curr->[__GNAW__WHAT] == __GNAW__MARKER_WHAT) {
		$final_string.= "MARKER   ";
	} elsif ($curr->[__GNAW__WHAT] == __GNAW__CLLBCK_WHAT) {
		$final_string.= "CALLBACK ";
	} elsif ($curr->[__GNAW__WHAT] == __GNAW__HEADER_WHAT) {
		$final_string.= "header   ";
	} else {
		$final_string .= "unknown id number(".($curr->[__GNAW__WHAT]);
	}

	if ($curr->[__GNAW__WHAT] == __GNAW__CLLBCK_WHAT) {
		$final_string .= " ".($curr->[__GNAW__PAYLOAD]);
	}

	my $debug_string = $curr->[__GNAW__DEBUG];
	if(defined($debug_string)) {
		$final_string .= " ".$debug_string;
	}

	$final_string.= "\n";

	return $final_string;
}


sub __gnaw__string_showing_user_current_location_in_text { # return string dump of text linked list
	########GNAWMONITOR;
	my $count;

	# starting from current location,
	# back up to the beginning of the line.
	# don't go past 100 characters
	# and don't go past the beginning marker.
	my $start = $__gnaw__curr_text_element;
	$count = 100;
	while ($count--) {
		if($start eq $__gnaw__head_text_element) {
			$count=0;
		} elsif ($start->[__GNAW__WHAT] == __GNAW__LETTER_WHAT) {
			if($start->[__GNAW__PAYLOAD] eq "\n") {
				$count=0;
			}
		} else {
			$start = $start->[__GNAW__PREV];
		}
	}

	# starting from current 
	# move to the end of the line.
	# don't go past 100 characters
	# and don't go past the end marker.
	my $stop = $__gnaw__curr_text_element;
	$count = 100;
	while ($count--) {
		if($stop eq $__gnaw__tail_text_element) {
			$count=0;
		} elsif ($start->[__GNAW__WHAT] == __GNAW__LETTER_WHAT) {
			if($start->[__GNAW__PAYLOAD] eq "\n") {
				$count=0;
			}
		} else {
			$start = $start->[__GNAW__NEXT];
		}
	}

	# for now, override start and stop to head/tail pointers.
	# we're parsing small enough strings that it isn't a problem.
	$start = $__gnaw__head_text_element;
	$stop = $__gnaw__tail_text_element;


	# now, go from start to stop marker and print out the elements
	my $curr = $start;
	my $final_string='';

	$final_string .= "START\n";
	$final_string .= "__gnaw__string_showing_user_current_location_in_text\n";
	$final_string.= "current element points to ".$__gnaw__curr_text_element."\n";

	my $keepgoing=1;

	while ($keepgoing) {
		$final_string .= __gnaw__string_describing_single_text_element($curr);

		if($curr eq $stop) {
			$keepgoing=0;
		}

		$curr = $curr->[__GNAW__NEXT];
	}

	$final_string .= "END\n";
	return $final_string;
}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



our $__gnaw__processor_still_running;
our $__gnaw__processor_succeeded;


our $__gnaw__processor_instruction_pointer;

sub __gnaw__get_current_instruction_pointer {
	return $__gnaw__processor_instruction_pointer;
}

sub __gnaw__move_current_instruction_pointer {
	my ($newinstruction)=@_;
	$__gnaw__processor_instruction_pointer = $newinstruction;
}


our @__gnaw__fallback_here_on_fail;

sub __gnaw__push_fallback_postition {
	my ($instruction, $textmarker) = @_;

	########GNAWMONITOR("push_fallback_position, instruction '$instruction', marker '$textmarker'");

	push(@__gnaw__fallback_here_on_fail, [$instruction, $textmarker]);
}

sub __gnaw__pop_fallback_postition {
	########GNAWMONITOR("POPPING FALLBACK POSITION");
	if(scalar(@__gnaw__fallback_here_on_fail)==0) {
		__gnaw__die("tried to pop fallback position, but array is empty");
	}
	my $arrref = pop(@__gnaw__fallback_here_on_fail);
	my ($instruction, $textmarker) = @$arrref;
	########GNAWMONITOR("pop_fallback_position, instruction '$instruction', marker '$textmarker'");
	return ($instruction, $textmarker);
}



sub __gnaw__parse_failed {
	########GNAWMONITOR( "__gnaw__parse_failed BEGINNING\n" );

	my ($instruction, $textmarker) = __gnaw__pop_fallback_postition();
	__gnaw__move_current_instruction_pointer($instruction);
	__gnaw__restore_old_text_marker($textmarker);

	# delete the current text marker and all the markers in front of it until we hit text
	while(	($__gnaw__curr_text_element ne $__gnaw__tail_text_element) and
		($__gnaw__curr_text_element->[__GNAW__WHAT] != __GNAW__LETTER_WHAT)
	) {
		__gnaw__delete_this_text_element($__gnaw__curr_text_element);
	}


}






sub generate_stitcher {

	my ($first, $last) = @_;

	my $stitcher = sub {
		my($command, $reference)=@_;

		# getfirst, getlast, setprevious, setnext
		if(0) {

		} elsif($command eq 'getfirst') {
			return $first;
		} elsif($command eq 'getlast') {
			return $last;
		} elsif($command eq 'setprevious') {
			unless(exists($first->{previous})) {
				$first->{previous}=[];
			}
			push(@{$first->{previous}}, $reference);
		} elsif($command eq 'setnext') {
			unless(exists($last->{next})) {
				$last->{next}=[];
			}
			push(@{$last->{next}}, $reference);
		} else {
			die "ERROR: called stitcher with invalid command '$command'";
		}
	};

	# bless stitcher so we can differentiate it from 'CODE' references.
	bless($stitcher,'Parse::Gnaw::Stitcher');

	return $stitcher;
}


sub __gnaw__given_instruction_return_next_instruction {
	my ($currentinstruction) = @_;

	my $nextinstruction = $currentinstruction->{next}->[0];

	return $nextinstruction;
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


sub l {
	my @stitchers;

	while(@_) {
		my $lit = shift(@_);
		if(ref($lit)) {
			die "ERROR: literal function l can only handle strings, not references, '$lit'";
		}
		my $stitcher = __gnaw__literal($lit);
		push(@stitchers, $stitcher);
	}

	my $final_stitcher = series(@stitchers);

	return $final_stitcher;
}

sub __gnaw__separate_string_into_words {
	my ($string)=@_;

	my @words;
	my @letters = split(//, $string);
	push(@letters,' '); # force the last word to get pushed.

	my $current_word;

	while(scalar(@letters)) {
		my $letter = shift(@letters);

		if (
			   ($letter eq " ") 
			or ($letter eq "\t")
			or ($letter eq "\n")
			or ($letter eq "\r")
			or ($letter eq "\f")
		) {
			if(length($current_word)) {
				push(@words, $current_word);
				$current_word = '';
			}
		} else {
			$current_word .= $letter;
		}
	}

	return (@words);
}

sub ql {
	my ($string)=@_;
	my @words = __gnaw__separate_string_into_words($string);

	#warn; print Dumper \@words;

	my $stitcher = l(@words);
	return $stitcher;
}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# __gnaw__literal is the low level, single literal, operation.
# the "l" and "ql" and other functions must break their input
# parameters down into individual calls to __gnaw__literal.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub __gnaw__literal {
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	########GNAWMONITOR( "__gnaw__literal command");
	my ($literal) = @_;
	my @letters = split(//, $literal);

	my $compiled_code = {
		opcode => 'literal',
		coderef=> \&__gnaw__lit_callback,
		value => \@letters,
		debugstring => $literal,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# __gnaw__lit is the callback the parser will call when dealing with a literal.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub __gnaw__lit_callback {
	########GNAWMONITOR( "__gnaw__lit command");
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	########GNAWMONITOR( "__gnaw__lit command: looking for ".($thisinstruction->{debugstring}));

	$__gnaw__skip_code->();

	my $arrref = $thisinstruction->{value};
	my $lastiter = scalar(@$arrref);

	########GNAWMONITOR( "__gnaw__lit command: ". (Dumper $arrref));
	########GNAWMONITOR( "__gnaw__lit command: lastiter=$lastiter");

	########GNAWMONITOR( __gnaw__string_showing_user_current_location_in_text() );

	for(my $iter=0; $iter<$lastiter; $iter++) {
		my $currchar = __gnaw__curr_character();

		if($currchar eq 'FAIL') { return }

		my $litchar = $arrref->[$iter];

		########GNAWMONITOR("__gnaw__lit command: comparing $currchar eq $litchar");
		unless($currchar eq $litchar) {
			__gnaw__parse_failed();
			return;
		} 
		__gnaw__move_pointer_forward();
	}

	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);
}



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub __gnaw__convert_character_class_string_into_hash_ref {
	########GNAWMONITOR;
	my ($characterset)=@_;

	my @chars = split(//, $characterset);

	my $char_set_hash_ref={};

	if($chars[0] eq '-') {
		$char_set_hash_ref->{'-'} = 1;
		shift(@chars);
	}

	while(@chars) {
		my $first = shift(@chars);

		if( (scalar(@chars)>=2) and ($chars[0] eq '-') ){

			my $hyphen = shift(@chars);

			my $last = shift(@chars);

			for my $letter ($first .. $last) {
				$char_set_hash_ref->{$letter} = 1;
			}
		} else {
			$char_set_hash_ref->{$first} = 1;
		}
	}

	#print "\ncharacterset is '$characterset'\n"; print Dumper $char_set_hash_ref;

	return $char_set_hash_ref;
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# character class
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub cc {
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	########GNAWMONITOR( "cc command");
	my ($characterset)=@_;

	my $char_set_hash_ref = 
		__gnaw__convert_character_class_string_into_hash_ref
			($characterset);

	my $compiled_code = {
		opcode => 'character class',
		coderef=> \&__gnaw__cc,
		value => $char_set_hash_ref,
		debugstring => $characterset,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}


sub __gnaw__cc {
	########GNAWMONITOR( "__gnaw__cc command");
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);

	# have to skip. when we do a "get", the get function does a skip
	# if we do a match('b', cc('aeiou'), 'b'), and we dont skip cc function,
	# then this will match only bob, bab, bib, etc.
	# if we do a match('b', get(cc('aeiou'), 'b'), then this will match 'b  ob'.
	# match must be same whether we use "get" or not.
	# therefore the only way to make it consistent is to skip on every 
	# function that looks for text, like literals and character classes.
	$__gnaw__skip_code->();

	########GNAWMONITOR( "__gnaw__cc command: looking for ".($thisinstruction->{debugstring}));

	my $hashref = $thisinstruction->{value};

	########GNAWMONITOR( __gnaw__string_showing_user_current_location_in_text() );

	my $currchar = __gnaw__curr_character();
	if($currchar eq 'FAIL') { return }

	if(exists($hashref->{$currchar})) {
		__gnaw__move_pointer_forward();
	} else {
		__gnaw__parse_failed();
		return;
	}
}



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# inverted character class
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub CC {
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	########GNAWMONITOR( "CC command");
	my ($characterset)=@_;

	my $char_set_hash_ref = 
		__gnaw__convert_character_class_string_into_hash_ref
			($characterset);

	my $compiled_code = {
		opcode => 'inverted_character class',
		coderef=> \&__gnaw__inv_cc,
		value => $char_set_hash_ref,
		debugstring => $characterset,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}


sub __gnaw__inv_cc {
	########GNAWMONITOR( "__gnaw__inv_cc command");
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);

	# have to skip. when we do a "get", the get function does a skip
	# if we do a match('b', cc('aeiou'), 'b'), and we dont skip cc function,
	# then this will match only bob, bab, bib, etc.
	# if we do a match('b', get(cc('aeiou'), 'b'), then this will match 'b  ob'.
	# match must be same whether we use "get" or not.
	# therefore the only way to make it consistent is to skip on every 
	# function that looks for text, like literals and character classes.
	$__gnaw__skip_code->();

	########GNAWMONITOR( "__gnaw__inv_cc command: looking for NOT ".($thisinstruction->{debugstring}));

	my $hashref = $thisinstruction->{value};

	########GNAWMONITOR( __gnaw__string_showing_user_current_location_in_text() );

	my $currchar = __gnaw__curr_character();
	if($currchar eq 'FAIL') { return }

	if(exists($hashref->{$currchar})) {
		__gnaw__parse_failed();
		return;
	} else {
		__gnaw__move_pointer_forward();
	}
}


# character class shortcuts

sub ccdigit { cc('0-9') }
sub CCDIGIT { CC('0-9') }

sub ccword { cc('a-zA-Z0-9_') }
sub CCWORD { CC('a-zA-Z0-9_') }

sub ccspace { cc("\n \t \r \f") }
sub CCSPACE { CC("\n \t \r \f") }

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# "thing" function is equivalent to perl regular expression '.' 
# any single character.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub thing {
	########GNAWMONITOR( "thing command");

	my $compiled_code = {
		opcode => 'thing',
		coderef=> \&__gnaw__thing,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}


sub __gnaw__thing {
	########GNAWMONITOR( "__gnaw__thing command");
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);

	########GNAWMONITOR( __gnaw__string_showing_user_current_location_in_text() );

	# have to skip. when we do a "get", the get function does a skip
	# if we do a match('b', thing, 'b'), and we dont skip cc function,
	# then this will match only bob, bab, bib, etc.
	# if we do a match('b', get(thing), 'b'), then this will match 'b  ob'.
	# match must be same whether we use "get" or not.
	# therefore the only way to make it consistent is to skip on every 
	# function that looks for text, like literals and character classes.
	$__gnaw__skip_code->();

	if(__gnaw__at_end_of_input_text()) {
		__gnaw__parse_failed();
		return;
	} else {
		__gnaw__move_pointer_forward();
	}

}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# gnaw series evaporates into whatever subcommands it consists of.
# there is no __gnaw__series subroutine to handle the series because
# the series dissolves into atomic operations like literals and character classes.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


sub __gnaw__take_grammar_components_and_turn_into_list_of_stitchers {

	my @listofstitchers;

	while(@_) {
		my $component = shift(@_);

		if(ref($component)) {
			if(ref($component) eq 'Parse::Gnaw::Stitcher') {
				push(@listofstitchers, $component);
			} elsif( ref($component) eq 'ARRAY' ) {
				# treat array reference as a "series" function.
				my $stitcher = series(@$component);
				push(@listofstitchers, $stitcher);
			} else {
				die "Error: unknown component passed into function, '$component'";
			}
		} else {
			# for now, assume anything that isn't a reference is a string to be treated as a literal
			my $stitcher = __gnaw__literal($component);
			push(@listofstitchers, $stitcher);
		}
	}

	return (@listofstitchers);
}


sub series {
	########GNAWMONITOR( "series command");
	my @stitcherseries = __gnaw__take_grammar_components_and_turn_into_list_of_stitchers(@_);

	# getfirst, getlast, setprevious, setnext

	# go through all the stitchers in the series and stitch them together.
	for(my $iter=0; $iter<scalar(@stitcherseries); $iter++) {
		my $thisstitch = $stitcherseries[$iter];

		if($iter<(scalar(@stitcherseries)-1)) {
			my $nextstitch = $stitcherseries[$iter+1];
			$thisstitch->('setnext', ($nextstitch->('getfirst')));
			$nextstitch->('setprevious', ($thisstitch->('getlast')));
		}
	}

	my $firststitch = $stitcherseries[0];
	my $laststitch = $stitcherseries[-1];

	my $first = $firststitch->('getfirst');
	my $last = $laststitch->('getlast');

	my $stitcher = generate_stitcher($first, $last);

	return $stitcher;
}



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# alternation command breaks down into three subcommands.
# initialization
# alternation command
# rejoinder
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# callback used by parser when executing an alternate instruction
# we only hit the init command once. Use it to initialize the iterator value
sub __gnaw__alt_init {
	########GNAWMONITOR( "__gnaw__alt_init:");
	my $alt_init_instruction =  __gnaw__get_current_instruction_pointer();
	my $alt_cmd_instruction = __gnaw__given_instruction_return_next_instruction($alt_init_instruction);
	$alt_cmd_instruction->{iterator}=0;
	__gnaw__move_current_instruction_pointer($alt_cmd_instruction);
}

# based off iterator prepare to try another alternate.
sub __gnaw__alt_cmd {
	########GNAWMONITOR( "\n\n\n__gnaw__alt_cmd:");
	my $alt_cmd_instruction = __gnaw__get_current_instruction_pointer();
	my $alt_cmd_fail = $alt_cmd_instruction->{alt_cmd_fail};
	my $iterator = $alt_cmd_instruction->{iterator};
	my $lastiterator = scalar(@{$alt_cmd_instruction->{alternates}});


	# if we're done, we failed to match anything
	if($iterator == $lastiterator) {
		# we created a marker at the beginning of the alternate command
		# now that we've failed, delete the marker
		__gnaw__parse_failed();
		return;
	} else {
		# we're not done, try the next alternate
		$alt_cmd_instruction->{iterator}++;	

		# we created a marker at the beginning of the alternate command
		# create a fallback that will go to that marker if we fail.
		my $textmarker = __gnaw__create_new_marker_before_current_element
			######## ( 'alternation command is going to try another alternate' )
		;	
		__gnaw__push_fallback_postition($alt_cmd_instruction, $textmarker);

		my $nextcmd = $alt_cmd_instruction->{alternates}->[$iterator];
		__gnaw__move_current_instruction_pointer($nextcmd);
	}
}

# callback used by parser when executing an alternate instruction
# the only way we'll hit this instruction is if
# we start down an alternation path and get all teh way to the end.
# i.e. we matched! Woot!
sub __gnaw__alt_rejoinder {
	########GNAWMONITOR( "\n\n\n__gnaw__alt_rejoinder:");

	# we can pop off the fallback position and discard them.
	my ($fallback_cmd, $fallback_marker) = __gnaw__pop_fallback_postition(); 
	# we created this marker at the start of the alternation command. can delete it now.
	__gnaw__delete_this_text_element($fallback_marker);

	my $alt_rej_instruction = __gnaw__get_current_instruction_pointer();
	########GNAWMONITOR( "__gnaw__alt_rejoinder: alt_rej_instruction is '$alt_rej_instruction'");
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($alt_rej_instruction);
	########GNAWMONITOR( "__gnaw__alt_rejoinder: nextinstruction is '$nextinstruction'");
	__gnaw__move_current_instruction_pointer($nextinstruction);
	########GNAWMONITOR( "\n\n\n");
}



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# user function for creating an alternate.
# pass in a series of alternates into call to "a" function.
# each parameter passed in will be treated as a different alternate.
# group components you want to be part of a sequence within an alternate
# by using array references
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub a {
	my @alternates = __gnaw__take_grammar_components_and_turn_into_list_of_stitchers(@_);

	my $alternation_stitcher = __gnaw__alternation(@alternates);

	return $alternation_stitcher;
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# This is useful if you have a bunch of alternates which are all single literals.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub qa {
	my ($string)=@_;
	my @words = __gnaw__separate_string_into_words($string);
	my $stitcher = a(@words);
	return $stitcher;
}

sub __gnaw__alternation {
	########GNAWMONITOR( "alternation command");
	my @alternates = @_;

	my $alt_init = {
		opcode => 'alternationinit',
		coderef => \&__gnaw__alt_init,
	};

	my $alt_cmd = {
		opcode => 'alternationcmd',
		coderef => \&__gnaw__alt_cmd,
		alternates => [],
	};

	my $alt_rejoinder = { 
		opcode => 'alternationrejoinder',
		signifyendof => $alt_cmd,
		coderef => \&__gnaw__alt_rejoinder,
	};

	$alt_cmd->{rejoinder} = $alt_rejoinder;

	my $initializestitcher = generate_stitcher(	$alt_init, 		$alt_init);
	my $alternatestitcher  = generate_stitcher(	$alt_cmd, 		$alt_cmd);
	my $rejoinderstitcher  = generate_stitcher(	$alt_rejoinder, 	$alt_rejoinder);

	# the initialize command goes immediately into the compiled command
	$initializestitcher->('setnext', ($alternatestitcher->('getfirst')));
	$alternatestitcher->('setprevious', ($initializestitcher->('getlast')));


	# getfirst, getlast, setprevious, setnext
	foreach my $subalt (@alternates) {

		my $firstalt = $subalt->('getfirst');
		push(@{$alt_cmd->{alternates}}, $firstalt);

		$alternatestitcher->('setnext', ($subalt->('getfirst')));
		$subalt->('setprevious', ($alternatestitcher->('getlast')));

		$subalt->('setnext', ($rejoinderstitcher->('getfirst')));
		$rejoinderstitcher->('setprevious', ($subalt->('getlast')));

	}

	my $stitcher = generate_stitcher($alt_init, $alt_rejoinder);

	return $stitcher;

}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# greedy command breaks down into five subcommands.
# initialization
# pattern start
# pattern pass
# pattern fail
# rest of grammar
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# callback used by parser when executing an greedy instruction
sub __gnaw__grdy_init {
	my $grdy_init_instruction =  __gnaw__get_current_instruction_pointer();
	my $grdy_patt_start = __gnaw__given_instruction_return_next_instruction($grdy_init_instruction);
	__gnaw__move_current_instruction_pointer($grdy_patt_start);
	$grdy_patt_start->{iterator}=0;
	$grdy_patt_start->{textmarkers}=[];

	# Based on the way we currently handle the fallback markers, 
	# if the minimum quantity is zero, we don't create a fallback to option 0.
	# so we need to specifically check if minimum value is zero, and if so,
	# then create a fallback to the current text marker and rest of grammar instruction
	if($grdy_patt_start->{min}==0) {
		my $grdy_rest_of_grammar = $grdy_patt_start->{grdy_rest_of_grammar};

		my $textmarker =  __gnaw__create_new_marker_before_current_element
			######## ( 'greedy initialization phase creates marker for min quantity of zero' )
		;		
		__gnaw__push_fallback_postition($grdy_rest_of_grammar, $textmarker);
	}

}

# callback used by parser when executing an greedy instruction
sub __gnaw__grdy_patt_start {
	my $grdy_patt_start = __gnaw__get_current_instruction_pointer();
	my $grdy_user_instruction = __gnaw__given_instruction_return_next_instruction($grdy_patt_start);
	__gnaw__move_current_instruction_pointer($grdy_user_instruction);

	my $grdy_patt_fail = $grdy_patt_start->{grdy_patt_fail};

	my $textmarker =  __gnaw__create_new_marker_before_current_element
		######## ( ' greedy pattern start ' )
	;		
	__gnaw__push_fallback_postition($grdy_patt_fail, $textmarker);
}

# callback used by parser when executing an greedy instruction
sub __gnaw__grdy_patt_pass{
	my $grdy_patt_pass = __gnaw__get_current_instruction_pointer();
	my $grdy_patt_start = $grdy_patt_pass->{grdy_patt_start};
	$grdy_patt_start->{iterator}++;
	my $iterator = $grdy_patt_start->{iterator};
	my $min = $grdy_patt_start->{min};
	my $max = $grdy_patt_start->{max};
	my $grdy_rest_of_grammar = $grdy_patt_start->{grdy_rest_of_grammar};

	my $openended = defined($max) ? 0 : 1;

	# when we started pattern, we created a fallback position 
	# at start of text to fallback to the "fail" function.
	# we don't need that fallback position anymore. pop it. and delete it.
	my ($fallback_cmd, $fallback_marker) = __gnaw__pop_fallback_postition(); 
	__gnaw__delete_this_text_element($fallback_marker);

	# if quantifier is consumable
	if($grdy_patt_start->{consumable}) {
		if(0) {
		} elsif ($iterator<$min) {
			# if min is something like "6", and iterator is less than 6,
			# then keep markers around until we reach the minimum.
			push(@{$grdy_patt_start->{textmarkers}}, $fallback_marker);
			__gnaw__move_current_instruction_pointer($grdy_patt_start);	
		} elsif ($iterator==$min) {
			# if we hit the minimum, then go through and delete all the previous markers.
			while(scalar(@{$grdy_patt_start->{textmarkers}})) {
				my $textmarker = pop(@{$grdy_patt_start->{textmarkers}});
				__gnaw__delete_this_text_element($textmarker);
				__gnaw__move_current_instruction_pointer($grdy_patt_start);	
			}
		} else { 
			# elsif ($iterator>$min) {
			# if iterator is greater than minimum, then already deleted all 
			# the previous markers, don't need to do anything with markers anymore.

			# if iterator is less than max, try another pattern
			if($openended or ($iterator<$max)) {
				__gnaw__move_current_instruction_pointer($grdy_patt_start);	
			} else {
				# else go to rest of grammar
				__gnaw__move_current_instruction_pointer($grdy_rest_of_grammar);
			}		

		}
	} else {
		# else quantifier is NOT consumable
		if(0) {

		# if we can try some more
		} elsif($openended or ($iterator<$max)) {

			# if iterator says we matched enough to meet minimum, create fallback to here.
			if($iterator >= $min) {
				# before we try to match another user pattern,
				# create a fallback position at the current text marker
				# with the instruction being "rest of grammar".
				# this means that if quantifier consumes 6, but then 
				# rest of grammar fails, we will fallback to marker for 5
				# and then try the rest of grammar from there.
				my $textmarker =  __gnaw__create_new_marker_before_current_element
					########('__gnaw__grdy_patt_pass creating a fallback position if rest of grammar fails')
				;		
				__gnaw__push_fallback_postition($grdy_rest_of_grammar, $textmarker);
			} # if iterator less than min, don't create a fallback position.
		
			# try another 
			__gnaw__move_current_instruction_pointer($grdy_patt_start);			
		} else {
			# else not open ended and iterator == max, cant try any more, go to rest of grammar
			# if max==6 then no need to create a fallback from here to try rest of grammar.
			# only need a fallback from pattern 5. So, all we need to do here is go to 
			# rest of grammar.
			__gnaw__move_current_instruction_pointer($grdy_rest_of_grammar);
		}
	}
}

# callback used by parser when executing an greedy instruction
sub __gnaw__grdy_patt_fail{
	my $grdy_patt_fail = __gnaw__get_current_instruction_pointer();
	my $grdy_patt_start = $grdy_patt_fail->{grdy_patt_start};
	my $iterator = $grdy_patt_start->{iterator};
	my $min = $grdy_patt_start->{min};

	# the only we hit patt_fail is if we hit patt_start, create a fallback position
	# that is at the last good text, then try to match the user pattern and fail.
	# fail parse will pop fallback position and restor the text marker,
	# so we don't need to pop fallback stack. already taken care of.

	# if we met the minimum, we're ok 
	if($iterator >= $min) {
		my $grdy_rest_of_grammar = $grdy_patt_start->{grdy_rest_of_grammar};
		__gnaw__move_current_instruction_pointer($grdy_rest_of_grammar);
	} else {
		# else we didn't meet minimum, pop off all the fallback markers, then fail.
		while(scalar(@{$grdy_patt_start->{textmarkers}})) {
			my $textmarker = pop(@{$grdy_patt_start->{textmarkers}});
			__gnaw__delete_this_text_element($textmarker);
		}

		__gnaw__parse_failed();
		return;
	}
}

# callback used by parser when executing an greedy instruction
sub __gnaw__grdy_rest_of_grammar {
	my $grdy_rest_instruction =  __gnaw__get_current_instruction_pointer();
	my $grdy_next_instruction = __gnaw__given_instruction_return_next_instruction($grdy_rest_instruction);
	__gnaw__move_current_instruction_pointer($grdy_next_instruction);
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# user function to create a greedy quantifier
# g( [min, max?], grammar component, component...? )
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub g {
	########GNAWMONITOR( "g (greedy) command");

	# g( [min, max?, consumable?], patternstitcher(s), );
	#
	# min must be defined and must be zero or larger and an integer.
	#
	# if max not defined, max is unlimited. if defined, must be 1 or larger and an integer.
	#
	# consumable flag is an optional boolean flag. default to false.
	# if true, pattern is consumable.
	# if false, pattern is NOT consumable.
	#
	# patternstitcher must be defined.
	#

	my $attributes = shift(@_);

	unless(ref($attributes) eq 'ARRAY') {
		die "ERROR: g called but not passed an array reference containing the quantifier attributes. Instead got '$attributes'";
	}

	my $min=shift(@$attributes);

	my $max=undef;

	if(scalar(@$attributes)) {
		$max=shift(@$attributes);
	}

	my $consumable=0;

	if(scalar(@$attributes)) {
		$consumable = shift(@$attributes);
	}

	my $userpattern = series(@_);

	my $grdy_init = {
		opcode => 'greedy init',
		coderef => \&__gnaw__grdy_init,
	};

	my $grdy_patt_start = {
		opcode => 'grdy_patt_start',
		min => $min,
		max => $max,
		consumable => $consumable,
		coderef => \&__gnaw__grdy_patt_start,
	};

	my $grdy_patt_pass = {
		grdy_patt_start => $grdy_patt_start,
		opcode => 'grdy_patt_pass',
		coderef => \&__gnaw__grdy_patt_pass,

	};

	my $grdy_patt_fail = {
		grdy_patt_start => $grdy_patt_start,
		opcode => 'grdy_patt_fail',
		coderef => \&__gnaw__grdy_patt_fail,

	};

	my $grdy_rest_of_grammar = {
		grdy_patt_start => $grdy_patt_start,
		opcode => 'grdy_rest_of_grammar',
		coderef => \&__gnaw__grdy_rest_of_grammar,

	};


	$grdy_patt_start->{grdy_patt_fail}=$grdy_patt_fail;
	$grdy_patt_start->{grdy_rest_of_grammar} = $grdy_rest_of_grammar;

	my $initializestitcher = generate_stitcher(	$grdy_init, 		$grdy_init);
	my $pattstartstitcher  = generate_stitcher(	$grdy_patt_start, 	$grdy_patt_start);
	my $pattpassstitcher   = generate_stitcher(	$grdy_patt_pass, 	$grdy_patt_pass);

	# the initialize command goes immediately into the pattern command
	$initializestitcher->('setnext', ($pattstartstitcher->('getfirst')));
	$pattstartstitcher->('setprevious', ($initializestitcher->('getlast')));

	$pattstartstitcher->('setnext', ($userpattern->('getfirst')));
	$userpattern->('setprevious', ($pattstartstitcher->('getlast')));

	$userpattern->('setnext', ($pattpassstitcher->('getfirst')));
	$pattpassstitcher->('setprevious', ($userpattern->('getlast')));

	my $stitcher = generate_stitcher($grdy_init, $grdy_rest_of_grammar);

	return $stitcher;
}


# greedy shortcuts

sub any  { g([0], @_) }		# zero or more
sub some { g([1], @_) }		# one or more

sub anything  { any (thing) } 	# zero or more 'things'
sub something { some(thing) }	# one or more 'things'

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# thrifty command breaks down into five subcommands.
# initialization
# pattern start
# pattern pass
# pattern fail
# rest of grammar
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# callback used by parser when executing a thrifty instruction
sub __gnaw__tfty_init {
	my $tfty_init_instruction =  __gnaw__get_current_instruction_pointer();
	my $tfty_patt_start = __gnaw__given_instruction_return_next_instruction($tfty_init_instruction);
	$tfty_patt_start->{iterator}=0;
	$tfty_patt_start->{textmarkers}=[];

	# if minimum is zero, then 
	# set a fallback to try another pattern and then jump to the rest of grammar
	if($tfty_patt_start->{min}==0) {
		my $tfty_rest_of_grammar = $tfty_patt_start->{tfty_rest_of_grammar};
		__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);

		my $textmarker =  __gnaw__create_new_marker_before_current_element
			######## ( ' thrifty init phase creating a marker for minimum of zero matches, will fallback here if rest of grammar fails.') 
		;		
		__gnaw__push_fallback_postition($tfty_patt_start, $textmarker);
	} else {
		# otherwise, minimum is greater than zero, so go try a pattern.
		__gnaw__move_current_instruction_pointer($tfty_patt_start);
	}

}

# callback used by parser when executing a thrifty instruction
sub __gnaw__tfty_patt_start {
	my $tfty_patt_start = __gnaw__get_current_instruction_pointer();
	my $tfty_user_instruction = __gnaw__given_instruction_return_next_instruction($tfty_patt_start);
	__gnaw__move_current_instruction_pointer($tfty_user_instruction);

	my $tfty_patt_fail = $tfty_patt_start->{tfty_patt_fail};

	my $textmarker =  __gnaw__create_new_marker_before_current_element
		######## ( '__gnaw__tfty_patt_start fallback position at start of pattern ' )
	;		
	__gnaw__push_fallback_postition($tfty_patt_fail, $textmarker);
}

# callback used by parser when executing a thrifty instruction
sub __gnaw__tfty_patt_pass{
	########GNAWMONITOR("__gnaw__tfty_patt_pass BEGIN");
	my $tfty_patt_pass = __gnaw__get_current_instruction_pointer();
	my $tfty_patt_start = $tfty_patt_pass->{tfty_patt_start};
	$tfty_patt_start->{iterator}++;
	my $iterator = $tfty_patt_start->{iterator};
	my $min = $tfty_patt_start->{min};
	my $max = $tfty_patt_start->{max};
	my $tfty_rest_of_grammar = $tfty_patt_start->{tfty_rest_of_grammar};

	my $openended = defined($max) ? 0 : 1;
	# when we started pattern, we created a fallback position 
	# at start of text to fallback to the "fail" function.
	# we don't need that fallback position anymore. pop it. and delete it.
	my ($fallback_cmd, $fallback_marker) = __gnaw__pop_fallback_postition(); 
	__gnaw__delete_this_text_element($fallback_marker);

	# if quantifier is consumable
	if($tfty_patt_start->{consumable}) {
		########GNAWMONITOR("__gnaw__tfty_patt_pass consumable");
		if(0) {
		} elsif ($iterator<$min) {
			# if min is something like "6", and iterator is less than 6,
			# then keep markers around until we reach the minimum.
			push(@{$tfty_patt_start->{textmarkers}}, $fallback_marker);
			__gnaw__move_current_instruction_pointer($tfty_patt_start);	
		} elsif ($iterator==$min) {
			# if we hit the minimum, then go through and delete all the previous markers.
			while(scalar(@{$tfty_patt_start->{textmarkers}})) {
				my $textmarker = pop(@{$tfty_patt_start->{textmarkers}});
				__gnaw__delete_this_text_element($textmarker);
				__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);
			}
		} else { 
			# elsif ($iterator>$min) {
			# if iterator is greater than minimum, then already deleted all 
			# the previous markers, don't need to do anything with markers anymore

			# if iterator is less than max, set fallback position to try another pattern
			if($openended or ($iterator<$max)) {
				my $textmarker =  __gnaw__create_new_marker_before_current_element
					######## ( " __gnaw__tfty_patt_pass set fallback position to try another pattern " )
				;		
				__gnaw__push_fallback_postition($tfty_patt_start, $textmarker);

				__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);	
			} else {
				# else go to rest of grammar, if it fails, we can't try anymore, so no fallback
				__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);
			}		
		}
	} else {
		# else quantifier is NOT consumable
		########GNAWMONITOR("__gnaw__tfty_patt_pass NOT consumable");

		if(0) {

		# if we can try some more
		} elsif($openended or ($iterator<$max)) {

			########GNAWMONITOR("__gnaw__tfty_patt_pass if we can try some more");
			# if iterator says we matched enough to meet minimum, create fallback to here.
			if($iterator >= $min) {
				########GNAWMONITOR("__gnaw__tfty_patt_pass iterator>=min");
				# create a fallback position at the current text marker
				# with the instruction being 'try another pattern'
				my $textmarker =  __gnaw__create_new_marker_before_current_element
					######## ( " __gnaw__tfty_patt_pass create a fallback position to try another pattern " )
				;		
				__gnaw__push_fallback_postition($tfty_patt_start, $textmarker);

				# now go try rest of grammar. if it fails, we'll try another pattern
				__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);			
			} else {
				########GNAWMONITOR("__gnaw__tfty_patt_pass haven't matched enough paterns to hit minimum");
				# else we haven't matched enough paterns to hit minimum. do another patern
				__gnaw__move_current_instruction_pointer($tfty_patt_start);			
			}
		} else {
			########GNAWMONITOR("__gnaw__tfty_patt_pass cant try any more");
			# else not open ended and iterator == max, cant try any more, go to rest of grammar
			# if max==6 then no need to create a fallback 
			__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);
		}
	}
	########GNAWMONITOR("__gnaw__tfty_patt_pass END");
}

# callback used by parser when executing a thrifty instruction
sub __gnaw__tfty_patt_fail{
	my $tfty_patt_fail = __gnaw__get_current_instruction_pointer();
	my $tfty_patt_start = $tfty_patt_fail->{tfty_patt_start};
	my $iterator = $tfty_patt_start->{iterator};
	my $min = $tfty_patt_start->{min};

	# the only way we hit patt_fail is if we hit patt_start, create a fallback position
	# that is at the last good text, then try to match the user pattern and fail.
	# fail parse will pop fallback position and restore the text marker,
	# so we don't need to pop fallback stack. already taken care of.

	# if we met the minimum, we're ok 
	if($iterator >= $min) {
		my $tfty_rest_of_grammar = $tfty_patt_start->{tfty_rest_of_grammar};
		__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);
	} else {
		# else we didn't meet minimum, pop off all the fallback markers, then fail.
		while(scalar(@{$tfty_patt_start->{textmarkers}})) {
			my $textmarker = pop(@{$tfty_patt_start->{textmarkers}});
			__gnaw__delete_this_text_element($textmarker);
		}

		__gnaw__parse_failed();
		return;
	}
}

# callback used by parser when executing a thrifty instruction
sub __gnaw__tfty_rest_of_grammar {
	my $tfty_rest_instruction =  __gnaw__get_current_instruction_pointer();
	my $tfty_next_instruction = __gnaw__given_instruction_return_next_instruction($tfty_rest_instruction);
	__gnaw__move_current_instruction_pointer($tfty_next_instruction);
}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# user function to create a greedy quantifier
# g( [min, max?], grammar component, component...? )
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub t {
	########GNAWMONITOR( "thrifty command");

	# t ( [min, max?, consumable?] , patternstitcher(s) );
	#
	# min must be defined, must be zero or larger, and an integer.
	#
	# if max not defined, max is unlimited. if defined, must be 1 or larger and an integer.
	#
	# consumable flag is an optional boolean flag. default to false.
	# if true, pattern is consumable.
	# if false, pattern is NOT consumable.
	#
	# patternstitcher must be defined.

	my $attributes = shift(@_);

	unless(ref($attributes) eq 'ARRAY') {
		die "ERROR: t called but not passed an array reference containing the quantifier attributes. Instead got '$attributes'";
	}

	my $min=shift(@$attributes);

	my $max=undef;

	if(scalar(@$attributes)) {
		$max=shift(@$attributes);
	}

	my $consumable=0;

	if(scalar(@$attributes)) {
		$consumable = shift(@$attributes);
	}

	my $userpattern = series(@_);



	my $tfty_init = {
		opcode => 'thrifty init',
		coderef => \&__gnaw__tfty_init,
	};

	my $tfty_patt_start = {
		opcode => 'tfty_patt_start',
		min => $min,
		max => $max,
		consumable => $consumable,
		coderef => \&__gnaw__tfty_patt_start,
	};

	my $tfty_patt_pass = {
		tfty_patt_start => $tfty_patt_start,
		opcode => 'tfty_patt_pass',
		coderef => \&__gnaw__tfty_patt_pass,

	};

	my $tfty_patt_fail = {
		tfty_patt_start => $tfty_patt_start,
		opcode => 'tfty_patt_fail',
		coderef => \&__gnaw__tfty_patt_fail,

	};

	my $tfty_rest_of_grammar = {
		grdy_patt_start => $tfty_patt_start,
		opcode => 'tfty_rest_of_grammar',
		coderef => \&__gnaw__tfty_rest_of_grammar,

	};


	$tfty_patt_start->{tfty_patt_fail}=$tfty_patt_fail;
	$tfty_patt_start->{tfty_rest_of_grammar} = $tfty_rest_of_grammar;

	my $initializestitcher = generate_stitcher(	$tfty_init, 		$tfty_init);
	my $pattstartstitcher  = generate_stitcher(	$tfty_patt_start, 	$tfty_patt_start);
	my $pattpassstitcher   = generate_stitcher(	$tfty_patt_pass, 	$tfty_patt_pass);

	# the initialize command goes immediately into the pattern command
	$initializestitcher->('setnext', ($pattstartstitcher->('getfirst')));
	$pattstartstitcher->('setprevious', ($initializestitcher->('getlast')));

	$pattstartstitcher->('setnext', ($userpattern->('getfirst')));
	$userpattern->('setprevious', ($pattstartstitcher->('getlast')));

	$userpattern->('setnext', ($pattpassstitcher->('getfirst')));
	$pattpassstitcher->('setprevious', ($userpattern->('getlast')));

	my $stitcher = generate_stitcher($tfty_init, $tfty_rest_of_grammar);

	return $stitcher;
}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# "now" is executed every time the parser hits that branch of the grammar
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub now {
	my ($coderef)=@_;

	my $closure = sub {
		$coderef->();

		my $thisinstruction = __gnaw__get_current_instruction_pointer();
		my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
		__gnaw__move_current_instruction_pointer($nextinstruction);
	};

	my $compiled_code = {
		opcode => 'now',
		coderef=> $closure,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# "defer" is scheduled for execution but is only called if the grammar matches
# that interpretation.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub defer {
	my ($coderef) = @_;

	my $closure = sub {
		__gnaw__create_new_element_before_current_element(__GNAW__CLLBCK_WHAT, $coderef
			######## , 'defer callback'
		); # callback same as code except for this line.

		my $thisinstruction = __gnaw__get_current_instruction_pointer();
		my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
		__gnaw__move_current_instruction_pointer($nextinstruction);
	};

	my $compiled_code = {
		opcode => 'defer',
		coderef=> $closure,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# commit command is an immediate commitment to the current interpretation
# of the grammar to the string being parsed. It causes any callbacks
# from the beginning of the string to the current pointer to be executed
# and it deletes the text from beginning of string to 10 characters
# before the current pointer.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub commit {
	return now(\&__gnaw__commit_text_to_current_location);
}


my @__gnaw__array_of_get_initializers_so_far;

sub get {
	my $first_parameter = shift(@_);

	my $callback;
	my $initialize;

	if(ref($first_parameter) eq 'SCALAR') {
		my $initvalue = $$first_parameter;
		$callback = sub { $$first_parameter = shift(@_); };
		$initialize = sub { $$first_parameter = $initvalue; }
	} elsif (ref($first_parameter) eq 'ARRAY') {
		$callback = sub { push(@$first_parameter, shift(@_)); };
		$initialize = sub { @$first_parameter = (); };
	} elsif (ref($first_parameter) eq 'CODE') {
		$callback = $first_parameter;
	} elsif (ref($first_parameter) eq 'HASH') {
		my $callback = $first_parameter->{get};
		my $initialize = $first_parameter->{init};
	} else {
		die "ERROR: get doesn't know how to handle first parameter '$first_parameter'";
	}


	if(defined($initialize)) {
		push(@__gnaw__array_of_get_initializers_so_far, $initialize);
	}

	my $retval = __gnaw__get($callback, @_);

	return $retval;
}

sub __gnaw__generate_initialization_routine_for_get_callbacks_so_far {
	my $localroutines = [];

	@$localroutines = @__gnaw__array_of_get_initializers_so_far;

	@__gnaw__array_of_get_initializers_so_far=();

	my $init_routine = sub {
		foreach my $routine (@$localroutines) {
			$routine->();
		}
	};

	return $init_routine;
}

sub __gnaw__get {

	my $user_call_back = shift(@_);

	my $enclosedstitcher;

	if(scalar(@_) == 0) {
		die "ERROR: need to pass at least two parameters to 'get' function";
	} else {
		$enclosedstitcher = series(@_);
	}

	# the first opcode is a "now" instruction that immediately gets text marker.
	# the second opcode is a "now" instruction that gets the end text marker
	# and schedules the user callback there is a match. (i.e. "defer" it).

	my $begintextmarker;

	my $beginstitcher = now(sub{
		########GNAWMONITOR("GET function, BEGIN opcode, about to skip whitespace");
		$__gnaw__skip_code->();
		########GNAWMONITOR("GET function, BEGIN opcode, about to create start marker");
		$begintextmarker =  __gnaw__create_new_marker_before_current_element
			######## ( 'get function creating start marker' )
		;		
		########GNAWMONITOR("GET function, BEGIN opcode, created start marker, '$begintextmarker'");
	});
	my $get_begin = $beginstitcher->('getfirst');
	$get_begin->{opcode} = 'get_begin';


	my $endstitcher = now(sub{
		########GNAWMONITOR("GET function, END opcode, about to create end marker");
		my $endtextmarker =  __gnaw__create_new_marker_before_current_element		
			######## ( 'get function creating end marker' )
		;

		# need to make a copy of the markers NOW because they may change 
		# by the time the defered callback to "get" occurs.
		# these copies will be contained in the subroutine closure at the time its closed.
		my $beginmarkercopy = $begintextmarker;
		my $endmarkercopy   = $endtextmarker;

		########GNAWMONITOR("GET function, BEGIN opcode, created start marker, '$endtextmarker'");
		my $call_back_with_string = sub {
			########GNAWMONITOR("GET function, callback function, about to read string between markers $begintextmarker and $endtextmarker");
			my $string = __gnaw__read_string_between_markers
				($beginmarkercopy,$endmarkercopy);
			########GNAWMONITOR("GET function, callback function, string is '$string', about to pass to user function '$user_call_back'");
			$user_call_back->($string);
		};
		__gnaw__create_new_element_before_current_element(__GNAW__CLLBCK_WHAT, $call_back_with_string
			######## , " 'get' function created callback, markers are $begintextmarker,$endtextmarker  "
		);
	});
	my $get_end = $endstitcher->('getfirst');
	$get_end->{opcode} = 'get_end';

	# the begin-get instruction goes in front of the enclosed stitcher
	$beginstitcher->('setnext', ($enclosedstitcher->('getfirst')));
	$enclosedstitcher->('setprevious', ($beginstitcher->('getlast')));

	# the end of the enclosed stitcher comes before the end-get instruction
	$enclosedstitcher->('setnext', ($endstitcher->('getfirst')));
	$endstitcher->('setprevious', ($enclosedstitcher->('getlast')));


	# flatten this chunk of code out so that we start at get_begin and
	# end at get_end. the enclosed_stitcher is enclosed by the get instructions.
	# return the stitcher for this overall chunk of grammar.
	my $stitcher = generate_stitcher($get_begin, $get_end);

	return $stitcher;
}



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# outer functions
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



sub parse {
	########GNAWMONITOR( "parse command begin");

	my $stitcher=series(@_);

	# once we've processed the parameters passed into 'parse',
	# all the grammar components have been executed.
	# this means we can now generate the callback to initialize
	# all "get" variables and subroutines.
	my $variableinitroutine = __gnaw__generate_initialization_routine_for_get_callbacks_so_far();

	my $pars_init = {
		opcode => 'parseinit',
		coderef => sub {
			########GNAWMONITOR;
			$variableinitroutine->(); 

			my $thisinstruction = __gnaw__get_current_instruction_pointer();
			my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
			__gnaw__move_current_instruction_pointer($nextinstruction);

			my $parse_fail_instr = $thisinstruction->{parse_fail_instr};
			########GNAWMONITOR("parse init about to push text marker");
			my $textmarker =  __gnaw__create_new_marker_before_current_element
				######## ( ' parse initialization instruction creating fallback marker ' )
			;		
			__gnaw__push_fallback_postition($parse_fail_instr, $textmarker);
			########GNAWMONITOR("parse init finished pushing text marker");

		},
	};

	########GNAWMONITOR("parse init hash ref is $pars_init");

	my $pars_rejoinder = {
		opcode => 'parserejoinder',
		signifyendof => $pars_init,
		coderef => sub{
			########GNAWMONITOR("Parse rejoinder starting");
			$__gnaw__processor_still_running=0;
			$__gnaw__processor_succeeded=1;
			########GNAWMONITOR(__gnaw__string_showing_user_current_location_in_text);
			__gnaw__commit_text_to_current_location;
		},
	};

	########GNAWMONITOR("parse rejoinder hash ref is $pars_rejoinder");

	my $pars_failure = {
		opcode => 'parserefailure',
		signifyendof => $pars_init,
		coderef => sub{
			########GNAWMONITOR("in PARSE FAILURE");
			$__gnaw__processor_still_running=0;
			$__gnaw__processor_succeeded=0;
		},
	};

	########GNAWMONITOR("parse failure hash ref is $pars_failure");

	$pars_init->{rejoinder}=$pars_rejoinder;
	$pars_init->{parse_fail_instr} = $pars_failure;

	my $parsestitcher = generate_stitcher(	  $pars_init, 		$pars_init);
	my $rejoinderstitcher = generate_stitcher($pars_rejoinder, 	$pars_rejoinder);

	
	# getfirst, getlast, setprevious, setnext
	$parsestitcher->('setnext', ($stitcher->('getfirst')));
	$stitcher->('setprevious', ($parsestitcher->('getlast')));

	$stitcher->('setnext', ($rejoinderstitcher->('getfirst')));
	$rejoinderstitcher->('setprevious', ($stitcher->('getlast')));


	my $call_back = sub {
		my ($string) = @_;

		__gnaw__initialize_text_linked_list_to_empty();
		__gnaw__insert_string_at_end_of_linked_list($string);

		########GNAWMONITOR("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nend string initialization\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");

		########GNAWMONITOR(__gnaw__string_showing_user_current_location_in_text());

		$__gnaw__processor_still_running=1;
		$__gnaw__processor_succeeded=0;
		$__gnaw__processor_instruction_pointer = $pars_init;




		__gnaw__process_commands();

		return $__gnaw__processor_succeeded;
	};

	########GNAWMONITOR( "parse command end");

	return $call_back;
}


sub match {
	########GNAWMONITOR( "match command begin");

	my $stitcher=series(@_);

	# once we've processed the parameters passed into 'match',
	# all the grammar components have been executed.
	# this means we can now generate the callback to initialize
	# all "get" variables and subroutines.
	my $variableinitroutine = __gnaw__generate_initialization_routine_for_get_callbacks_so_far();

	my $match_init = {
		opcode => 'match_init',
		coderef => sub {
			$variableinitroutine->(); 

			my $thisinstruction = __gnaw__get_current_instruction_pointer();
			my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
			__gnaw__move_current_instruction_pointer($nextinstruction);
		},
	};

	my $match_pattern;
	$match_pattern = {
		opcode => 'match_pattern',
		coderef => sub {
			########GNAWMONITOR( "match_pattern");
			if(__gnaw__at_end_of_input_text) {
				########GNAWMONITOR("match pattern at end of string");
				$__gnaw__processor_still_running=0;
				$__gnaw__processor_succeeded=0;
				return;
			}

			########GNAWMONITOR( "match_pattern about to create fallback");
			my $match_failure = $match_pattern->{match_failure};
			my $textmarker =  __gnaw__create_new_marker_before_current_element 
				######## ( ' match pattern function creating fallback marker ' )
			;		
			__gnaw__push_fallback_postition($match_failure, $textmarker);

			my $thisinstruction = __gnaw__get_current_instruction_pointer();
			my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
			__gnaw__move_current_instruction_pointer($nextinstruction);
		},
	};

	my $match_rejoinder = {
		opcode => 'match_rejoinder',
		signifyendof => $match_pattern,
		coderef => sub{
			# pop off the old fallback position, don't need it anymore.
			my $instruction;
			my $textmarker;
			__gnaw__pop_fallback_postition($instruction, $textmarker);
			__gnaw__delete_this_text_element($textmarker);

			$__gnaw__processor_still_running=0;
			$__gnaw__processor_succeeded=1;
			########GNAWMONITOR(__gnaw__string_showing_user_current_location_in_text);
			__gnaw__commit_text_to_current_location;
		},
	};

	my $match_failure = {
		opcode => 'match_failure',
		signifyendof => $match_pattern,
		coderef => sub{
			__gnaw__move_pointer_forward();
			# we created a fallback, tried to parse, failed, and fellback to where we were
			# If we can move current position forward, then do that and jump to match pattern
			# if we can't move current position forward, we're out of text, fail.
			if(__gnaw__at_end_of_input_text) {
				########GNAWMONITOR("match failure at end of string");
				$__gnaw__processor_still_running=0;
				$__gnaw__processor_succeeded=0;
			} else {
				########GNAWMONITOR("match failure NOT at end of string");
				__gnaw__move_current_instruction_pointer($match_pattern);
			}
		},
	};

	my $match_cant_try_anymore = {
		opcode => 'match_cant_try_anymore',
		signifyendof => $match_pattern,
		coderef => sub{
			########GNAWMONITOR("match_cant_try_anymore");
			$__gnaw__processor_still_running=0;
			$__gnaw__processor_succeeded=0;

			# delete the current text marker
			# we inserted it at the start of the "match" function.
			# move pointer to next element.
			__gnaw__delete_this_text_element($__gnaw__curr_text_element);
		},
	};

	$match_init ->{rejoinder}=$match_rejoinder;
	$match_pattern ->{rejoinder}=$match_rejoinder;
	$match_pattern ->{match_failure} = $match_failure;

	my $initstitcher = generate_stitcher(	  $match_init, 		$match_init);
	my $matchstitcher = generate_stitcher(	  $match_pattern,	$match_pattern);
	my $rejoinderstitcher = generate_stitcher($match_rejoinder, 	$match_rejoinder);

	
	# getfirst, getlast, setprevious, setnext
	$initstitcher->('setnext', ($matchstitcher->('getfirst')));
	$matchstitcher->('setprevious', ($initstitcher->('getlast')));

	$matchstitcher->('setnext', ($stitcher->('getfirst')));
	$stitcher->('setprevious', ($matchstitcher->('getlast')));

	$stitcher->('setnext', ($rejoinderstitcher->('getfirst')));
	$rejoinderstitcher->('setprevious', ($stitcher->('getlast')));


	my $call_back = sub {
		my ($string) = @_;

		__gnaw__initialize_text_linked_list_to_empty();
		__gnaw__insert_string_at_end_of_linked_list($string);

		########GNAWMONITOR("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nend string initialization\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");

		$__gnaw__processor_still_running=1;
		$__gnaw__processor_succeeded=0;
		$__gnaw__processor_instruction_pointer = $match_init;

		__gnaw__process_commands();

		return $__gnaw__processor_succeeded;
	};

	########GNAWMONITOR( "match command end");

	return $call_back;
}



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# this is the parsing engine that executes the compiled grammar.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


sub __gnaw__process_commands {
	########GNAWMONITOR( "process_commands: ");
	while($__gnaw__processor_still_running) {
		########GNAWMONITOR( "process_commands: while still running");
		my $instruction =  __gnaw__get_current_instruction_pointer();
		########GNAWMONITOR( "process_commands: instruction is '$instruction'");
		########GNAWMONITOR( "process_commands: opcode is '". ($instruction->{opcode})."'");
		my $coderef = $instruction->{coderef};
		########GNAWMONITOR( "process_commands: coderef is '$coderef'");
		$coderef->();
	}
}






=head1 INTERNALS

These are notes to developers who may need to understand how
the internals of Parse::Gnaw operate so they can create 
advanced grammars.

Also, these are notes to myself to remember how things function.

=head2 Text being parsed.

The text being parsed is held internally in a linked list. 
This allows Parse::Gnaw to operate on a small subset of the 
entire string being parsed. Theoretically, Parse::Gnaw can 
parse an infinite amount of text as long as it can be 
parsed in chunks small enough that the rules can disambiguate 
text that fits in memory.

Each element in the linked list is an array. 

Array stores the following data: 

	0: numeric indicator of what type of element this is
	1: payload
	2: previous element pointer
	3: next element pointer
	4: used for debugging

There are several "types" of elements as indicated by the
value in index 0 of an element:

	0: element has been deleted. If code tries to use 
		a deleted element, this should act as a 
		flag that something went wrong
	1: element holds a single text character. 
		letter is stored in payload index.
	2: element holds a "marker". Markers are placed between
		text elements by the parser to keep track of
		where it is in the code, where captured strings
		are located, where to fallback to in the text
		if a particular branch of a parse fails, etc.
		A marker contains no payload.
	3: element contains a callback to be executed on
		successful completion of parsing or a commit.
		Payload contains code ref to callback.
	4: element is a head/tail endpoint

The linked list starts and ends with two signpost elements:
'head' and 'tail'. No text is ever stored in these signpost
elements. Any text being parsed is always contained between
these two signpost elements.

The 'current' pointer always points to the text that is about
to be processed.

When the __gnaw__parse_failed function is called, it will
pop the last fallback position off the fallback array, 
which will change the next instruction to be executed and
will also move the text pointer back to teh fallback marker.
The last thing the __gnaw__parse_failed function does is
delete the fallback marker and any other elements in the
text linked list that are not text.

When any instruction moves the text pointer forward, it
will also delete any old markers it encounters.

The current pointer may point to the tail signpost element.
This may mean that we are at the end of the string, or it
may mean that the next time we try to get the current letter
that we need to insert more text from a file or something.

All interfaces to the linked list should be through the 
subroutines designed for working with the linked list.
These start with the prefix "__gnaw__" to help prevent
subroutine colisions.

All parse level commands should manipulate text based on markers.

No user-level or grammar-level commands are currently supported.
You can always call the __gnaw__* functions, but they are
currently subject to change.

=head2 Generating the Parser

tbd


=cut

=head1 AUTHOR

Greg London, C<< <email at greglondon.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-parse-gnaw at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Gnaw>.  I will be notified, and then you will
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Gnaw


You can also look for information at:

=over 4

=item * RT: CPANs request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Gnaw>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Gnaw>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Parse-Gnaw>

=item * Search CPAN

L<http://search.cpan.org/dist/Parse-Gnaw>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Greg London, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Parse::Gnaw
