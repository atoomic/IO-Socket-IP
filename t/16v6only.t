#!/usr/bin/perl -w

use strict;
use Test::More;

use Socket;
use IO::Socket::IP;

eval { IO::Socket::IP->new( LocalHost => "::1" ) } or
   plan skip_all => "Unable to bind to ::1";

plan tests => 4;

{
   my $listensock = IO::Socket::IP->new(
      Listen    => 1,
      Family    => PF_INET6,
      LocalPort => 0,
      Type      => SOCK_STREAM,
      V6Only    => 1,
   ) or die "Cannot listen on PF_INET6 - $@";

   my $testsock = IO::Socket::IP->new(
      Listen    => 1,
      Family    => PF_INET,
      LocalPort => $listensock->sockport,
      Type      => SOCK_STREAM,
   );

   ok( defined $testsock, 'Able to create PF_INET socket on PF_INET6 socket with V6Only true' );
   is( $testsock->sockport, $listensock->sockport, 'PF_INET and PF_INET6 socket share local port' );
}

{
   local $ENV{LANG} = "C"; # avoid locale-dependent error messages

   my $listensock = IO::Socket::IP->new(
      Listen    => 1,
      Family    => PF_INET6,
      LocalPort => 0,
      Type      => SOCK_STREAM,
      V6Only    => 0,
   ) or die "Cannot listen on PF_INET6 - $@";

   my $testsock = IO::Socket::IP->new(
      Listen    => 1,
      Family    => PF_INET,
      LocalPort => $listensock->sockport,
      Type      => SOCK_STREAM,
   );
   my $err = "$@";

   ok( !defined $testsock, 'Unable to create PF_INET socket on PF_INET6 socket with V6Only false' );
   like( $err, qr/Address already in use/, 'Socket creation fails with address in use' );
}
