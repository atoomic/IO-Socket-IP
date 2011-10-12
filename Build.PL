use strict;
use warnings;

use Module::Build;

my %requires = (
   'IO::Socket' => 0,
);

# As of Perl 5.13.9, core's Socket now contains getaddrinfo, getnameinfo, and
# all the associated constants.
if( eval { require Socket and defined &Socket::getaddrinfo } ) {
   # Was added in Socket 1.93
   $requires{"Socket"} = '1.93';
}
else {
   $requires{"Socket::GetAddrInfo"} = '0.17';
}

my $build = Module::Build->new(
   module_name => 'IO::Socket::IP',
   requires => \%requires,
   build_requires => {
      'Test::More' => 0,
   },
   auto_configure_requires => 0, # Don't add M::B to configure_requires
   license => 'perl',
   create_makefile_pl => 'small',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;
