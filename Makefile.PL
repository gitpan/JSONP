use 5.010;
use v5.10;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'JSONP',
    VERSION_FROM	=> 'lib/JSONP.pm', # finds $VERSION
    LICENSE		=> 'perl_5',
    PREREQ_PM		=> {
	    CGI		=> 0,
	    JSON	=> 0,
	    Want	=> 0,
	    Time::HiRes	=> 0,
	    Digest::SHA	=> 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/JSONP.pm', # retrieve abstract from module
       AUTHOR         => 'Anselmo Canfora <acanfora@cpan.org>') : ()),
);
