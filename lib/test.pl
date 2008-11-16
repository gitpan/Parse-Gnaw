
use warnings;
use strict;
use Data::Dumper;
use Parse::Gnaw;

my $grammar;

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

########################################################


ok( match('hello', 'world')->("howdy partner") == 0, "try direct call, no match");

ok( match('hello', 'world')->("well hello  world !") == 1, "try direct call,  match");


