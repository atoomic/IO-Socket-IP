#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010 -- leonerd@leonerd.org.uk

package IO::Socket::IP;

use strict;
use warnings;
use base qw( IO::Socket );

our $VERSION = '0.01';

use Carp;

use Socket::GetAddrInfo qw(
   :newapi getaddrinfo getnameinfo

   NI_NUMERICHOST NI_NUMERICSERV
   NI_DGRAM
);
use Socket qw(
   SOCK_DGRAM
   SOL_SOCKET
   SO_REUSEADDR SO_REUSEPORT SO_BROADCAST
);

=head1 NAME

C<IO::Socket::IP> - Use IPv4 and IPv6 sockets in a protocol-independent way

=head1 SYNOPSIS

 use IO::Socket::IP;

 my $sock = IO::Socket::IP->new(
    PeerHost    => "www.google.com",
    PeerService => "www",
 );

 printf "Now connected to %s:%s\n", $sock->peerhost_service;

 ...

=head1 DESCRIPTION

This module provides a protocol-independent way to use IPv4 and IPv6 sockets.
It allows new connections to be made by specifying the hostname and service
name or port number. It allows for connections to be accepted by sockets
listening on local ports, by service name or port number.

It uses L<Socket::GetAddrInfo>'s C<getaddrinfo> function to convert
hostname/service name pairs into sets of possible addresses to connect to.
This allows it to work for IPv6 where the system supports it, while still
falling back to IPv4-only on systems which don't.

It provides an API which, for most typical cases, should be a drop-in
replacement for L<IO::Socket::INET>; most constructor arguments and methods
are provided in a compatible way.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $sock = IO::Socket::IP->new( %args )

Creates a new C<IO::Socket::IP> object. If any arguments are passed it will be
configured to contain a newly created socket handle, and be configured
according to the argmuents. The recognised arguments are:

=over 8

=item Type => INT

The socket type (e.g. C<SOCK_STREAM>, C<SOCK_DGRAM>). Will be inferred by 
C<getaddrinfo> from the service name if not supplied.

=item Proto => INT

IP protocol for the socket connection. Will be inferred by C<getaddrinfo> from
the service name, or by the kernel from the socket type, if not supplied.

=item PeerHost => STRING

=item PeerService => STRING

Hostname and service name for the peer to C<connect()> to. The service name
may be given as a port number, as a decimal string.

For symmetry with the accessor methods and compatibility with
C<IO::Socket::INET>, C<PeerAddr> and C<PeerPort> are accepted as synonyms
respectively.

=item Listen => INT

Puts the socket into listening mode where new connections can be accepted
using the C<accept> method.

=item LocalHost => STRING

=item LocalService => STRING

Hostname and service name for the local address to C<bind()> to.

For symmetry with the accessor methods and compatibility with
C<IO::Socket::INET>, C<LocalAddr> and C<LocalPort> are accepted as synonyms
respectively.

=item ReuseAddr => BOOL

If true, set the C<SO_REUSEADDR> sockopt

=item ReusePort => BOOL

If true, set the C<SO_REUSEPORT> sockopt (not all OSes implement this sockopt)

=item Broadcast => BOOL

If true, set the C<SO_BROADCAST> sockopt

=back

=cut

sub configure
{
   my $self = shift;
   my ( $arg ) = @_;

   # Some conveniences for IO::Socket::INET users
   for (qw( Local Peer )) {
      # TODO: Consider hostname:port notations
      !defined $arg->{$_."Host"} and defined $arg->{$_."Addr"} and
         $arg->{$_."Host"} = delete $arg->{$_."Addr"};

      !defined $arg->{$_."Service"} and defined $arg->{$_."Port"} and
         $arg->{$_."Service"} = delete $arg->{$_."Port"};
   }

   my %hints;
   my @sockaddrs;
   my @peeraddrs;

   my @sockopts_enabled;

   if( defined $arg->{Type} ) {
      my $type = delete $arg->{Type};
      $hints{type} = $type;
   }

   if( defined $arg->{Proto} ) {
      my $proto = delete $arg->{Proto};

      unless( $proto =~ m/^\d+$/ ) {
         my $protonum = getprotobyname( $proto );
         defined $protonum or croak "Unrecognised protocol $proto";
         $proto = $protonum;
      }

      $hints{protocol} = $proto;
   }

   if( defined $arg->{LocalHost} or defined $arg->{LocalService} ) {
      # Either may be undef
      my $host = delete $arg->{LocalHost};
      my $service = delete $arg->{LocalService};

      ( my $err, @sockaddrs ) = getaddrinfo( $host, $service, \%hints );

      # TODO: This needs to raise somehow in $!
      $err and croak "Cannot getaddrinfo - $err;"
   }

   if( defined $arg->{PeerHost} or defined $arg->{PeerService} ) {
      defined( my $host = delete $arg->{PeerHost} ) or
         croak "Expected 'PeerHost'";
      defined( my $service = delete $arg->{PeerService} ) or
         croak "Expected 'PeerService'";

      ( my $err, @peeraddrs ) = getaddrinfo( $host, $service, \%hints );

      # TODO: This needs to raise somehow in $!
      $err and croak "Cannot getaddrinfo - $err;"
   }

   push @sockopts_enabled, SO_REUSEADDR if delete $arg->{ReuseAddr};
   push @sockopts_enabled, SO_REUSEPORT if delete $arg->{ReusePort};
   push @sockopts_enabled, SO_BROADCAST if delete $arg->{Broadcast};

   my $listenqueue = delete $arg->{Listen};

   croak "Cannot Listen with a PeerHost" if defined $listenqueue and @peeraddrs;

   keys %$arg and croak "Unexpected keys - " . join( ", ", sort keys %$arg );

   if( @peeraddrs ) {
      # Loop on socket / bind? / connect
      # TODO: Local binds

      while( @peeraddrs ) {
         my $addr = shift @peeraddrs;

         $self->socket( @{$addr}{qw( family socktype protocol )} ) or next;

         $self->setsockopt( SOL_SOCKET, $_, pack "i", 1 ) or return undef for @sockopts_enabled;

         $self->connect( $addr->{addr} ) or next;

         return $self;
      }
   }
   else {
      # Loop on socket / bind
      while( @sockaddrs ) {
         my $addr = shift @sockaddrs;

         $self->socket( @{$addr}{qw( family socktype protocol )} ) or next;

         $self->setsockopt( SOL_SOCKET, $_, pack "i", 1 ) or return undef for @sockopts_enabled;

         $self->bind( $addr->{addr} ) or next;

         $self->listen( $listenqueue ) or return undef if defined $listenqueue;

         return $self;
      }
   }

   # TODO: an error code
   return undef;
}

