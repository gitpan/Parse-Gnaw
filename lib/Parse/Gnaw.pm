
1; 
{ 
package Parse::Gnaw; 
our $VERSION = '0.20'; 
}  
1;

use warnings;
use strict;
use Data::Dumper; 



# these two subroutines are used to turn on/off debugging info
sub GNAWMONITOR {} 

sub GNAWMONITOR_0  {
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



sub __gnaw__die {
	my ($message)=@_;
	my $location = __gnaw__string_showing_user_current_location_in_text();
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

If you call the grammar multiple times to parse different strings,
or if your grammar gets more than one match while it parses,
the scalar reference only holds the last match.


	my $name;

	$grammar = match('hello', get(\$name, some(ccword)), '!' );
	$grammar->('hello Alice !');
	$grammar->('hello Bob !');
	$grammar->('hello Charlie !');

	print "name is '$name'\n";

	> name is 'Charlie'

If the first parameter is an array reference, then every match
by the "get" function will get pushed into the array. 

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

Note that the parser will call the subroutine at the beginning of
parsing to allow you to initialize anything. You can detect the
initialization phase by the fact that @_ is empty. If you do not 
need to initialize anything, simply insert the following as the first 
line in your subroutine. 

	return unless(scalar(@_))

Here is an example of "get" using a subroutine reference.

	my $name = sub{
		if(scalar(@_)==0) {
			# open a file, etc
		} else {
			my ($string) = @_;
			# write $string to a file, or whatever
			print "called subroutine, received '$string'\n";
		}
	};

	$grammar = match('hello', get($name, some(ccword)), '!' );

	$grammar->('hello Alice !');

	> called subroutine, received 'Alice'


The remaining parameters of the "get" function are one or more 
grammar components. Literals, character classes, alternations, 
quantifiers, array refs used for grouping sequences of grammar
components, etc.

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

#####################################################################
#####################################################################
#####################################################################
#####################################################################

#####################################################################
#####################################################################
#####################################################################
#####################################################################

#####################################################################
#####################################################################
#####################################################################
#####################################################################





####################################################################
####################################################################
####################################################################
# text is linked list to allow adding new and removing old
####################################################################
####################################################################
####################################################################
# text to parse is a linked list.

sub __GNAW__PREV {0;}

sub __GNAW__NEXT {1;}

sub __GNAW__LETTER {2;}

# this is always the last element.
# we use this in several for loops to do things to an element.
sub __GNAW__LOCATION_MARKERS {3;}



# these two elements never get deleted
our $__gnaw__head_text_element    ;
our $__gnaw__tail_text_element    ;

# keep a pointer to current position in text.
our $__gnaw__curr_text_element ;  


##################################################################### text linked list markers
##################################################################### explaining "markers" to text in linked list.
# sometimes we might want to remember where we are in the text linked list.
# such as in a "capture" command, so we can remember start of capture.
# however, as text is consumed, the text being pointed to may no longer exist.
# so, rather than just making a copy of the current pointer, we create a "marker".
# a marker is a pointer to a pointer. 
# When we want a text marker, we create a scalar, then we initilize that scalar
# to be a reference to the current text element. then we return a reference to 
# that scalar. The scalar exists in the heap because it is declared by "my" in
# the "get new marker", but a reference to it is returned, so it isn't garbage
# collected. 
# it might be nice to make the marker a hash so we can store info in it, but 
# that might create a lot of memory overhead and slow execution down.
#
# note that to do any operation on a marker, a scalar must be passed in as the
# first parameter. This will be the marker. this will help us make sure there
# are no old markers laying around.
####################################################################

# receive a marker and return a pointer to the text element in linked list being pointed to
# using a sub call in case I want to change how markers work.
sub __gnaw__text_element_pointed_to_by_marker {
	my $markerref = $_[0];

	GNAWMONITOR($markerref);
	unless(defined($markerref)) {
		return undef;
	}

	if(ref($markerref) eq 'CODE') {
		print "ERROR: called __gnaw__text_element_pointed_to_by_marker and didn't pass it a marker\n";
		print "Instead of a marker, a code reference was passed in.\n";
		die;
	}

	# individual text elements are arrays.
	# elements are chained together as a linked list.
	if(ref($$markerref) eq 'ARRAY') {
		return $$markerref;
	} 

	print "ERROR: called __gnaw__text_element_pointed_to_by_marker and passed it a reference to something not a marker\n";
	print Dumper $markerref;
	die "ERROR: bad text marker";
	return undef;

}

our $__gnaw__universal_undefined_scalar;

sub __gnaw__have_marker_point_to_element {
	my ($markerref, $element) = @_;

	if(defined($element)) {
		$$markerref = $element;
	} else {
		undef $$markerref;
		$$markerref = $__gnaw__universal_undefined_scalar;
	}
}


sub __gnaw__get_current_text_marker {
	GNAWMONITOR;

	my $marker;
	$marker = $__gnaw__curr_text_element;

	my $markerref = \$marker;

	push(@$__gnaw__curr_text_element, $markerref);
	

	# if caller passed us an old marker, garbage collect it.
	if(defined($_[0])) {
		__gnaw__garbage_collect_old_marker($_[0]);
	}

	# we don't return the marker, we get it via @_
	$_[0] = $markerref;

	# use a hard coded return to make sure we don't return the result
	# of the last operation.
	return; 
}

sub __gnaw__garbage_collect_old_marker {
	my ($markerref) = @_;

	unless(defined($markerref)) {
		GNAWMONITOR("tried to garbage collect an undefined marker");
		return;
	}

	my $textelement = __gnaw__text_element_pointed_to_by_marker($markerref);

	GNAWMONITOR("garbage collect marker: marker is at $markerref");
	GNAWMONITOR("garbage collect marker: text element is at $textelement");

	my $size_of_array = scalar(@$textelement);

	for(my $iter=__GNAW__LOCATION_MARKERS; $iter<$size_of_array; $iter++) {
		if($markerref eq $textelement->[$iter]) {
			# splice ( ARRAY , OFFSET , LENGTH , LIST );
			# The elements in ARRAY starting at OFFSET and 
			# going for LENGTH indexes will be removed from ARRAY. 
			# Any elements from LIST will be inserted at OFFSET into ARRAY.

			splice(@$textelement, $iter, 1);
			return;
		}
	}

	# if we fell through, we didn't find it.
	return;
}


sub __gnaw__restore_old_text_marker {
	my ($markerref) = @_;
	unless(defined($markerref)) {
		GNAWMONITOR("tried to restore an undefined marker");
		return;
	}

	my $textelement = __gnaw__text_element_pointed_to_by_marker($markerref);

	unless(defined($textelement)) {
		GNAWMONITOR("tried to restore a marker to undefined textelement");
		return;
	}

	GNAWMONITOR("restore old marker: marker is at $markerref");
	GNAWMONITOR("restore old  marker: text element is at $textelement");

	$__gnaw__curr_text_element = $textelement;

	__gnaw__garbage_collect_old_marker( $markerref );

	__gnaw__delete_all_markers_and_callbacks_at_text_position($__gnaw__curr_text_element);

	return;
}



##################################################################### callbacks are associated with the text element of the current element
####################################################################
sub __gnaw__assign_callback_to_current_text_element {
	GNAWMONITOR;

	my ($coderef)=@_;

	push(@$__gnaw__curr_text_element, $coderef);
	
}


sub __gnaw__call_all_callbacks_from_beginning_to_current_element {
	GNAWMONITOR("__gnaw__call_all_callbacks_from_beginning_to_current_element BEGIN");

	my $curr = $__gnaw__head_text_element;

	# while still looking
	my $still_looking=1;
	while ($still_looking) {

		# if this element has some references at the end
		if(scalar(@$curr)>(__GNAW__LOCATION_MARKERS)) {

			# take the references off and put them in @refs array
			my @refs = splice(@$curr, __GNAW__LOCATION_MARKERS);

			# while there are refs in @refs array
			while(scalar(@refs)) {

				#get a ref
				my $ref = pop(@refs);

				# if ref is not a callback, must be a marker, put it back 
				if(ref($ref) ne 'CODE') {
					push(@$curr, $ref);
				} else { # else must be a call back, call it.
					$ref->();
				}
			}
		}

		if($curr eq $__gnaw__curr_text_element) {
			$still_looking=0;
		} else {
			# now go to next element
			$curr = $curr->[__GNAW__NEXT];
		}

	}

	GNAWMONITOR("__gnaw__call_all_callbacks_from_beginning_to_current_element END");

}

# this assumes there are no callbacks on element.
sub __gnaw__delete_all_markers_from_beginning_to_current_element {
	GNAWMONITOR("__gnaw__delete_all_markers_from_beginning_to_current_element BEGIN");

	my $curr = $__gnaw__head_text_element;
	my $next;
	my $still_looking=1;
	while ($still_looking) {

		# while this element has some references at the end
		#while(scalar(@$curr)>(__GNAW__LOCATION_MARKERS)) {
		#	#get a ref
		#	my $ref = pop(@$curr);
		#	$$ref = \$__gnaw__universal_undefined_scalar;
		#}

		__gnaw__delete_all_markers_and_callbacks_at_text_position($curr);


		if( 	   ($curr eq $__gnaw__curr_text_element) 
			or ($curr eq $__gnaw__tail_text_element) ) 
		{
			$still_looking=0;
		} else {
			# now go to next element
			$next = $curr->[__GNAW__NEXT];

			#@$curr = ();

			$curr = $next;
		}


	}

	GNAWMONITOR("__gnaw__delete_all_markers_from_beginning_to_current_element END");

}

# this assumes you've already called any callbacks and deleted any markers.
sub __gnaw__delete_all_elements_from_beginning_to_just_prior_to_current_element {
	GNAWMONITOR("__gnaw__delete_all_elements_from_beginning_to_just_prior_to_current_element BEGIN");
	my $count;

	# starting from current location,
	# back up to the beginning of the line.
	# don't go past 100 characters
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

		@$curr = ();

		$curr = $next;
	}

	$__gnaw__head_text_element->[__GNAW__NEXT] = $stop;
	$stop->[__GNAW__PREV] = $__gnaw__head_text_element;

	GNAWMONITOR("__gnaw__delete_all_elements_from_beginning_to_just_prior_to_current_element END");

}


sub __gnaw__commit_text_to_current_location {
	GNAWMONITOR;
	__gnaw__call_all_callbacks_from_beginning_to_current_element();
	__gnaw__delete_all_markers_from_beginning_to_current_element();
	__gnaw__delete_all_elements_from_beginning_to_just_prior_to_current_element();
}



##################################################################### text linked list handling subroutines.
####################################################################
sub __gnaw__initialize_text_linked_list_to_empty {
	GNAWMONITOR;

	# if the text linked list currently has data in it, 
	# go through and delete all the data and delete all the markers
	if(defined($__gnaw__head_text_element)) {
		my $element = $__gnaw__head_text_element;
		while(defined($element)) {
			my $next = $element->[__GNAW__NEXT];
			splice(@$element, 0, __GNAW__LOCATION_MARKERS);

			my $markerref;
			while(scalar(@$element)) {
				$markerref = shift(@$element);
				__gnaw__have_marker_point_to_element($markerref, undef);
			}
			undef $element;
			$element = $next;
		}

	}


	$__gnaw__head_text_element = [];
	$__gnaw__tail_text_element = [];

	# the location markers go at the end of the array.
	# will push them on only as needed.

	$__gnaw__head_text_element->[__GNAW__PREV]	= undef;
	$__gnaw__head_text_element->[__GNAW__NEXT]	= $__gnaw__tail_text_element;
	$__gnaw__head_text_element->[__GNAW__LETTER]	= '';

	$__gnaw__tail_text_element->[__GNAW__PREV]	= $__gnaw__head_text_element;
	$__gnaw__tail_text_element->[__GNAW__NEXT]	= undef;
	$__gnaw__tail_text_element->[__GNAW__LETTER]	= '';

	# we will initialize to pointing to tail element.
	# when we add text, if curr pointer is pointing to tail element, then we will
	# add text to the end, and move curr pointer to the previous element.
	# we should never be pointing to the head element, if we do, it may be a bug.
	$__gnaw__curr_text_element  = $__gnaw__tail_text_element;
}


__gnaw__initialize_text_linked_list_to_empty();

sub __gnaw__insert_letter_just_before_marker {
	my ($letter, $marker)=@_;

	GNAWMONITOR("__gnaw__insert_letter_just_before_marker letter is '$letter', marker is '$marker'"); ;

	my $oldelement = __gnaw__text_element_pointed_to_by_marker($marker);

	unless(defined($oldelement)) {
		GNAWMONITOR("tried to __gnaw__insert_letter_just_before_marker but marker pointed to undef");
		return;
	}

	GNAWMONITOR( "__gnaw__insert_letter_just_before_marker oldelement is '$oldelement'\n");

	my $newelement = [];

	$newelement->[__GNAW__LETTER]=$letter;

	# get pointer to previous element
	my $prevelement = $oldelement->[__GNAW__PREV];

	$prevelement->[__GNAW__NEXT] = $newelement;
	$newelement->[__GNAW__PREV] = $prevelement;

	$newelement->[__GNAW__NEXT] = $oldelement;
	$oldelement->[__GNAW__PREV] = $newelement;

	# if marker pointed to last element and last element has location markers, 
	# then move them into this character we just added.
	if($oldelement eq $__gnaw__tail_text_element) {
		my @temparray = @$__gnaw__tail_text_element;

		# use splice so we can change number of indexes between zero and 
		# location markers and still work.
		splice(@temparray, 0, __GNAW__LOCATION_MARKERS);
	
		while(scalar(@temparray)) {
			my $markerref = shift(@temparray);
			__gnaw__have_marker_point_to_element($markerref,$newelement);
		}

		# if currently pointing to the tail element, 
		# move pointer to the element we just inserted
		if($__gnaw__curr_text_element eq $__gnaw__tail_text_element) {
			$__gnaw__curr_text_element = $newelement;
		}
	}
	return;
}

sub __gnaw__insert_letter_at_end_of_linked_list {
	my ($letter)=@_;
	GNAWMONITOR("__gnaw__insert_letter_at_end_of_linked_list inserting '$letter'");
	my $endmarker = \$__gnaw__tail_text_element;
	GNAWMONITOR( "__gnaw__tail_text_element is '$__gnaw__tail_text_element'. endmarker is '$endmarker'\n");
	__gnaw__insert_letter_just_before_marker($letter, $endmarker);
}


sub __gnaw__insert_string_just_before_marker {
	GNAWMONITOR;
	my ($string, $marker) = @_;

	my @letters = split(//, $string);

	foreach my $letter (@letters) {
		GNAWMONITOR(  "__gnaw__insert_string_just_before_marker letter '$letter' at marker '$marker'\n" );
		__gnaw__insert_letter_just_before_marker($letter, $marker);
	}
}

sub __gnaw__insert_string_at_end_of_linked_list {
	my ($string) = @_;
	GNAWMONITOR("__gnaw__insert_string_at_end_of_linked_list inserting string '$string'");

	my @letters = split(//, $string);

	foreach my $letter (@letters) {
		__gnaw__insert_letter_at_end_of_linked_list($letter);
	}

}


sub __gnaw__delete_this_element_in_text_linked_list {
	my ($element)=@_;
	GNAWMONITOR("__gnaw__delete_this_element_in_text_linked_list $element");

	return if($element eq $__gnaw__head_text_element);
	return if($element eq $__gnaw__tail_text_element);

	my $prev = $element->[__GNAW__PREV];
	my $next = $element->[__GNAW__NEXT];

	$prev->[__GNAW__NEXT] = $next;
	$next->[__GNAW__PREV] = $prev;

	# now that we've got the prev, next, and letter, delete them from array
	# the only thing left will be markers.
	# use splice so we can change number of indexes between zero and 
	# location markers and still work.
	splice(@$element, 0, __GNAW__LOCATION_MARKERS);

	# if there are any markers in current element, delete them
	while(scalar(@$element)) {
		my $markerref = shift(@$element);
		__gnaw__have_marker_point_to_element($markerref,undef);
	}

}	





####################################################################
####################################################################
# some higher level subroutines for string manipulation
####################################################################
####################################################################

sub __gnaw__read_string_between_markers {
	GNAWMONITOR ( "__gnaw__read_string_between_markers" );
	my($startmarker, $stopmarker) = @_;

	GNAWMONITOR("startmarker is '$startmarker'");
	GNAWMONITOR("stopmarker is '$stopmarker'");

	my $startelement = __gnaw__text_element_pointed_to_by_marker($startmarker);
	my $stopelement = __gnaw__text_element_pointed_to_by_marker($stopmarker);

	GNAWMONITOR("startelement is '$startelement'");
	GNAWMONITOR("stopelement is '$stopelement'");

	unless(defined($startelement) and defined($stopelement)) {
		return '';
	}

	my $string = '';

	my $element = $startelement;

	while( defined($element) and ($element ne $stopelement) ) {
		my $letter = $element->[__GNAW__LETTER];
		$string .= $letter;
		$element = $element->[__GNAW__NEXT];
	}

	return $string;
}


# note "start" marker element will be deleted. "stop" element will not.
sub __gnaw__delete_string_between_markers {
	GNAWMONITOR ( "__gnaw__delete_string_between_markers" );
	my($startmarker, $stopmarker) = @_;

	GNAWMONITOR("startmarker is '$startmarker'");
	my $startelement = __gnaw__text_element_pointed_to_by_marker($startmarker);
	GNAWMONITOR("startelement is '$startelement'");


	GNAWMONITOR("stopmarker is '$stopmarker'");
	my $stopelement = __gnaw__text_element_pointed_to_by_marker($stopmarker);
	GNAWMONITOR("stopelement is '$stopelement'");

	unless(defined($startelement) and defined($stopelement)) {
		return;
	}

	my $element = $startelement;

	while( defined($element) and ($element ne $stopelement) ) {
		my $next = $element->[__GNAW__NEXT];
		__gnaw__delete_this_element_in_text_linked_list($element);
		$element=$next;
	}

	return;
}


sub __gnaw__replace_text_between_markers_with_string {
	GNAWMONITOR ( "__gnaw__replace_text_between_markers_with_string" );
	my($startmarker, $stopmarker, $string) = @_;
	__gnaw__delete_string_between_markers($startmarker, $stopmarker);
	__gnaw__insert_string_just_before_marker($string, $stopmarker); 
	return;
}

####################################################################
####################################################################
# low level parsing subroutines.
####################################################################
####################################################################

sub __gnaw__at_end_of_string {
	GNAWMONITOR;
	if($__gnaw__curr_text_element eq $__gnaw__tail_text_element) {
		return 1;
	} else { 
		return 0;
	}
}

sub __gnaw__move_pointer_forward {
	GNAWMONITOR;
	if(__gnaw__at_end_of_string()) {
		__gnaw__parse_failed();
		return;
	}
	$__gnaw__curr_text_element = $__gnaw__curr_text_element->[__GNAW__NEXT];

	__gnaw__delete_all_markers_and_callbacks_at_text_position($__gnaw__curr_text_element);
}	

sub __gnaw__delete_all_markers_and_callbacks_at_text_position {
	# as we move forward, we may attach markers and callbacks to the text
	# if we fallback to an earlier position, we don't delete all the existing
	# markers and callbacks, because we may not get as far. 
	# instead, we'll only delete them as we need.
	# when we move the text pointer forward here, we are guaranteed that no
	# opcode has put a marker on this text yet. Any markers there now are old
	# markers and can be deleted.
	#
	# short version: delete everything in array from index __GNAW__LOCATION_MARKERS to end
	my($textelement) = @_;

	return unless(defined($textelement));
	unless(defined($textelement)) {
		my $cnt=0;
		while(1) {
			my @caller = caller($cnt++);
			if(scalar(@caller)==0) {exit;}
			warn; print Dumper \@caller;
		}
	}

	delete @$textelement[ __GNAW__LOCATION_MARKERS .. (scalar(@$textelement)-1) ];

}

####################################################################
# Note: if you create your own "skip" subroutine, make sure it doesn't
# use the __gnaw__curr_character routine because the __gnaw__curr_character 
# will call the "skip" subroutine, and things will go kersplewy.
####################################################################
our $__gnaw__skip_whitespace = sub{
####################################################################
	GNAWMONITOR('skipwhitespace');

	while(1) {

		if(__gnaw__at_end_of_string()) {
			return;
		}

		my $letter =  $__gnaw__curr_text_element->[__GNAW__LETTER];

		if(
			($letter eq ' ' ) or
			($letter eq "\t") or
			($letter eq "\n") or
			($letter eq "\f")
		) {
			__gnaw__move_pointer_forward();
		} else {
			return;
		}

	}
};

####################################################################
our $__gnaw__skip_nothing = sub{};
####################################################################

####################################################################
# change the coderef assigned to this to change what we skip.
# probably want to do it with a "local" command.
####################################################################
our $__gnaw__skip_code = $__gnaw__skip_whitespace;
####################################################################

sub __gnaw__curr_character {
	GNAWMONITOR;
	if(__gnaw__at_end_of_string()) {
		__gnaw__parse_failed();
		return '';
	}

	return $__gnaw__curr_text_element->[__GNAW__LETTER];
}





sub __gnaw__string_showing_user_current_location_in_text {
	GNAWMONITOR;
	my $count;

	# starting from current location,
	# back up to the beginning of the line.
	# don't go past 100 characters
	# and don't go past the beginning marker.
	my $start = $__gnaw__curr_text_element;
	$count = 100;
	while( 	($count--) and  
		($start ne $__gnaw__head_text_element) and 
		($start->[__GNAW__LETTER] ne "\n") 
	){
		$start = $start->[__GNAW__PREV];
	}


	# starting from current 
	# move to the end of the line.
	# don't go past 100 characters
	# and don't go past the end marker.
	my $stop = $__gnaw__curr_text_element;
	$count = 100;
	while( 	($count--) and  
		($stop ne $__gnaw__tail_text_element) and 
		($stop->[__GNAW__LETTER] ne "\n") 
	){
		$stop = $stop->[__GNAW__NEXT];
	}


	# now, go from start to stop marker and print out the elements
	my $curr = $start;
	my $final_string='';

	$final_string .= "START\n";
	$final_string .= "__gnaw__string_showing_user_current_location_in_text\n";
	$final_string.= "current element points to ".$__gnaw__curr_text_element."\n";

	my $keepgoing=1;

	while ($keepgoing) {
		if($curr eq $__gnaw__curr_text_element) {
			$final_string.= ">";
		} else {
			$final_string.= " ";
		}

		$final_string .= $curr." ";

		if($curr eq $__gnaw__head_text_element) {
			$final_string.= "HEAD";
		} elsif ($curr eq $__gnaw__tail_text_element){
			$final_string.= "TAIL";
		} else {
			my $letter = $curr->[__GNAW__LETTER];
			$final_string.= $letter;
		}

		$final_string.= " : ";

		for(my $iter=__GNAW__LOCATION_MARKERS; $iter<scalar(@$curr); $iter++) {
			my $markerref = $curr->[$iter];
			if(defined($markerref)) {
				if(ref($markerref) eq 'CODE') {
					$final_string.= " $markerref-callback ";
				} elsif (ref($markerref) eq 'REF') {

					my $referent = $$markerref;

					if(ref($referent) eq 'ARRAY') {
						$final_string.= " $referent-textmarker ";
					} else {
						$final_string.= " $markerref-(?????) ";					
					}
				} else {
					$final_string .= " '$markerref' ";
				}
			} else {
				$final_string.= " undef ";
			}
		}

		$final_string.= "\n";

		if($curr eq $stop) {
			$keepgoing=0;
		}

		$curr = $curr->[__GNAW__NEXT];
	}

	$final_string .= "END\n";
	return $final_string;
}

####################################################################
####################################################################
####################################################################
####################################################################
####################################################################
####################################################################
####################################################################



####################################################################
####################################################################
####################################################################
####################################################################
####################################################################
####################################################################
####################################################################



####################################################################
####################################################################
####################################################################
####################################################################
####################################################################
####################################################################
####################################################################



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
	GNAWMONITOR("push_fallback_position, instruction '$instruction', marker '$textmarker', text is ".$$textmarker);

	push(@__gnaw__fallback_here_on_fail, [$instruction, $textmarker]);
}

sub __gnaw__pop_fallback_postition {
	my $arrref = pop(@__gnaw__fallback_here_on_fail);
	my ($instruction, $textmarker) = @$arrref;
	GNAWMONITOR("pop_fallback_position, instruction '$instruction', marker '$textmarker', text is ".$$textmarker);
	return ($instruction, $textmarker);
}



sub __gnaw__parse_failed {
	GNAWMONITOR( "__gnaw__parse_failed BEGINNING\n" );

	my ($instruction, $textmarker) = __gnaw__pop_fallback_postition();
	__gnaw__move_current_instruction_pointer($instruction);
	__gnaw__restore_old_text_marker($textmarker);
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

#######################################################################
#######################################################################
#######################################################################
#######################################################################
#######################################################################
#######################################################################


#######################################################################
#######################################################################
#######################################################################
#######################################################################
#######################################################################
#######################################################################


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


#######################################################################
#######################################################################
# __gnaw__literal is the low level, single literal, operation.
# the "l" and "ql" and other functions must break their input
# parameters down into individual calls to __gnaw__literal.
#######################################################################
sub __gnaw__literal {
#######################################################################
#######################################################################
#######################################################################
	GNAWMONITOR( "__gnaw__literal command");
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

#######################################################################
# __gnaw__lit is the callback the parser will call when dealing with a literal.
#######################################################################
sub __gnaw__lit_callback {
	GNAWMONITOR( "__gnaw__lit command");
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	GNAWMONITOR( "__gnaw__lit command: looking for ".($thisinstruction->{debugstring}));

	$__gnaw__skip_code->();

	my $arrref = $thisinstruction->{value};
	my $lastiter = scalar(@$arrref);

	GNAWMONITOR( "__gnaw__lit command: ". (Dumper $arrref));
	GNAWMONITOR( "__gnaw__lit command: lastiter=$lastiter");

	GNAWMONITOR( __gnaw__string_showing_user_current_location_in_text() );

	for(my $iter=0; $iter<$lastiter; $iter++) {
		my $currchar = __gnaw__curr_character();
		my $litchar = $arrref->[$iter];

		GNAWMONITOR("__gnaw__lit command: comparing $currchar eq $litchar");
		unless($currchar eq $litchar) {
			__gnaw__parse_failed();
			return;
		} 
		__gnaw__move_pointer_forward();
	}

	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);
}



#######################################################################
#######################################################################
#######################################################################

sub __gnaw__convert_character_class_string_into_hash_ref {
	GNAWMONITOR;
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

#######################################################################
# character class
#######################################################################
sub cc {
#######################################################################
	GNAWMONITOR( "cc command");
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
	GNAWMONITOR( "__gnaw__cc command");
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

	GNAWMONITOR( "__gnaw__cc command: looking for ".($thisinstruction->{debugstring}));

	my $hashref = $thisinstruction->{value};

	GNAWMONITOR( __gnaw__string_showing_user_current_location_in_text() );

	my $currchar = __gnaw__curr_character();

	if(exists($hashref->{$currchar})) {
		__gnaw__move_pointer_forward();
	} else {
		__gnaw__parse_failed();
		return;
	}
}



#######################################################################
# inverted character class
#######################################################################
sub CC {
#######################################################################
	GNAWMONITOR( "CC command");
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
	GNAWMONITOR( "__gnaw__inv_cc command");
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

	GNAWMONITOR( "__gnaw__inv_cc command: looking for NOT ".($thisinstruction->{debugstring}));

	my $hashref = $thisinstruction->{value};

	GNAWMONITOR( __gnaw__string_showing_user_current_location_in_text() );

	my $currchar = __gnaw__curr_character();

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

#######################################################################
# "thing" function is equivalent to perl regular expression '.' 
# any single character.
#######################################################################

sub thing {
	GNAWMONITOR( "thing command");

	my $compiled_code = {
		opcode => 'thing',
		coderef=> \&__gnaw__thing,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}


sub __gnaw__thing {
	GNAWMONITOR( "__gnaw__thing command");
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);

	GNAWMONITOR( __gnaw__string_showing_user_current_location_in_text() );

	# have to skip. when we do a "get", the get function does a skip
	# if we do a match('b', thing, 'b'), and we dont skip cc function,
	# then this will match only bob, bab, bib, etc.
	# if we do a match('b', get(thing), 'b'), then this will match 'b  ob'.
	# match must be same whether we use "get" or not.
	# therefore the only way to make it consistent is to skip on every 
	# function that looks for text, like literals and character classes.
	$__gnaw__skip_code->();

	if(__gnaw__at_end_of_string()) {
		__gnaw__parse_failed();
		return;
	} else {
		__gnaw__move_pointer_forward();
	}

}

#######################################################################
#######################################################################
#######################################################################
# gnaw series evaporates into whatever subcommands it consists of.
# there is no __gnaw__series subroutine to handle the series because
# the series dissolves into atomic operations like literals and character classes.
#######################################################################
#######################################################################
#######################################################################


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
	GNAWMONITOR( "series command");
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



#######################################################################
#######################################################################
#######################################################################
# alternation command breaks down into three subcommands.
# initialization
# alternation command
# rejoinder
#######################################################################
#######################################################################
#######################################################################

# callback used by parser when executing an alternate instruction
# we only hit the init command once. Use it to initialize the iterator value
sub __gnaw__alt_init {
	GNAWMONITOR( "__gnaw__alt_init:");
	my $alt_init_instruction =  __gnaw__get_current_instruction_pointer();
	my $alt_cmd_instruction = __gnaw__given_instruction_return_next_instruction($alt_init_instruction);
	$alt_cmd_instruction->{iterator}=0;
	__gnaw__move_current_instruction_pointer($alt_cmd_instruction);
}

# callback used by parser when executing an alternate instruction
# we hit this at start of command and every time an alternate fails.
# based off iterator prepare to try another alternate.
sub __gnaw__alt_cmd {
	GNAWMONITOR( "\n\n\n__gnaw__alt_cmd:");
	my $alt_cmd_instruction = __gnaw__get_current_instruction_pointer();
	my $iterator = $alt_cmd_instruction->{iterator};
	my $lastiterator = scalar(@{$alt_cmd_instruction->{alternates}});

	# if we're done, we failed to match anything
	if($iterator == $lastiterator) {
		__gnaw__parse_failed();
		return;
	} else {
		# we're not done, try the next alternate
		$alt_cmd_instruction->{iterator}++;

		my $textmarker;
		__gnaw__get_current_text_marker($textmarker);		
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
	GNAWMONITOR( "\n\n\n__gnaw__alt_rejoinder:");

	# we can pop off the fallback position and discard them.
	my ($fallback_cmd, $fallback_marker) = __gnaw__pop_fallback_postition(); 
	__gnaw__garbage_collect_old_marker($fallback_marker);

	my $alt_rej_instruction = __gnaw__get_current_instruction_pointer();
	GNAWMONITOR( "__gnaw__alt_rejoinder: alt_rej_instruction is '$alt_rej_instruction'");
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($alt_rej_instruction);
	GNAWMONITOR( "__gnaw__alt_rejoinder: nextinstruction is '$nextinstruction'");
	__gnaw__move_current_instruction_pointer($nextinstruction);
	GNAWMONITOR( "\n\n\n");
}



#######################################################################
# user function for creating an alternate.
# pass in a series of alternates into call to "a" function.
# each parameter passed in will be treated as a different alternate.
# group components you want to be part of a sequence within an alternate
# by using array references
#######################################################################

sub a {
	my @alternates = __gnaw__take_grammar_components_and_turn_into_list_of_stitchers(@_);

	my $alternation_stitcher = __gnaw__alternation(@alternates);

	return $alternation_stitcher;
}

#######################################################################
# This is useful if you have a bunch of alternates which are all single literals.
#######################################################################
sub qa {
	my ($string)=@_;
	my @words = __gnaw__separate_string_into_words($string);
	my $stitcher = a(@words);
	return $stitcher;
}

sub __gnaw__alternation {
	GNAWMONITOR( "alternation command");
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


#######################################################################
#######################################################################
#######################################################################
# greedy command breaks down into five subcommands.
# initialization
# pattern start
# pattern pass
# pattern fail
# rest of grammar
#######################################################################
#######################################################################
#######################################################################

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

		my $textmarker;
		__gnaw__get_current_text_marker($textmarker);		
		__gnaw__push_fallback_postition($grdy_rest_of_grammar, $textmarker);
	}

}

# callback used by parser when executing an greedy instruction
sub __gnaw__grdy_patt_start {
	my $grdy_patt_start = __gnaw__get_current_instruction_pointer();
	my $grdy_user_instruction = __gnaw__given_instruction_return_next_instruction($grdy_patt_start);
	__gnaw__move_current_instruction_pointer($grdy_user_instruction);

	my $grdy_patt_fail = $grdy_patt_start->{grdy_patt_fail};

	my $textmarker;
	__gnaw__get_current_text_marker($textmarker);		
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
	__gnaw__garbage_collect_old_marker($fallback_marker);

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
				__gnaw__garbage_collect_old_marker($textmarker);
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
				my $textmarker;
				__gnaw__get_current_text_marker($textmarker);		
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
			__gnaw__garbage_collect_old_marker($textmarker);
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

#######################################################################
# user function to create a greedy quantifier
# g( [min, max?], grammar component, component...? )
#######################################################################
sub g {
	GNAWMONITOR( "g (greedy) command");

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

#######################################################################
#######################################################################
#######################################################################
# thrifty command breaks down into five subcommands.
# initialization
# pattern start
# pattern pass
# pattern fail
# rest of grammar
#######################################################################
#######################################################################
#######################################################################

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

		my $textmarker;
		__gnaw__get_current_text_marker($textmarker);		
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

	my $textmarker;
	__gnaw__get_current_text_marker($textmarker);		
	__gnaw__push_fallback_postition($tfty_patt_fail, $textmarker);
}

# callback used by parser when executing a thrifty instruction
sub __gnaw__tfty_patt_pass{
	GNAWMONITOR("__gnaw__tfty_patt_pass BEGIN");
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
	__gnaw__garbage_collect_old_marker($fallback_marker);

	# if quantifier is consumable
	if($tfty_patt_start->{consumable}) {
		GNAWMONITOR("__gnaw__tfty_patt_pass consumable");
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
				__gnaw__garbage_collect_old_marker($textmarker);
				__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);
			}
		} else { 
			# elsif ($iterator>$min) {
			# if iterator is greater than minimum, then already deleted all 
			# the previous markers, don't need to do anything with markers anymore

			# if iterator is less than max, set fallback position to try another pattern
			if($openended or ($iterator<$max)) {
				my $textmarker;
				__gnaw__get_current_text_marker($textmarker);		
				__gnaw__push_fallback_postition($tfty_patt_start, $textmarker);

				__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);	
			} else {
				# else go to rest of grammar, if it fails, we can't try anymore, so no fallback
				__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);
			}		
		}
	} else {
		# else quantifier is NOT consumable
		GNAWMONITOR("__gnaw__tfty_patt_pass NOT consumable");

		if(0) {

		# if we can try some more
		} elsif($openended or ($iterator<$max)) {

			GNAWMONITOR("__gnaw__tfty_patt_pass if we can try some more");
			# if iterator says we matched enough to meet minimum, create fallback to here.
			if($iterator >= $min) {
				GNAWMONITOR("__gnaw__tfty_patt_pass iterator>=min");
				# create a fallback position at the current text marker
				# with the instruction being 'try another pattern'
				my $textmarker;
				__gnaw__get_current_text_marker($textmarker);		
				__gnaw__push_fallback_postition($tfty_patt_start, $textmarker);

				# now go try rest of grammar. if it fails, we'll try another pattern
				__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);			
			} else {
				GNAWMONITOR("__gnaw__tfty_patt_pass haven't matched enough paterns to hit minimum");
				# else we haven't matched enough paterns to hit minimum. do another patern
				__gnaw__move_current_instruction_pointer($tfty_patt_start);			
			}
		} else {
			GNAWMONITOR("__gnaw__tfty_patt_pass cant try any more");
			# else not open ended and iterator == max, cant try any more, go to rest of grammar
			# if max==6 then no need to create a fallback 
			__gnaw__move_current_instruction_pointer($tfty_rest_of_grammar);
		}
	}
	GNAWMONITOR("__gnaw__tfty_patt_pass END");
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
			__gnaw__garbage_collect_old_marker($textmarker);
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


#######################################################################
# user function to create a greedy quantifier
# g( [min, max?], grammar component, component...? )
#######################################################################
sub t {
	GNAWMONITOR( "thrifty command");

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


#######################################################################
#######################################################################
# "now" is executed every time the parser hits that branch of the grammar
#######################################################################
#######################################################################

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


#######################################################################
#######################################################################
# "defer" is scheduled for execution but is only called if the grammar matches
# that interpretation.
#######################################################################
#######################################################################

sub defer {
	my ($coderef) = @_;

	my $closure = sub {
		__gnaw__assign_callback_to_current_text_element($coderef); # callback same as code except for this line.

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


#######################################################################
#######################################################################
#######################################################################
# commit command is an immediate commitment to the current interpretation
# of the grammar to the string being parsed. It causes any callbacks
# from the beginning of the string to the current pointer to be executed
# and it deletes the text from beginning of string to 10 characters
# before the current pointer.
#######################################################################
#######################################################################
#######################################################################

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
		$__gnaw__skip_code->();
		__gnaw__get_current_text_marker($begintextmarker);
	});
	my $get_begin = $beginstitcher->('getfirst');
	$get_begin->{opcode} = 'get_begin';


	my $endstitcher = now(sub{
		my $endtextmarker;
		__gnaw__get_current_text_marker($endtextmarker);
		my $call_back_with_string = sub {
			my $string = __gnaw__read_string_between_markers
				($begintextmarker,$endtextmarker);
			$user_call_back->($string);
		};
		__gnaw__assign_callback_to_current_text_element($call_back_with_string);
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



#####################################################################
#####################################################################
#####################################################################
#####################################################################
#####################################################################

#####################################################################
#####################################################################
#####################################################################
#####################################################################
#####################################################################
# outer functions
#####################################################################
#####################################################################
#####################################################################
#####################################################################
#####################################################################



sub parse {
	GNAWMONITOR( "parse command begin");

	my $stitcher=series(@_);

	# once we've processed the parameters passed into 'parse',
	# all the grammar components have been executed.
	# this means we can now generate the callback to initialize
	# all "get" variables and subroutines.
	my $variableinitroutine = __gnaw__generate_initialization_routine_for_get_callbacks_so_far();

	my $pars_init = {
		opcode => 'parseinit',
		coderef => sub {
			$variableinitroutine->(); 
			my $thisinstruction = __gnaw__get_current_instruction_pointer();
			my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
			__gnaw__move_current_instruction_pointer($nextinstruction);
		},
	};

	my $pars_rejoinder = {
		opcode => 'parserejoinder',
		signifyendof => $pars_init,
		coderef => sub{
			$__gnaw__processor_still_running=0;
			$__gnaw__processor_succeeded=1;
			GNAWMONITOR(__gnaw__string_showing_user_current_location_in_text);
			__gnaw__commit_text_to_current_location;
		},
	};

	my $pars_failure = {
		opcode => 'parserefailure',
		signifyendof => $pars_init,
		coderef => sub{
			$__gnaw__processor_still_running=0;
			$__gnaw__processor_succeeded=0;
		},
	};

	$pars_init ->{rejoinder}=$pars_rejoinder;


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

		GNAWMONITOR("end string initialization\n\n\n\n\n\n");

		$__gnaw__processor_still_running=1;
		$__gnaw__processor_succeeded=0;
		$__gnaw__processor_instruction_pointer = $pars_init;


		my $textmarker;
		__gnaw__get_current_text_marker($textmarker);		
		__gnaw__push_fallback_postition($pars_failure, $textmarker);


		__gnaw__process_commands();

		return $__gnaw__processor_succeeded;
	};

	GNAWMONITOR( "parse command end");

	return $call_back;
}


sub match {
	GNAWMONITOR( "match command begin");

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
			GNAWMONITOR( "match_pattern");
			if(__gnaw__at_end_of_string) {
				GNAWMONITOR("match pattern at end of string");
				$__gnaw__processor_still_running=0;
				$__gnaw__processor_succeeded=0;
				return;
			}

			GNAWMONITOR( "match_pattern about to create fallback");
			my $match_failure = $match_pattern->{match_failure};
			my $textmarker;
			__gnaw__get_current_text_marker($textmarker);		
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
			__gnaw__garbage_collect_old_marker($textmarker);

			$__gnaw__processor_still_running=0;
			$__gnaw__processor_succeeded=1;
			GNAWMONITOR(__gnaw__string_showing_user_current_location_in_text);
			__gnaw__commit_text_to_current_location;
		},
	};

	my $match_failure = {
		opcode => 'match_failure',
		signifyendof => $match_pattern,
		coderef => sub{
			# we created a fallback, tried to parse, failed, and fellback to where we were
			# If we can move current position forward, then do that and jump to match pattern
			# if we can't move current position forward, we're out of text, fail.
			if(__gnaw__at_end_of_string) {
				GNAWMONITOR("match failure at end of string");
				$__gnaw__processor_still_running=0;
				$__gnaw__processor_succeeded=0;
			} else {
				GNAWMONITOR("match failure NOT at end of string");
				__gnaw__move_pointer_forward();
				__gnaw__move_current_instruction_pointer($match_pattern);
			}
		},
	};

	my $match_cant_try_anymore = {
		opcode => 'match_cant_try_anymore',
		signifyendof => $match_pattern,
		coderef => sub{
			GNAWMONITOR("match_cant_try_anymore");
			$__gnaw__processor_still_running=0;
			$__gnaw__processor_succeeded=0;
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

		GNAWMONITOR("end string initialization\n\n\n\n\n\n");

		my $textmarker;
		__gnaw__get_current_text_marker($textmarker);		
		__gnaw__push_fallback_postition($match_cant_try_anymore, $textmarker);

		$__gnaw__processor_still_running=1;
		$__gnaw__processor_succeeded=0;
		$__gnaw__processor_instruction_pointer = $match_init;

		__gnaw__process_commands();

		return $__gnaw__processor_succeeded;
	};

	GNAWMONITOR( "match command end");

	return $call_back;
}



#######################################################################
#######################################################################
#######################################################################
# this is the parsing engine that executes the compiled grammar.
#######################################################################
#######################################################################
#######################################################################


sub __gnaw__process_commands {
	GNAWMONITOR( "process_commands: ");
	while($__gnaw__processor_still_running) {
		GNAWMONITOR( "process_commands: while still running");
		my $instruction =  __gnaw__get_current_instruction_pointer();
		GNAWMONITOR( "process_commands: instruction is '$instruction'");
		GNAWMONITOR( "process_commands: opcode is '". ($instruction->{opcode})."'");
		my $coderef = $instruction->{coderef};
		GNAWMONITOR( "process_commands: coderef is '$coderef'");
		$coderef->();
	}
}





#=head2 function1
#
#=cut
#
#sub function1 {
#}

=head1 TEXT INTERNALS

The text being parsed is held internally in a linked list. 
This allows Parse::Gnaw to operate on a small subset of the 
entire string being parsed. Theoretically, Parse::Gnaw can 
parse an infinite amount of text as long as it can be 
parsed in chunks small enough that the rules can disambiguate 
in a small enough space to fit in memory.

Each element in linked list is an array. 

Array stores the following data: 
0 : pointer to previous element
1 : pointer to next element
3 : text stored at this location
4 and above : text markers (optional)


The linked list starts and ends with two signpost elements:
'head' and 'tail'. No text is ever stored in these signpost
elements. Any text being parsed is always contained between
these two signpost elements.

The 'current' pointer always points to the text that is 

ABOUT TO BE PARSED.

When the parser successfully matches a letter, it will move
the pointer ahead by one character so that the next command
will be ready to match.

The current pointer may point to the tail signpost element.
This may mean that we are at the end of the string, or it
may mean that the next time we try to get the current letter
that we need to insert more text from a file or something.

All interfaces to the linked list should be through the 
subroutines. 

All parse level commands should manipulate text based on markers.


Getting text between two markers will get the text 
AT the start marker
and include all the text up to but BEFORE the stop marker.

This is because the current marker is always at the text ABOUT TO
be processed.

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
