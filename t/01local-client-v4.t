#!/usr/bin/perl -w

use strict;
use Test::More tests => 12;

use IO::Socket::IP;

use IO::Socket::INET;
use Socket qw( unpack_sockaddr_in );

foreach my $proto (qw( tcp udp )) {
   my $testserver = IO::Socket::INET->new(
      ( $proto eq "tcp" ? ( Listen => 1 ) : () ),
      LocalHost => "127.0.0.1",
      Proto     => $proto,
   ) or die "Cannot listen on PF_INET - $!";

   $testserver->blocking( 0 );

   my $socket = IO::Socket::IP->new(
      PeerHost    => "127.0.0.1",
      PeerService => $testserver->sockport,
      Proto       => $proto,
   );

   ok( defined $socket, "IO::Socket::IP->new constructs a $proto socket" );

   my $testclient = ( $proto eq "tcp" ) ? 
      $testserver->accept : 
      do { $testserver->connect( $socket->sockname ); $testserver };

   ok( defined $testclient, "accepted test $proto client" );

   is_deeply( [ unpack_sockaddr_in $socket->sockname ],
              [ unpack_sockaddr_in $testclient->peername ],
              "\$socket->sockname for $proto" );

   is_deeply( [ unpack_sockaddr_in $socket->peername ],
              [ unpack_sockaddr_in $testclient->sockname ],
              "\$socket->peername for $proto" );

   is( $socket->peeraddr, "127.0.0.1",           "\$socket->peeraddr for $proto" );
   is( $socket->peerport, $testserver->sockport, "\$socket->peerport for $proto" );

   # Can't easily test the non-numeric versions without relying on the system's
   # ability to resolve the name "localhost"
}
