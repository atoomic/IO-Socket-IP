#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

my @gai_args;
my @gai_rets;

use Socket::GetAddrInfo;
BEGIN {
   my $orig_gai = \&Socket::GetAddrInfo::getaddrinfo;

   no strict 'refs';
   no warnings 'redefine';

   *{"Socket::GetAddrInfo::getaddrinfo"} = sub {
      push @gai_args, [ @_ ];
      return @{ shift @gai_rets };
   }
}

use IO::Socket::IP;
use Socket qw( PF_INET SOCK_STREAM IPPROTO_TCP pack_sockaddr_in INADDR_ANY );

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
              [ undef, "zyxxyblarg", {} ],
              [ undef, "80",         {} ],
           ],
           '@gai_args for LocalPort => "zyxxyblarg(80)"' );
