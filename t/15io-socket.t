#!/usr/bin/perl -w

use strict;
use Test::More tests => 2;

use IO::Socket;
use IO::Socket::IP -register;

my $sock = IO::Socket->new(
   Domain    => AF_INET,
   LocalHost => "127.0.0.1",
   LocalPort => 0,
);

isa_ok( $sock, "IO::Socket::IP", 'IO::Socket->new( Domain => AF_INET )' );

SKIP: {
   my $AF_INET6 = eval { Socket::AF_INET6() } ||
                  eval { require Socket6; Socket6::AF_INET6() };
   $AF_INET6 or skip 1, "No AF_INET6";

   my $sock = IO::Socket->new(
      Domain    => $AF_INET6,
      LocalHost => "::1",
      LocalPort => 0,
   );

   isa_ok( $sock, "IO::Socket::IP", 'IO::Socket->new( Domain => AF_INET6 )' );
}