=head1 METHODS

=cut

sub _get_host_service
{
   my $self = shift;
   my ( $addr, $numeric ) = @_;

   my $flags = 0;

   $flags |= NI_DGRAM if $self->socktype == SOCK_DGRAM;
   $flags |= NI_NUMERICHOST|NI_NUMERICSERV if $numeric;

   my ( $err, $host, $service ) = getnameinfo( $addr, $flags );
   croak "getnameinfo - $err" if $err;

   return ( $host, $service );
}

=head2 ( $host, $service ) = $sock->sockhost_service( $numeric )

Return the hostname and service name for the local endpoint (that is, the
socket address given by the C<sockname> method).

If C<$numeric> is true, these will be given in numeric form rather than being
resolved into names.

This method is used to implement the following for convenience wrappers. If
both host and service names are required, this method is preferrable to the
following wrappers, because it will call C<getnameinfo(3)> only once.

=cut

sub sockhost_service
{
   my $self = shift;
   my ( $numeric ) = @_;

   $self->_get_host_service( $self->sockname, $numeric );
}

=head2 $addr = $sock->sockaddr

Return the numeric form of the local address

=head2 $port = $sock->sockport

Return the numeric form of the local port number

=head2 $host = $sock->sockhost

Return the resolved name of the local address

=head2 $service = $sock->sockservice

Return the resolved name of the local port number

=cut

sub sockaddr    { ( shift->sockhost_service(1) )[0] }
sub sockport    { ( shift->sockhost_service(1) )[1] }
sub sockhost    { ( shift->sockhost_service(0) )[0] }
sub sockservice { ( shift->sockhost_service(0) )[1] }

=head2 ( $host, $service ) = $sock->peerhost_service( $numeric )

Similar to the C<sockhost_service> method, but instead returns the hostname
and service name for the peer endpoint (that is, the socket address given by
the C<peername> method).

=cut

sub peerhost_service
{
   my $self = shift;
   my ( $numeric ) = @_;

   $self->_get_host_service( $self->peername, $numeric );
}

=head2 $addr = $sock->peeraddr

Return the numeric form of the peer address

=head2 $port = $sock->peerport

Return the numeric form of the peer port number

=head2 $host = $sock->peerhost

Return the resolved name of the peer address

=head2 $service = $sock->peerservice

Return the resolved name of the peer port number

=cut

sub peeraddr    { ( shift->peerhost_service(1) )[0] }
sub peerport    { ( shift->peerhost_service(1) )[1] }
sub peerhost    { ( shift->peerhost_service(0) )[0] }
sub peerservice { ( shift->peerhost_service(0) )[1] }

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 TODO

=over 8

=item *

Accept C<hostname:port> notation in C<LocalAddr> and C<PeerAddr> constructor
args, as per C<IO::Socket::INET>. Special care should be taken on raw IPv6
addresses, which need wrapping as C<[2001::0123:4567]:89>.

=item *

Raise errors by correctly setting C<$!> or appropriate, and returning undef,
as per other C<IO::Socket> modules. Some care is required on how to handle
e.g. errors from C<getaddrinfo(3)>, which don't have C<errno> values.

=item *

Support C<LocalHost> and C<LocalService> to C<bind()> even when also
C<connect()>ing to a peer.

=item *

Return a useful error code if C<connect()> fails. Because of the inherent
"try-them-all" behaviour, it isn't easy to know what's the most appropriate
failure.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
