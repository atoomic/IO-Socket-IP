#!/usr/bin/perl -w

use strict;
use Test::More;

# This test script uses IO::Socket::INET6 to test against, though the actual
# module does not require it to be installed.
# TODO: See if we can do this using only Socket6

eval { require IO::Socket::INET6 } or
   plan skip_all => "No INET6";

plan tests => 14;

use IO::Socket::IP;

use Socket6 qw( unpack_sockaddr_in6 );

foreach my $proto (qw( tcp udp )) {
   my $testserver = IO::Socket::IP->new(
      ( $proto eq "tcp" ? ( Listen => 1 ) : () ),
      LocalHost => "::1",
      Proto     => $proto,
   );

   ok( defined $testserver, "IO::Socket::IP->new constructs a $proto socket" );

   $testserver->blocking( 0 );

   is( $testserver->sockaddr, "::1",       "\$testserver->sockaddr for $proto" );
   like( $testserver->sockport, qr/^\d+$/, "\$testserver->sockport for $proto" );

   my $socket = IO::Socket::INET6->new(
      PeerHost => "::1",
      PeerPort => $testserver->sockport,
      Proto    => $proto,
   ) or die "Cannot connect to PF_INET - $!";

   my $testclient = ( $proto eq "tcp" ) ? 
      $testserver->accept : 
      do { $testserver->connect( $socket->sockname ); $testserver };

   ok( defined $testclient, "accepted test $proto client" );
   isa_ok( $testclient, "IO::Socket::IP", "\$testclient for $proto" );

   is_deeply( [ unpack_sockaddr_in6 $socket->sockname ],
              [ unpack_sockaddr_in6 $testclient->peername ],
              "\$socket->sockname for $proto" );

   is_deeply( [ unpack_sockaddr_in6 $socket->peername ],
              [ unpack_sockaddr_in6 $testclient->sockname ],
              "\$socket->peername for $proto" );
}
