#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Parse::Gnaw' );
}

diag( "Testing Parse::Gnaw $Parse::Gnaw::VERSION, Perl $], $^X" );
