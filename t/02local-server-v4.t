#!/usr/bin/perl -w

use strict;
use Test::More tests => 14;

use IO::Socket::IP;

use IO::Socket::INET;
use Socket qw( unpack_sockaddr_in );

foreach my $proto (qw( tcp udp )) {
   my $testserver = IO::Socket::IP->new(
      ( $proto eq "tcp" ? ( Listen => 1 ) : () ),
      LocalHost => "127.0.0.1",
      Proto     => $proto,
   );

   ok( defined $testserver, "IO::Socket::IP->new constructs a $proto socket" );

   $testserver->blocking( 0 );

   is( $testserver->sockaddr, "127.0.0.1", "\$testserver->sockaddr for $proto" );
   like( $testserver->sockport, qr/^\d+$/, "\$testserver->sockport for $proto" );

   my $socket = IO::Socket::INET->new(
      PeerHost => "127.0.0.1",
      PeerPort => $testserver->sockport,
      Proto    => $proto,
   ) or die "Cannot connect to PF_INET - $!";

   my $testclient = ( $proto eq "tcp" ) ? 
      $testserver->accept : 
      do { $testserver->connect( $socket->sockname ); $testserver };

   ok( defined $testclient, "accepted test $proto client" );
   isa_ok( $testclient, "IO::Socket::IP", "\$testclient for $proto" );

   is_deeply( [ unpack_sockaddr_in $socket->sockname ],
              [ unpack_sockaddr_in $testclient->peername ],
              "\$socket->sockname for $proto" );

   is_deeply( [ unpack_sockaddr_in $socket->peername ],
              [ unpack_sockaddr_in $testclient->sockname ],
              "\$socket->peername for $proto" );
}
