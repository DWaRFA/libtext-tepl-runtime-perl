use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::Tepl::Runtime',
    AUTHOR              => 'MIZUTANI Tociyuki <tociyuki@gmail.com>',
    VERSION_FROM        => 'lib/Text/Tepl/Runtime.pm',
    ABSTRACT_FROM       => 'lib/Text/Tepl/Runtime.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Base' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
