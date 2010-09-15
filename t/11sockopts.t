#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

use IO::Socket::IP;

use Socket qw( SOL_SOCKET SO_REUSEADDR SO_REUSEPORT SO_BROADCAST );

my $sock;

$sock = IO::Socket::IP->new(
   LocalHost => "127.0.0.1",
   Proto     => "tcp",
   ReuseAddr => 1,
) or die "Cannot socket() - $!";

is( $sock->getsockopt( SOL_SOCKET, SO_REUSEADDR ), 1, 'SO_REUSEADDR set' );

SKIP: {
   # Some OSes don't implement SO_REUSEPORT
   skip "No SO_REUSEPORT", 1 unless defined eval { SO_REUSEPORT };

   $sock = IO::Socket::IP->new(
      LocalHost => "127.0.0.1",
      Proto     => "tcp",
      ReusePort => 1,
   ) or die "Cannot socket() - $!";

   is( $sock->getsockopt( SOL_SOCKET, SO_REUSEPORT ), 1, 'SO_REUSEPORT set' );
}

$sock = IO::Socket::IP->new(
   LocalHost => "127.0.0.1",
   Proto     => "tcp",
   Broadcast => 1,
) or die "Cannot socket() - $!";

is( $sock->getsockopt( SOL_SOCKET, SO_BROADCAST ), 1, 'SO_BROADCAST set' );
