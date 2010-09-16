#!/usr/bin/perl -w

use strict;
use Test::More;

# This test script uses IO::Socket::INET6 to test against, though the actual
# module does not require it to be installed.
# TODO: See if we can do this using only Socket6

eval { require IO::Socket::INET6 } or
   plan skip_all => "No INET6";
eval { require Socket6 } or
   plan skip_all => "No Socket6";

plan tests => 14;

use IO::Socket::IP;
use Socket;

foreach my $socktype (qw( SOCK_STREAM SOCK_DGRAM )) {
   my $testserver = IO::Socket::IP->new(
      ( $socktype eq "SOCK_STREAM" ? ( Listen => 1 ) : () ),
      LocalHost => "::1",
      Type      => Socket->$socktype,
   );

   ok( defined $testserver, "IO::Socket::IP->new constructs a $socktype socket" );

   $testserver->blocking( 0 );

   is( $testserver->sockaddr, "::1",       "\$testserver->sockaddr for $socktype" );
   like( $testserver->sockport, qr/^\d+$/, "\$testserver->sockport for $socktype" );

   my $socket = IO::Socket::INET6->new(
      PeerHost => "::1",
      PeerPort => $testserver->sockport,
      Type     => Socket->$socktype,
      Proto    => ( $socktype eq "SOCK_STREAM" ? "tcp" : "udp" ), # Because IO::Socket::INET6 is stupid and always presumes tcp
   ) or die "Cannot connect to PF_INET - $!";

   my $testclient = ( $socktype eq "SOCK_STREAM" ) ? 
      $testserver->accept : 
      do { $testserver->connect( $socket->sockname ); $testserver };

   ok( defined $testclient, "accepted test $socktype client" );
   isa_ok( $testclient, "IO::Socket::IP", "\$testclient for $socktype" );

   is_deeply( [ Socket6::unpack_sockaddr_in6( $socket->sockname ) ],
              [ Socket6::unpack_sockaddr_in6( $testclient->peername ) ],
              "\$socket->sockname for $socktype" );

   is_deeply( [ Socket6::unpack_sockaddr_in6( $socket->peername ) ],
              [ Socket6::unpack_sockaddr_in6( $testclient->sockname ) ],
              "\$socket->peername for $socktype" );
}
