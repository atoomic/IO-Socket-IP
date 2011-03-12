#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

use IO::Socket::IP;
use Socket qw( PF_INET SOCK_STREAM IPPROTO_TCP pack_sockaddr_in INADDR_ANY );

BEGIN {
   # Perl 5.13.9 or above has Socket::getaddrinfo support in core.
   # Before that we need to use Socket::GetAddrInfo
   my @imports = qw(
      AI_PASSIVE
   );

   if( require Socket and defined &Socket::getaddrinfo ) {
      Socket->import( @imports );
   }
   else {
      require Socket::GetAddrInfo;
      Socket::GetAddrInfo->import( ':newapi', @imports );
   }
}

my @gai_args;
my @gai_rets;

no strict 'refs';
no warnings 'redefine';

*{"IO::Socket::IP::getaddrinfo"} = sub {
   push @gai_args, [ @_ ];
   return @{ shift @gai_rets };
};

@gai_rets = (
   [ "Service unknown" ],
   [ "", {
         family   => PF_INET,
         socktype => SOCK_STREAM,
         protocol => IPPROTO_TCP,
         addr     => pack_sockaddr_in( 80, INADDR_ANY )
      } ],
);

IO::Socket::IP->new( LocalPort => "zyxxyblarg(80)" );

is_deeply( \@gai_args,
           [ 
              [ undef, "zyxxyblarg", { flags => AI_PASSIVE, socktype => SOCK_STREAM, protocol => IPPROTO_TCP } ],
              [ undef, "80",         { flags => AI_PASSIVE, socktype => SOCK_STREAM, protocol => IPPROTO_TCP } ],
           ],
           '@gai_args for LocalPort => "zyxxyblarg(80)"' );
