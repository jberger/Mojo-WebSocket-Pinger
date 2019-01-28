package Mojo::WebSocket::Pinger;

use Mojo::Base -base;

use Carp ();
use Mojo::Promise;
use Mojo::Util;
use Mojo::WebSocket;
use Scalar::Util ();

my $isa = sub { Scalar::Util::blessed($_[0]) && $_[0]->isa($_[1]) }

has tx => sub { Carp::croak 'tx is required' }, weak => 1;

sub DESTROY {
  my $self = shift;
  return if defined ${^GLOBAL_PHASE} && ${^GLOBAL_PHASE} eq 'DESTRUCT';
  return unless my $tx = $self->tx;
  $tx->unsubscribe(frame => delete $self->{listen}) if $self->{listen};
}

sub new {
  my $self = shift->SUPER::new(@_);
  Scalar::Util::weaken(my $weak = $self);
  $self->{listen} = $self->tx->on(frame => sub {
    my (undef, $frame) = @_;
    my ($op, $body) = @{$frame}[4,5];
    return unless $op == Mojo::WebSocket::WS_PONG;
    return unless my $p = delete $weak->{pending}{$body};
    $p->resolve;
  });
  return $self;
}

sub ping {
  my ($self, $cb) = @_;
  $self->ping_p->then(
    sub{ $self->$cb(undef) },
    sub{ $self->$cb($_[0]) },
  );
  return $self;
}

sub ping_p {
  my $self = shift;
  my $tx = $self->tx;
  my $id = Mojo::Util::sha1_sum(time . rand);
  my $p = $self->{pending}{$id} = Mojo::Promise->new;
  $tx->send([1, 0, 0, 0, Mojo::WebSocket::WS_PING, $id]);
  return $p;
}

1;

