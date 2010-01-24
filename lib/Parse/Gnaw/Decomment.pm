


# This is a very rudimentary source code comment filter used
# to help debug the Parse::Gnaw module. It looks for any
# comment with exactly 8 pound signs '#' in a row,
# with something other than a pound sign before and after,
# and it deletes those pound signs from the source code.
# if you have debug code you want to go completely away 
# during production, just comment it out with 8 '#' marks.

# WHATEVER YOU DO, DON'T USE 8 POUND MARKS TO COMMENT OUT 
# SOMETHING YOU DON"T WANT TO SUDDENLY REAPPEAR IN YOUR
# EXECUTABLE CODE.

package Parse::Gnaw::Decomment;

use Filter::Simple;

	#	find exactly eight '#' characters in a row, no space, something other than
	#	a '#' before them and after them, and delete them.
	#
	#	if your code has a comment with eight '#' characters used to comment it,
	# 	this module will remove the comment and give you whatever was left.
	#
	#	make sure whatever was left is executable code.

FILTER {   s{([^\#])\#\#\#\#\#\#\#\#([^\#])}{$1$2}g   };


=head1 NAME

Parse::Gnaw::Decomment - Used by Parse::Gnaw to decomment debug statements in the code. 

=head1 SYNOPSIS

Parse::Gnaw is chock full of comments that hide executable code used for debug. This
code is commented out with a specific comment string of 8 pound signs (#).

Normally, Parse::Gnaw contains a line that says 

	# use Parse::Gnaw::Decomment

i.e. it is commented out.

To enable debugging, uncomment that line and run the script. It will dump huge amounts
of debugging text to standard out.

Do not use anything in Parse::Gnaw with an 8 pound (#) comment unless you want it to 
be uncommented during debug and executed like normal code.


=cut

1;

