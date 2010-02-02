



1; 
{ 
	package Parse::Gnaw; 
	our $VERSION = '0.52'; 

	use Exporter;
	@ISA = qw( Exporter );
	@EXPORT = qw( @GNAW 
		      $c1  $c2  $c3  $c4  $c5  $c6  $c7  $c8  $c9  
		$c10 $c11 $c12 $c13 $c14 $c15 $c16 $c17 $c18 $c19 
		$c20 $c21 $c22 $c23 $c24 $c25 $c26 $c27 $c28 $c29 
		$c30 $c31 $c32 $c33 $c34 $c35 $c36 $c37 $c38 $c39 
		$c40 $c41 $c42 $c43 $c44 $c45 $c46 $c47 $c48 $c49 
		$c50 $c51 $c52 $c53 $c54 $c55 $c56 $c57 $c58 $c59 
		$c60 $c61 $c62 $c63 $c64 $c65 $c66 $c67 $c68 $c69 
		$c70 $c71 $c72 $c73 $c74 $c75 $c76 $c77 $c78 $c79 
		$c80 $c81 $c82 $c83 $c84 $c85 $c86 $c87 $c88 $c89 
		$c90 $c91 $c92 $c93 $c94 $c95 $c96 $c97 $c98 $c99 
		

	 );

	# when you "commit", this controls number of letters you let hang around
	# so that the next grammar component can look back if it wants to.
	our $GNAW_DEFAULT_PEEKBACK_WINDOW=1;
}  
1;

use warnings;
use strict;
use Data::Dumper; 

#use Parse::Gnaw::Decomment;

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
sub __GNAW__WRDBND_WHAT { 5; } # element is a word boundary marker inserted by "sip" function




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
	my $peekback_window=shift(@_);

	########GNAWMONITOR("__gnaw__delete_all_elements_from_beginning_to_just_prior_to_current_element BEGIN");
	my $count;

	# starting from current location,
	# back up the "peekback" number of characters.
	# don't go past the beginning marker.
	my $stop = $__gnaw__curr_text_element;
	$count = $peekback_window;
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
	return ;
}



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# this scalar stores a subref that we call anytime we commit text.
# when we commit text, it gets deleted from the linked list in memory.
# just before we delete it, we pass it to this subroutine which 
# does whatever it needs to do with the text.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

our $__gnaw__flush = undef;

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub __gnaw__flushed_text_is_ignored {
	$__gnaw__flush = undef;
}

sub __gnaw__flushed_text_is_sent_to_variable {
	# pass in a reference to a variable, we'll create a callback that will append text to that variable.

	my $varref = shift(@_);

	unless(ref($varref) eq 'SCALAR') {
		__gnaw__die("__gnaw__flushed_text_is_sent_to_variable must receive scalar ref");
		die;
	}

	my $callback = sub {
		# pass in string in first parameter
		$$varref .= $_[0];

		#warn "appending ".$_[0]." ";
	};

	$__gnaw__flush = $callback;

	return;
}

sub __gnaw__flushed_text_is_appended_to_file {
	# pass in a filename, we'll create a callback that will append to file

	my $filename = shift(@_);

	unless(-e $filename) {
		__gnaw__die("ERROR: __gnaw__flushed_text_is_appended_to_file must receive a filename that exists");
	}

	my $outfh;

	open($outfh, '>>'.$filename) or __gnaw__die("ERROR: unable to open file for append ($filename)");

	my $callback = sub {
		print $outfh $_[0];
	};
	
	$__gnaw__flush = $callback;

	return $outfh;
}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub __gnaw__commit_text_to_current_location {
	my $peekback_window=shift(@_);
	########GNAWMONITOR;
	__gnaw__call_all_callbacks_from_beginning_to_current_element();
	__gnaw__call_all_callbacks_from_beginning_to_current_element();

	if(defined($__gnaw__flush)) {
		my $string = __gnaw__read_string_between_markers
			($__gnaw__head_text_element, $__gnaw__curr_text_element);

		$__gnaw__flush->($string);
	}

	__gnaw__delete_all_elements_from_beginning_to_just_prior_to_current_element($peekback_window);
	return;
}


