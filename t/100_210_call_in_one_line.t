

use Test::More 'no_plan';

use lib 'lib';
use Parse::Gnaw;

# you can create a grammar and apply it to a text in one line

ok(match('howdy', 'partner')->("why howdy   partner !") == 1, "direct call matches");
ok(match('howdy', 'partner')->("why hello   world   !") == 0, "direct call no match");
