

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

# combinations of all different grammar components at the same time



sub trekname { qa('Jim Captain Spock Bones Doctor Scotty') } 

sub occupation {a('ditch digger', 'bricklayer', 'mechanic')}

sub mccoy_job { [ql("I'm a doctor, not a"), occupation, a('!', '.')] }

sub mccoy_diag { [ "He's", 'dead', ',', trekname, a('!', '.') ] }

sub mccoy_rant1 { [ql('You green-blooded Vulcan'), a('!', '.') ] }

sub mccoy_isms { a(mccoy_job, mccoy_diag, mccoy_rant1) }



sub spock_awe {['Fascinating', ',', trekname, '.']}

sub spock_logic {['Highly', 'illogical',',', trekname, '.']}

sub spock_sensors { [ql("It's life ,"), trekname, ql(', but not as we know it .')]}

sub spock_isms {a(spock_awe, spock_logic, spock_sensors)}



sub kirk_dipolomacy1 {ql('We come in peace .')}

sub kirk_dipolomacy2 {ql('Shoot to kill .')}

sub kirk_to_scotty {ql('I need warp speed now, Scotty !')}

sub kirk_to_spock {ql('What is it , Spock ?')}

sub kirk_to_bones {ql('Just fix him , Bones')}

sub kirk_solution {ql('Activate ship self-destruct mechanism .')}

sub kirk_isms {a(
		kirk_dipolomacy1, 
		kirk_dipolomacy2,
		kirk_to_scotty,
		kirk_to_spock,
		kirk_to_bones,
		kirk_solution
	)
}



sub scotty_phy101 {ql('Ya kenna change the laws of physics .')}

sub time_units {qa('minutes hours days weeks')}

sub scotty_estimate {[ ql("I'll have it ready for you in three"), time_units, '.' ]}

sub scotty_isms { a(scotty_phy101, scotty_estimate) }


sub alien_isms {'weeboo'}



sub trek_isms {a(mccoy_isms, spock_isms, kirk_isms, scotty_isms, alien_isms )}

sub trek_script {g([23,23],trek_isms)}

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


my $leftovers =  <<'LEFTOVERS';






LEFTOVERS
;

#print "script is '$script'\n";

ok($grammar->( $script )==1, "1 match");