sub __gnaw__flush_remaining_unparsed_text {

	my $startmarker = __gnaw__create_new_marker_before_current_element();

	if(defined($__gnaw__flush)) {
		my $string = __gnaw__read_string_between_markers
			($startmarker, $__gnaw__tail_text_element);

		$__gnaw__flush->($string);
	}

	__gnaw__initialize_text_linked_list_to_empty();

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

# this subroutine gets called when we hit end of text in memory and we
# need to see if we can add anymore text. Default behaviour is to process
# the whole text in memory. Assign a subroutine reference to this that will
# read new text from input file or stream or whatever if you want that
# sort of functionality.
#
# If you do override this callback, you will probably want to use 
#	__gnaw__insert_string_at_end_of_linked_list()
# to add text to linked list.
our $__gnaw__sip = sub{};

sub __gnaw__at_end_of_input_text { # return boolean
	########GNAWMONITOR;
	if($__gnaw__curr_text_element eq $__gnaw__tail_text_element) {
		$__gnaw__sip->();
	
		if($__gnaw__curr_text_element eq $__gnaw__tail_text_element) {
			return 1;
		} else {
			return 0;
		}
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

	# delete any element that is not a letter. 
	# markers, callbacks, etc. are all to be deleted at this time.
	# move forward to first letter element.
	while(	
		    ($__gnaw__curr_text_element ne $__gnaw__tail_text_element) 
		and ($__gnaw__curr_text_element->[__GNAW__WHAT] != __GNAW__LETTER_WHAT)
	) {
		# don't delete word boundary markers inserted by "sip" function.
		if($__gnaw__curr_text_element->[__GNAW__WHAT] == __GNAW__WRDBND_WHAT) {
			$__gnaw__curr_text_element = $__gnaw__curr_text_element->[__GNAW__NEXT];
		} else {
			$__gnaw__curr_text_element = __gnaw__delete_this_text_element($__gnaw__curr_text_element);
		}
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
# skip functionality.
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



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

our %__gnaw__skip_callbacks = (
	'whitespace'=> $__gnaw__skip_whitespace,
	'nothing' => $__gnaw__skip_nothing,

);


our @__gnaw__list_of_stored_skip_callbacks;

sub __gnaw__store_old_skip_and_assign_new_skip { 
	my ($newskipcallback) = @_;
	push(@__gnaw__list_of_stored_skip_callbacks, $__gnaw__skip_code);

	$__gnaw__skip_code=$newskipcallback;
}

sub __gnaw__discard_current_skip_and_restore_previous_skip{
	my $oldcallback = pop(@__gnaw__list_of_stored_skip_callbacks);

	$__gnaw__skip_code=$oldcallback;
}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
	} elsif ($curr->[__GNAW__WHAT] == __GNAW__WRDBND_WHAT) {
		$final_string.= "BOUNDARY ";
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

	# make sure old text marker is still valid
	__gnaw__text_element_is_valid($textmarker);

	# set current pointer to text marker.
	$__gnaw__curr_text_element = $textmarker;


	# delete the current text marker and all the markers in front of it until we hit text
	while(	($__gnaw__curr_text_element ne $__gnaw__tail_text_element) and
		($__gnaw__curr_text_element->[__GNAW__WHAT] != __GNAW__LETTER_WHAT)
	) {
		# dont delete word boundary markers inserted by "sip".
		if($__gnaw__curr_text_element->[__GNAW__WHAT] == __GNAW__WRDBND_WHAT) {
			$__gnaw__curr_text_element = $__gnaw__curr_text_element->[__GNAW__NEXT];
		} else {
			__gnaw__delete_this_text_element($__gnaw__curr_text_element);
		}
		
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
 
sub noskip {
	__gnaw__set_skip('nothing', @_);
}



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub __gnaw__set_skip {
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	########GNAWMONITOR( "__gnaw__skip_instruction");
	my $whattoskip = shift(@_);

	unless(exists($__gnaw__skip_callbacks{$whattoskip})) {
		__gnaw__die("ERROR: tried to skip nonexistent type ($whattoskip)");
	}

	my $restofgrammarstitcher = series(@_);


	my $begin_code = {
		opcode => 'skip begin instruction',
		coderef=> \&__gnaw__skip_begin_callback,
		value => $whattoskip,
	};

	my $beginstitcher = generate_stitcher($begin_code, $begin_code);

	
	my $end_code = {
		opcode => 'skip end instruction',
		coderef=> \&__gnaw__skip_end_callback,
	};

	my $endstitcher = generate_stitcher($end_code, $end_code);

	

	my $instruction_if_fail = {
		opcode => 'skip restore on fail',
		coderef => \&__gnaw__skip_parse_fail,
		main => $begin_code,
	};

	$begin_code->{fallback}=$instruction_if_fail;


	# the begin command feeds into the series
	$beginstitcher->('setnext', ($restofgrammarstitcher->('getfirst')));
	$restofgrammarstitcher->('setprevious', ($beginstitcher->('getlast')));

	# the series command feeds into the end command
	$restofgrammarstitcher->('setnext', ($endstitcher->('getfirst')));
	$endstitcher->('setprevious', ($restofgrammarstitcher->('getlast')));

	my $skipstitcher = generate_stitcher($begin_code, $end_code);

	return $skipstitcher;
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub __gnaw__skip_begin_callback {
	########GNAWMONITOR( "__gnaw__skip_begin_callback");
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);

	my $whattoskip = $thisinstruction->{value};
	my $fallback = $thisinstruction->{fallback};
	########GNAWMONITOR( "__gnaw__skip command: setting skip to $whattoskip");
	########GNAWMONITOR( __gnaw__string_showing_user_current_location_in_text() );

	my $textmarker = __gnaw__create_new_marker_before_current_element
		######## ( 'skip_callback command setting a fallback position if rest of grammar fails' )
	;	
	__gnaw__push_fallback_postition($fallback, $textmarker);

	# now set the new skip value to 'whattoskip'
	my $newskipcallback = $__gnaw__skip_callbacks{$whattoskip};

	__gnaw__store_old_skip_and_assign_new_skip($newskipcallback);
}

sub __gnaw__skip_end_callback {
	########GNAWMONITOR( "__gnaw__skip_end_callback");
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);

	# we can pop off the fallback position and discard them.
	my ($fallback_cmd, $fallback_marker) = __gnaw__pop_fallback_postition(); 

	# we created this marker at the start of the skip command. can delete it now.
	__gnaw__delete_this_text_element($fallback_marker);

	# restore the old skip value
	__gnaw__discard_current_skip_and_restore_previous_skip();

}


sub __gnaw__skip_parse_fail {
	# restore the old skip value
	__gnaw__discard_current_skip_and_restore_previous_skip();

	# something failed while parsing. re-throw the failure.
	__gnaw__parse_failed();

}



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# the "skipnow" function will skip zero or more whitespace characters,
# even if the "noskip" is set. Especially if "noskip" is set. 
# that's probably when you'll use it.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub skipnow { 

	########GNAWMONITOR( "skipnow command");
	my $compiled_code = {
		opcode => 'skipnow',
		coderef=> \&__gnaw__skipnow_callback,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}


sub __gnaw__skipnow_callback {
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);

	$__gnaw__skip_whitespace->();

}




#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# __gnaw__literal is the low level, single literal, operation.
# the "l" and "ql" and other functions must break their input
# parameters down into individual calls to __gnaw__literal.
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
		coderef=> \&__gnaw__cc_callback,
		value => $char_set_hash_ref,
		debugstring => $characterset,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}


sub __gnaw__cc_callback {
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

sub dgt { cc('0-9') }
sub DGT { CC('0-9') }

sub wrd { cc('a-zA-Z0-9_') }
sub WRD { CC('a-zA-Z0-9_') }

sub spc { cc("\n \t \r \f") }
sub SPC { CC("\n \t \r \f") }

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
sub greedy {
	########GNAWMONITOR( "greedy command");

	# greedy( [min, max?, consumable?], patternstitcher(s), );
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


# a perl regular expression like ".*" will consume the entire string first,
# then release one character at a time until it has a match.
# this is a problem if you're trying to parse an infinite amount of text.
# To parse an infinite amount of text, open ended quantifiers should be thrifty.
# This will force them to match as little as possible first, then consume a little
# more until it finds a match.
# for this reason, the "any" and "some" shortcuts are thrift so that grammars
# can easily be used to parse infinite text.

# thrifty shortcuts

sub any  { thrifty([0], @_) }		# zero or more
sub some { thrifty([1], @_) }		# one or more

sub anything  { any (thing) } 	# zero or more 'things'
sub something { some(thing) }	# one or more 'things'


# 0 or 1 of whatever. i.e. 
# maybe('hello', 'there') 'Alice'
# will look for "Alice" that might or might not be preceded by "hello" "there".
# because "maybe" isn't open ended (at most, look for 1 match), it won't
# consume an entire file the way ".*" would. So for now, "maybe" is greedy.
sub maybe { greedy([0,1], @_) }	


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
sub thrifty {
	########GNAWMONITOR( "thrifty command");

	# thrifty ( [min, max?, consumable?] , patternstitcher(s) );
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
	my $peekback_window=$Parse::Gnaw::GNAW_DEFAULT_PEEKBACK_WINDOW;
	if(scalar(@_)>0) {
		$peekback_window=shift(@_);
	}
	return now(sub{__gnaw__commit_text_to_current_location($peekback_window)});
}


my @__gnaw__array_of_get_initializers_so_far;

sub get {
	my $first_parameter = shift(@_);

	my $callback;
	my $initialize;

	# return undef in callbacks for variables so we don't cause "get" to do a replace operation.
	if(ref($first_parameter) eq 'SCALAR') {
		my $initvalue = $$first_parameter;
		$callback = sub { $$first_parameter = shift(@_); return;};
		$initialize = sub { $$first_parameter = $initvalue; }
	} elsif (ref($first_parameter) eq 'ARRAY') {
		$callback = sub { push(@$first_parameter, shift(@_)); return;};
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

			my $beginmarkercopy1 = $beginmarkercopy;
			my $endmarkercopy1   = $endmarkercopy;
			
			my $call_back_in_front_of_marker = sub {
				########GNAWMONITOR("GET function, callback function, about to read string between markers $begintextmarker and $endtextmarker");
				my $string = __gnaw__read_string_between_markers
					($beginmarkercopy1,$endmarkercopy1);
				########GNAWMONITOR("GET function, callback function, string is '$string', about to pass to user function '$user_call_back'");
				my $user_return_string = $user_call_back->($string);
					if( defined($user_return_string) and (!(ref($user_return_string))) ) {

					__gnaw__replace_text_between_markers_with_string 
						($beginmarkercopy1,$endmarkercopy1, $user_return_string);
				}

			};

			__gnaw__create_new_element_before_this_element( $beginmarkercopy1, __GNAW__CLLBCK_WHAT, $call_back_in_front_of_marker
				######## , " 'get' function created callback a callback to put at front of string "
			);

		};
		__gnaw__create_new_element_before_current_element( __GNAW__CLLBCK_WHAT, $call_back_with_string
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




our @GNAW; 

sub __gnaw__c_callback {
	my $string = shift(@_);

	push(@GNAW, $string);

	my $size = scalar(@GNAW);

	my $evalstr = 'our $c'.$size.'; $c'.$size." = '".$string."';";

	#print "evalstr is '$evalstr'\n";

	eval($evalstr);

	return; # return undef so we don't cause "get" to do a replace operation.
}

sub c {
	push(@__gnaw__array_of_get_initializers_so_far, sub{@GNAW=();} );


	return get(\&__gnaw__c_callback, @_);

}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# bb
# positional marker: word boundary
# this is "true" on any of the following conditions, otherwise false:
#	1) at a transition from a \w character to a \W character
#	2) at a transition from a \W character to a \w character
#	3) at the beginning of the string
#	4) at the end of the string
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub bb {

	my $compiled_code = {
		opcode => 'word_boundary',
		coderef=> \&__gnaw__bb_callback,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}

sub BB {

	my $compiled_code = {
		opcode => 'NOT word_boundary',
		coderef=> \&__gnaw__not_bb_callback,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}


sub __gnaw__bb_callback {
	########GNAWMONITOR( "__gnaw__wb_callback");
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);

	if(__gnaw__are_we_currently_at_a_word_boundary() == 1) {
		return;
	} else {
		__gnaw__parse_failed();
	}
}

sub __gnaw__not_bb_callback {
	########GNAWMONITOR( "__gnaw__not_wb_callback");
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);

	if(__gnaw__are_we_currently_at_a_word_boundary() == 0) {
		return;
	} else {
		__gnaw__parse_failed();
	}
}


my %__gnaw__wb_word_class_hash;

foreach my $letter ('a'..'z', 'A'..'Z', '0'..'9', '_') {
	$__gnaw__wb_word_class_hash{$letter}=1;
}

# print Dumper \%__gnaw__wb_word_class_hash;

sub __gnaw__are_we_currently_at_a_word_boundary {
	########GNAWMONITOR( "__gnaw__are_we_currently_at_a_word_boundary begin");
	
	# if we're at the end of input text, then we're at a word boundary, nothing further needed.
	if(__gnaw__at_end_of_input_text()) {
		########GNAWMONITOR("at end of input text");
		return 1;
	}

	# starting from current position, move forward until we hit a letter or a word boundary marker.
	# do not go past the tail marker.

	my $markerforward = $__gnaw__curr_text_element;
	while(	
		    ($markerforward ne $__gnaw__tail_text_element) 
		and ($markerforward->[__GNAW__WHAT] != __GNAW__LETTER_WHAT)
		and ($markerforward->[__GNAW__WHAT] != __GNAW__WRDBND_WHAT)
	) {
		$markerforward = $markerforward->[__GNAW__NEXT];
	}

	# starting from just before current position,
	# move back until we hit a letter or word boundary marker,
	# do not go past the head marker.
	my $markerbackward = $__gnaw__curr_text_element->[__GNAW__PREV];
	while(
		    ($markerbackward ne $__gnaw__head_text_element) 
		and ($markerbackward->[__GNAW__WHAT] != __GNAW__LETTER_WHAT)
		and ($markerbackward->[__GNAW__WHAT] != __GNAW__WRDBND_WHAT)
	) {
		$markerbackward = $markerbackward->[__GNAW__PREV];
	}

	# return 1 if we know we are on a boundary. 
	return 1 if($markerforward eq $__gnaw__tail_text_element);
	return 1 if($markerbackward eq $__gnaw__head_text_element);
	return 1 if($markerforward->[__GNAW__WHAT] == __GNAW__WRDBND_WHAT);
	return 1 if($markerbackward->[__GNAW__WHAT] == __GNAW__WRDBND_WHAT);

	if(	($markerforward->[__GNAW__WHAT] == __GNAW__LETTER_WHAT)
	and	($markerbackward->[__GNAW__WHAT] == __GNAW__LETTER_WHAT)
	) {
		my $letterforward  = $markerforward->[__GNAW__PAYLOAD];
		my $letterbackward = $markerbackward->[__GNAW__PAYLOAD];

		my $letterforwardiswordclass = exists($__gnaw__wb_word_class_hash{$letterforward})?1:0;
		my $letterbackwardiswordclass = exists($__gnaw__wb_word_class_hash{$letterbackward})?1:0;

		#print "previous=$letterbackwardiswordclass,  next=$letterforwardiswordclass\n\n";

		if(	(    $letterforwardiswordclass  and not($letterbackwardiswordclass))
		or	(not($letterforwardiswordclass) and     $letterbackwardiswordclass )
		) {
			return 1;
		} else {
			return 0;
		}

	} else {
		__gnaw__die("__gnaw__are_we_currently_at_a_word_boundary should have eliminated everything but two letter positions.");
	}

}



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# end
# positional marker: end of input text
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub end {

	my $compiled_code = {
		opcode => 'endoftext',
		coderef=> \&__gnaw__endoftext_callback,
	};

	my $stitcher = generate_stitcher($compiled_code, $compiled_code);

	return $stitcher;
}


sub __gnaw__endoftext_callback {
	########GNAWMONITOR( "__gnaw__endoftext_callback");
	my $thisinstruction = __gnaw__get_current_instruction_pointer();
	my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
	__gnaw__move_current_instruction_pointer($nextinstruction);

	$__gnaw__skip_code->();

	# if we're at the end of input text, nothing further needed.
	if(__gnaw__at_end_of_input_text()) {
		########GNAWMONITOR("at end of input text");
		return;
	}

	# starting from current position, move forward until we hit a letter.
	# do not go past the tail marker.

	my $markerforward = $__gnaw__curr_text_element;
	while(	
		    ($markerforward ne $__gnaw__tail_text_element) 
		and ($markerforward->[__GNAW__WHAT] != __GNAW__LETTER_WHAT)
	) {
		$markerforward = $markerforward->[__GNAW__NEXT];
	}

	if($markerforward eq $__gnaw__tail_text_element) {
		return;
	}

	__gnaw__parse_failed();
}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# more advanced grammar extensions
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# "slist" separated list

# standard separated list of items, last item not followed by separator
# item, item, item  	=> separatedlist(item, ',')

# standard separated list of items, last item may be followed by a separator or not.
# item, item, item,  	=> separatedlist(item, ',', 1)

# standard separated list of items, empty items allowed, last thing may be a separator
# item,,,item,,item,,  	=> separatedlist(maybe(item), ',')

sub slist {
	my $item=shift(@_);
	my $separator=shift(@_);

	my $trailingseparatorallowed=0;

	if(scalar(@_)) {
		$trailingseparatorallowed=shift(@_);

		unless( ($trailingseparatorallowed==1) or ($trailingseparatorallowed==0) ) {
			__gnaw__die("Error: Third parameter to separatedlist must be a 1 or 0");
		}
	}

	if(scalar(@_)) {
		__gnaw__die("Error: separatedlist only takes max three parameters (item, separator, 1/0)");
	}

	my $extension;

	if($trailingseparatorallowed){
		# an item, followed by any number of (separator item) and maybe one separator at end
		$extension = series( $item,  any($separator, $item), maybe($separator) );
	} else {
		# an item, followed by any number of ( separator item ) 		
		$extension = series( $item, any($separator, $item) );
	}

}


#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# az is like =~ m{\A blah \Z}
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub az { parse( @_, end ) }



#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# id = identifier
# id will get one or more "wrd" characters, with no whitespace in between them,
# and with the "bb" boundary function on both ends.
# use this to match a variable name or similar identifier type thingy.
# by default, you pass in no parameters.
# if you pass in a parameter, "identifier" will treat that as a "get" input
# and do the get for you and pass in whatever you passed in to "get".
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub id { 
	if(scalar(@_)) {
		my $getthingy=shift(@_);
		return series(skipnow, bb, get($getthingy, some(noskip(wrd))), bb);
	} else {
		return series(skipnow, some(noskip(wrd)));
		return series(skipnow, bb, some(noskip(wrd)), bb);
	}
}


sub token {  series( skipnow, noskip( @_ ) ) }

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
			__gnaw__commit_text_to_current_location(0);
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
			__gnaw__commit_text_to_current_location(0);
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

		__gnaw__flushed_text_is_ignored;

		__gnaw__process_commands();

		return $__gnaw__processor_succeeded;
	};

	########GNAWMONITOR( "match command end");

	return $call_back;
}



sub modify {
	########GNAWMONITOR( "modify command begin");

	my $stitcher=series(@_);

	# once we've processed the parameters passed into 'modify',
	# all the grammar components have been executed.
	# this means we can now generate the callback to initialize
	# all "get" variables and subroutines.
	my $variableinitroutine = __gnaw__generate_initialization_routine_for_get_callbacks_so_far();

	my $modify_init = {
		opcode => 'modify_init',
		coderef => sub {
			$variableinitroutine->(); 

			my $thisinstruction = __gnaw__get_current_instruction_pointer();
			my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
			__gnaw__move_current_instruction_pointer($nextinstruction);
		},
	};

	my $modify_pattern;
	$modify_pattern = {
		opcode => 'modify_pattern',
		coderef => sub {
			########GNAWMONITOR( "modify_pattern");
			if(__gnaw__at_end_of_input_text) {
				########GNAWMONITOR("modify pattern at end of string");
				$__gnaw__processor_still_running=0;
				$__gnaw__processor_succeeded=0;
				return;
			}

			########GNAWMONITOR( "modify_pattern about to create fallback");
			my $modify_failure = $modify_pattern->{modify_failure};
			my $textmarker =  __gnaw__create_new_marker_before_current_element 
				######## ( ' modify pattern function creating fallback marker ' )
			;		
			__gnaw__push_fallback_postition($modify_failure, $textmarker);

			my $thisinstruction = __gnaw__get_current_instruction_pointer();
			my $nextinstruction = __gnaw__given_instruction_return_next_instruction($thisinstruction);
			__gnaw__move_current_instruction_pointer($nextinstruction);
		},
	};

	my $modify_rejoinder = {
		opcode => 'modify_rejoinder',
		signifyendof => $modify_pattern,
		coderef => sub{
			# pop off the old fallback position, don't need it anymore.
			my $instruction;
			my $textmarker;
			__gnaw__pop_fallback_postition($instruction, $textmarker);
			__gnaw__delete_this_text_element($textmarker);

			$__gnaw__processor_still_running=0;
			$__gnaw__processor_succeeded=1;
			########GNAWMONITOR(__gnaw__string_showing_user_current_location_in_text);
			__gnaw__commit_text_to_current_location(0);
		},
	};

	my $modify_failure = {
		opcode => 'modify_failure',
		signifyendof => $modify_pattern,
		coderef => sub{
			__gnaw__move_pointer_forward();
			# we created a fallback, tried to parse, failed, and fellback to where we were
			# If we can move current position forward, then do that and jump to modify pattern
			# if we can't move current position forward, we're out of text, fail.
			if(__gnaw__at_end_of_input_text) {
				########GNAWMONITOR("modify failure at end of string");
				$__gnaw__processor_still_running=0;
				$__gnaw__processor_succeeded=0;
			} else {
				########GNAWMONITOR("modify failure NOT at end of string");
				__gnaw__move_current_instruction_pointer($modify_pattern);
			}
		},
	};

	my $modify_cant_try_anymore = {
		opcode => 'modify_cant_try_anymore',
		signifyendof => $modify_pattern,
		coderef => sub{
			########GNAWMONITOR("modify_cant_try_anymore");
			$__gnaw__processor_still_running=0;
			$__gnaw__processor_succeeded=0;

			# delete the current text marker
			# we inserted it at the start of the "modify" function.
			# move pointer to next element.
			__gnaw__delete_this_text_element($__gnaw__curr_text_element);
		},
	};

	$modify_init ->{rejoinder}=$modify_rejoinder;
	$modify_pattern ->{rejoinder}=$modify_rejoinder;
	$modify_pattern ->{modify_failure} = $modify_failure;

	my $initstitcher = generate_stitcher(	  $modify_init, 		$modify_init);
	my $modifystitcher = generate_stitcher(	  $modify_pattern,	$modify_pattern);
	my $rejoinderstitcher = generate_stitcher($modify_rejoinder, 	$modify_rejoinder);

	
	# getfirst, getlast, setprevious, setnext
	$initstitcher->('setnext', ($modifystitcher->('getfirst')));
	$modifystitcher->('setprevious', ($initstitcher->('getlast')));

	$modifystitcher->('setnext', ($stitcher->('getfirst')));
	$stitcher->('setprevious', ($modifystitcher->('getlast')));

	$stitcher->('setnext', ($rejoinderstitcher->('getfirst')));
	$rejoinderstitcher->('setprevious', ($stitcher->('getlast')));


	my $call_back = sub {
		my ($string) = @_;

		__gnaw__initialize_text_linked_list_to_empty();
		__gnaw__insert_string_at_end_of_linked_list($string);

		########GNAWMONITOR("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nend string initialization\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");

		$__gnaw__processor_still_running=1;
		$__gnaw__processor_succeeded=0;
		$__gnaw__processor_instruction_pointer = $modify_init;

		my $temp;
		__gnaw__flushed_text_is_sent_to_variable(\$temp);

		__gnaw__process_commands();

		if($__gnaw__processor_succeeded) {
			__gnaw__flush_remaining_unparsed_text;
			$_[0] = $temp;
		}

		return $__gnaw__processor_succeeded;
	};

	########GNAWMONITOR( "modify command end");

	return $call_back;
}


sub swap {
	my $callback = pop(@_);

	unless(ref($callback) eq 'CODE') {
		if(ref($callback)) {
			__gnaw__die("ERROR: last parameter to swap must be a callback or a string");
			die;
		}

		my $string = $callback.'';
		$callback = sub{ return $string; };
	}

	return modify(get($callback, @_));
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





1; # End of Parse::Gnaw
