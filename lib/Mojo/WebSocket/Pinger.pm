package Mojo::WebSocket::Pinger;

use Mojo::Base -base;

use Carp ();
use Mojo::Promise;
use Mojo::Util;
use Mojo::WebSocket;
use Scalar::Util ();

my $isa = sub { Scalar::Util::blessed($_[0]) && $_[0]->isa($_[1]) };

sub DESTROY {
  return if defined ${^GLOBAL_PHASE} && ${^GLOBAL_PHASE} eq 'DESTRUCT';
  shift->_unlisten;
}

sub new { shift->SUPER::new->tx(shift) }

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
  my $id = Mojo::Util::sha1_sum(time . rand);
  my $p = $self->{pending}{$id} = Mojo::Promise->new;
  $self->{tx}->send([1, 0, 0, 0, Mojo::WebSocket::WS_PING, $id]);
  return $p;
}

sub tx {
  my $self = shift;
  return $self->{tx} unless @_;

  $self->_unlisten;

  my $tx = shift;
  Scalar::Util::weaken(my $weak = $self);
  $self->{listen} = $tx->on(frame => sub {
    my (undef, $frame) = @_;
    my ($op, $body) = @{$frame}[4,5];
    return unless $op == Mojo::WebSocket::WS_PONG;
    return unless my $p = delete $weak->{pending}{$body};
    $p->resolve;
  });

  Scalar::Util::weaken($self->{tx} = $tx);
  return $self;
}

sub _unlisten {
  my $self = shift;
  return unless my $listen = delete $self->{listen};
  return unless my $tx = $self->{tx};
  $tx->unsubscribe(frame => delete $self->{listen});
}

1;

