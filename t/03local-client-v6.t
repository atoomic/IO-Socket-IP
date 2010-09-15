#!/usr/bin/perl -w

use strict;
use Test::More;

# This test script uses IO::Socket::INET6 to test against, though the actual
# module does not require it to be installed.
# TODO: See if we can do this using only Socket6

eval { require IO::Socket::INET6 } or
   plan skip_all => "No INET6";

plan tests => 12;

use IO::Socket::IP;

use Socket6 qw( unpack_sockaddr_in6 );

foreach my $proto (qw( tcp udp )) {
   my $testserver = IO::Socket::INET6->new(
      ( $proto eq "tcp" ? ( Listen => 1 ) : () ),
      LocalHost => "::1",
      Proto     => $proto,
   ) or die "Cannot listen on PF_INET6 - $!";

   $testserver->blocking( 0 );

   my $socket = IO::Socket::IP->new(
      PeerHost    => "::1",
      PeerService => $testserver->sockport,
      Proto       => $proto,
   );

   ok( defined $socket, "IO::Socket::IP->new constructs a $proto socket" );

   my $testclient = ( $proto eq "tcp" ) ? 
      $testserver->accept : 
      do { $testserver->connect( $socket->sockname ); $testserver };

   ok( defined $testclient, "accepted test $proto client" );

   is_deeply( [ unpack_sockaddr_in6 $socket->sockname ],
              [ unpack_sockaddr_in6 $testclient->peername ],
              "\$socket->sockname for $proto" );

   is_deeply( [ unpack_sockaddr_in6 $socket->peername ],
              [ unpack_sockaddr_in6 $testclient->sockname ],
              "\$socket->peername for $proto" );

   is( $socket->peeraddr, "::1",                 "\$socket->peeraddr for $proto" );
   is( $socket->peerport, $testserver->sockport, "\$socket->peerport for $proto" );

   # Can't easily test the non-numeric versions without relying on the system's
   # ability to resolve the name "localhost"
}
