#!/usr/bin/perl -w

use strict;
use Test::More;

# This test script uses IO::Socket::INET6 to test against, though the actual
# module does not require it to be installed.
# TODO: See if we can do this using only Socket6

eval { require IO::Socket::INET6 } or
   plan skip_all => "No IO::Socket::INET6";
eval { require Socket6 } or
   plan skip_all => "No Socket6";

plan tests => 16;

use IO::Socket::IP;
use Socket;

foreach my $socktype (qw( SOCK_STREAM SOCK_DGRAM )) {
   my $testserver = IO::Socket::INET6->new(
      ( $socktype eq "SOCK_STREAM" ? ( Listen => 1 ) : () ),
      LocalHost => "::1",
      Type      => Socket->$socktype,
      Proto     => ( $socktype eq "SOCK_STREAM" ? "tcp" : "udp" ), # Because IO::Socket::INET6 is stupid and always presumes tcp
   ) or die "Cannot listen on PF_INET6 - $!";

   $testserver->blocking( 0 );

   my $socket = IO::Socket::IP->new(
      PeerHost    => "::1",
      PeerService => $testserver->sockport,
      Type        => Socket->$socktype,
   );

   ok( defined $socket, "IO::Socket::IP->new constructs a $socktype socket" );

   is( $socket->sockdomain, Socket6::AF_INET6(), "\$socket->sockdomain for $socktype" );
   is( $socket->socktype,   Socket->$socktype,   "\$socket->socktype for $socktype" );

   my $testclient = ( $socktype eq "SOCK_STREAM" ) ? 
      $testserver->accept : 
      do { $testserver->connect( $socket->sockname ); $testserver };

   ok( defined $testclient, "accepted test $socktype client" );

   is_deeply( [ Socket6::unpack_sockaddr_in6( $socket->sockname ) ],
              [ Socket6::unpack_sockaddr_in6( $testclient->peername ) ],
              "\$socket->sockname for $socktype" );

   is_deeply( [ Socket6::unpack_sockaddr_in6( $socket->peername ) ],
              [ Socket6::unpack_sockaddr_in6( $testclient->sockname ) ],
              "\$socket->peername for $socktype" );

   is( $socket->peerhost, "::1",                 "\$socket->peerhost for $socktype" );
   is( $socket->peerport, $testserver->sockport, "\$socket->peerport for $socktype" );

   # Can't easily test the non-numeric versions without relying on the system's
   # ability to resolve the name "localhost"
}
