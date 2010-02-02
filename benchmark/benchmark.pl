#!/usr/bin/env perl
use warnings;
use strict; 

# This script benchmarks Parse::Gnaw versus Parse::RecDescent.
# It uses a simple grammar to parse dates, like "Sun Jul 4".
# It creates a grammar for Parse::RecDescent that parses dates,
# and a grammar for Parse::Gnaw that parses dates.
# It creates parsers for both of them.
# both parsers are precompiled so they are not part of the benchmark timing.
# then the benchmarking runs both parsers on varying numbers of input dates.
# The inputs contain 1 date, half a dozen dates, and about 60 dates.
#
# The benchmarking module runs each parser with each group of input dates.
# The benchmarking module runs each combination for 5 seconds and counts 
# how many times each parser could parse each input block.
#
# when you run it, you get something like this:
#
#benchmarking for 30 seconds...
#                        Rate 
#parse_recdescent_many   19/s 
#parse_gnaw_many         64/s 
#parse_recdescent_few   270/s 
#parse_gnaw_few         523/s 
#parse_recdescent_1     819/s 
#parse_gnaw_1          1127/s 
#
# if I'm reading that correctly, Parse::Gnaw is about three times faster than Parse::RecDescent
# especially for longer chunks of text.




use lib '../lib';
use Parse::Gnaw;

use Parse::RecDescent;

use Benchmark qw(:all) ;
# http://search.cpan.org/~dapm/perl-5.10.1/lib/Benchmark.pm

use Data::Dumper;


# parse rec descent grammer for parsing dates

my $parse_recdescent_grammar = <<'PARSERECDESCENTGRAMMAR';
	date : (day  month dayofmonth)(s) eofile

	day : "Sun" | "Mon" | "Tue" | "Wed" | "Thu" | "Fri" | "Sat"

	month : "Jan" | "Feb" | "Mar" | "Apr" | "May" | "Jun" |
		"Jul" | "Aug" | "Sep" | "Oct" | "Nov" | "Dec"

	dayofmonth : (/\d/)(1..2)

	eofile: /^\Z/

PARSERECDESCENTGRAMMAR

my $prd_parser =  new Parse::RecDescent ($parse_recdescent_grammar);



# parse gnaw grammar for parsing dates


sub day { qa('Sat Sun Mon Tue Wed Thu Fri') }

sub month { qa ('Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec') }

sub dayofmonth { greedy([1,2],dgt)  }

sub date {  day, month, dayofmonth  }

# Note that "parse" will expect the grammar to match the entire string, from beginning to end.
# Therefore, the grammar doesn't have to specify "eofile" like Parse::RecDescent does.
my $pg_parser = parse(date); 


my $date_data_matches_1 = "Sat Jan 21";

#my $retval = $pg_parser->($date_data_matches_1);print "retval is \n";print Dumper $retval;exit;

#my $retval = $prd_parser->date($date_data_matches_1); print "retval is \n";print Dumper $retval;exit;

my $date_data_matches_few = <<"DATE_MATCHES_FEW";
Sun Feb 3
Mon Mar 25
Tue Apr 1
Wed May 30
Thu Jun 7
DATE_MATCHES_FEW


my $date_data_matches_many = <<"DATE_MATCHES_MANY";
Fri Jul 14
Sat Aug 9
Sun Sep 17
Mon Oct 2
Tue Nov 29
Wed Dec 6
Sat Jan 21
Sun Feb 3
Mon Mar 25
Tue Apr 1
Wed May 30
Thu Jun 7
Fri Jul 14
Sat Aug 9
Sun Sep 17
Mon Oct 2
Tue Nov 29
Wed Dec 6
Sat Jan 21
Sun Feb 3
Mon Mar 25
Tue Apr 1
Wed May 30
Thu Jun 7
Fri Jul 14
Sat Aug 9
Sun Sep 17
Mon Oct 2
Tue Nov 29
Wed Dec 6
Sat Jan 21
Sun Feb 3
Mon Mar 25
Tue Apr 1
Wed May 30
Thu Jun 7
Fri Jul 14
Sat Aug 9
Sun Sep 17
Mon Oct 2
Tue Nov 29
Wed Dec 6
Sat Jan 21
Sun Feb 3
Mon Mar 25
Tue Apr 1
Wed May 30
Thu Jun 7
Fri Jul 14
Sat Aug 9
Sun Sep 17
Mon Oct 2
Tue Nov 29
Wed Dec 6
Sat Jan 21
Sun Feb 3
Mon Mar 25
Tue Apr 1
Wed May 30
Thu Jun 7
Fri Jul 14
Sat Aug 9
Sun Sep 17
Mon Oct 2
Tue Nov 29
Wed Dec 6
DATE_MATCHES_MANY

my $prdfail=0;

sub prd_test_1 {
	unless (defined($prd_parser->date($date_data_matches_1))) {
		$prdfail=1;
	}
}

sub prd_test_few {
	unless (defined($prd_parser->date($date_data_matches_few))) {
		$prdfail=1;
	}
}

sub prd_test_many {
	unless (defined($prd_parser->date($date_data_matches_many))) {
		$prdfail=1;
	}
}

my $pgfail=0;

sub pg_test_1 {
	if($pg_parser->($date_data_matches_1) == 0) {
		$pgfail=1;
	}
}

sub pg_test_few {
	unless($pg_parser->($date_data_matches_few) ) {
		$pgfail=1;
	}
}

sub pg_test_many {
	unless($pg_parser->($date_data_matches_many) ) {
		$pgfail=1;
	}
}


print "benchmarking for 30 seconds...\n";

cmpthese( -5, {
	parse_recdescent_1 => \&prd_test_1,
	parse_recdescent_few => \&prd_test_few,
	parse_recdescent_many => \&prd_test_many,
	parse_gnaw_1 => \&pg_test_1,
	parse_gnaw_few => \&pg_test_few,
	parse_gnaw_many => \&pg_test_many,
} );

if($prdfail==1){ print "parse::recdescent parsing failed\n"; }
if( $pgfail==1){ print "parse::gnaw       parsing failed\n"; }




