use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::Gnaw',
    AUTHOR              => 'Greg London <email@greglondon.com>',
    VERSION_FROM        => 'lib/Parse/Gnaw.pm',
    ABSTRACT_FROM       => 'lib/Parse/Gnaw.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-Gnaw-*' },
);
