#!/usr/bin/perl -w

use strict;
use Test::More;

use IO::Socket::IP;

eval { IO::Socket::IP->new( LocalHost => "::1" ) } or
   plan skip_all => "Unable to bind to ::1";

plan tests => 12;

foreach my $socktype (qw( SOCK_STREAM SOCK_DGRAM )) {
   my $testserver = IO::Socket::IP->new(
      ( $socktype eq "SOCK_STREAM" ? ( Listen => 1 ) : () ),
      LocalHost => "::1",
      Type      => Socket->$socktype,
   );

   my $socket = IO::Socket::IP->new(
      PeerHost    => "::1",
      PeerService => $testserver->sockport,
      Type        => Socket->$socktype,
   );

   my $testclient = ( $socktype eq "SOCK_STREAM" ) ? 
      $testserver->accept : 
      do { $testserver->connect( $socket->sockname ); $testserver };

   is( $testclient->sockport, $socket->peerport, "\$testclient->sockport for $socktype" );
   is( $testclient->peerport, $socket->sockport, "\$testclient->peerport for $socktype" );

   is( $testclient->sockhost, $socket->peerhost, "\$testclient->sockhost for $socktype" );
   is( $testclient->peerhost, $socket->sockhost, "\$testclient->peerhost for $socktype" );

   $socket->write( "Request\n" );
   is( $testclient->getline, "Request\n", "\$socket to \$testclient for $socktype" );

   $testclient->write( "Response\n" );
   is( $socket->getline, "Response\n", "\$testclient to \$socket for $socktype" );
}
