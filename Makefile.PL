use v5.8;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'JSONP',
    VERSION_FROM      => 'lib/JSONP.pm', # finds $VERSION
    PREREQ_PM         => {JSON => 2.52}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/JSONP.pm', # retrieve abstract from module
       AUTHOR         => 'Anselmo Canfora <acanfora@cpan.org>') : ()),
);
